import SwiftUI
import SwiftData

struct FeedView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @StateObject private var viewModel = FeedViewModel()
    @State private var dragOffset: CGSize = .zero
    @State private var predictedAction: FeedViewModel.SwipeAction?
    @State private var deckWidth: CGFloat = 0

    private var taskToken: FeedTaskToken {
        FeedTaskToken(profileID: profiles.first?.id, apiID: environment.jobAPISourceID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                content
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .task(id: taskToken) {
            await reloadJobs()
        }
        .refreshable {
            await reloadJobs()
        }
        .animation(.easeInOut, value: viewModel.jobs)
        .navigationTitle("Matches")
        .alert("Unable to fetch jobs", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.jobs) { _ in
            dragOffset = .zero
            predictedAction = nil
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(environment.currentJobProviderName)
                    .font(.headline)
                Text(viewModel.jobs.isEmpty ? "No roles queued" : "\(viewModel.jobs.count) roles ready to review")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await reloadJobs() }
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.jobs.isEmpty {
            loadingState
        } else if viewModel.jobs.isEmpty {
            emptyState
        } else {
            swipeDeckSection
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Fetching curated jobs...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemBackground)))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No matches yet",
            systemImage: "rectangle.stack.badge.person.crop",
            description: Text("Save your profile to unlock personalized job matches.")
        )
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var swipeDeckSection: some View {
        VStack(spacing: 24) {
            GeometryReader { proxy in
                let width = proxy.size.width
                cacheDeckWidth(width)
                ZStack {
                    ForEach(Array(viewModel.jobs.prefix(3).enumerated()), id: \.element.id) { index, job in
                        let isTopCard = index == 0
                        FeedJobCardView(job: job)
                            .offset(x: isTopCard ? dragOffset.width : 0,
                                    y: CGFloat(index) * 12 + (isTopCard ? dragOffset.height : 0))
                            .scaleEffect(isTopCard ? 1 : 1 - CGFloat(index) * 0.05, anchor: .top)
                            .rotationEffect(isTopCard ? cardRotation(for: width) : .zero)
                            .zIndex(Double(viewModel.jobs.count - index))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 8)
                            .allowsHitTesting(isTopCard)
                            .gesture(isTopCard ? dragGesture(containerWidth: width) : nil)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    if predictedAction == .reject {
                        SwipeBadge(text: "PASS", color: .red, rotation: Angle(degrees: 12))
                            .padding(24)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if predictedAction == .apply {
                        SwipeBadge(text: "APPLY", color: .green, rotation: Angle(degrees: -12))
                            .padding(24)
                    }
                }
            }
            .frame(height: 430)

            actionButtons

            if let decision = viewModel.lastDecision {
                SwipeDecisionSummaryView(decision: decision)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 28) {
            SwipeActionButton(
                action: .reject,
                tint: .red,
                isDisabled: viewModel.jobs.isEmpty,
                perform: { trigger(.reject) }
            )

            Button(action: undoSwipe) {
                Label("Undo", systemImage: "arrow.uturn.left")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.swipeHistory.isEmpty)

            SwipeActionButton(
                action: .apply,
                tint: .green,
                isDisabled: viewModel.jobs.isEmpty,
                perform: { trigger(.apply) }
            )
        }
    }

    private func dragGesture(containerWidth width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragChanged(value, containerWidth: width)
            }
            .onEnded { value in
                handleDragEnded(value, containerWidth: width)
            }
    }

    private func handleDragChanged(_ value: DragGesture.Value, containerWidth width: CGFloat) {
        dragOffset = value.translation
        predictedAction = action(for: value.translation.width, threshold: width * 0.25)
    }

    private func handleDragEnded(_ value: DragGesture.Value, containerWidth width: CGFloat) {
        let action = action(for: value.translation.width, threshold: width * 0.25)
            ?? action(for: value.predictedEndTranslation.width, threshold: width * 0.35)
        guard let action else {
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
                predictedAction = nil
            }
            return
        }
        performSwipe(action, containerWidth: width)
    }

    private func action(for translation: CGFloat, threshold: CGFloat) -> FeedViewModel.SwipeAction? {
        if translation > threshold { return .apply }
        if translation < -threshold { return .reject }
        return nil
    }

    private func performSwipe(_ action: FeedViewModel.SwipeAction, containerWidth width: CGFloat) {
        predictedAction = action
        let horizontalTarget = (action == .apply ? width : -width) * 1.2
        withAnimation(.easeIn(duration: 0.18)) {
            dragOffset = CGSize(width: horizontalTarget, height: dragOffset.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            viewModel.performSwipe(action)
            dragOffset = .zero
            predictedAction = nil
        }
    }

    private func trigger(_ action: FeedViewModel.SwipeAction) {
        guard !viewModel.jobs.isEmpty else { return }
        let width = deckWidth == 0 ? 320 : deckWidth
        performSwipe(action, containerWidth: width)
    }

    private func undoSwipe() {
        guard !viewModel.swipeHistory.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = .zero
            predictedAction = nil
            viewModel.undoLastSwipe()
        }
    }

    private func cacheDeckWidth(_ width: CGFloat) {
        guard abs(deckWidth - width) > 1 else { return }
        DispatchQueue.main.async {
            deckWidth = width
        }
    }

    private func cardRotation(for width: CGFloat) -> Angle {
        let progress = dragOffset.width / max(width, 1)
        return Angle(degrees: Double(progress) * 12)
    }

    private func reloadJobs() async {
        viewModel.updateJobAPI(environment.jobAPI)
        await viewModel.loadJobs(for: profiles.first)
    }
}

private struct FeedTaskToken: Hashable {
    let profileID: UUID?
    let apiID: ObjectIdentifier
}

private struct SwipeBadge: View {
    let text: String
    let color: Color
    let rotation: Angle

    var body: some View {
        Text(text)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(.white)
            .rotationEffect(rotation)
    }
}

private struct SwipeActionButton: View {
    let action: FeedViewModel.SwipeAction
    let tint: Color
    let isDisabled: Bool
    let perform: () -> Void

    var body: some View {
        Button(action: perform) {
            Image(systemName: action.systemImage)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(tint))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.35 : 1)
    }
}

private struct SwipeDecisionSummaryView: View {
    let decision: FeedViewModel.SwipeDecision

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: decision.action.systemImage)
                .font(.title2)
                .foregroundStyle(decision.action == .apply ? Color.green : Color.red)
            VStack(alignment: .leading, spacing: 4) {
                Text(decision.action == .apply ? "Applied" : "Passed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(decision.job.title) • \(decision.job.companyName)")
                    .font(.subheadline)
                    .lineLimit(1)
            }
            Spacer()
            Text(decision.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
    }
}

#Preview {
    NavigationStack {
        FeedView()
            .modelContainer(ModelContainerProvider.shared(inMemory: true))
            .environmentObject(AppEnvironment(useMockJobs: true))
    }
}
