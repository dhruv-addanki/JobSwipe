import SwiftUI

struct ProfileView: View {
    var body: some View {
        Form {
            Section("Welcome") {
                Text("Profile builder coming soon.")
                Text("We\'ll capture experience, preferences, and resume content.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
