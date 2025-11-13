import SwiftUI

struct ApplicationsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Applications Hub")
                .font(.title)
                .bold()
            Text("Track drafts, submissions, and AI-tailored content here.")
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
        ApplicationsView()
    }
}
