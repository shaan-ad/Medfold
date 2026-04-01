import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .onTapGesture {
                            Task { await authViewModel.signOut() }
                        }
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // Will implement full account deletion in Step 7
                }
            } message: {
                Text("This will permanently delete your account and all health records. This action cannot be undone.")
            }
        }
    }
}
