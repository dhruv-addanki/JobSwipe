import SwiftUI

struct FeedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Job Feed")
                .font(.largeTitle)
                .bold()
            Text("Swipe through tailored job matches. Coming soon 🚧")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
}
