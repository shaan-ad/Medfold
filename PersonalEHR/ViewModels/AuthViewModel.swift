import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?

    private let client = AppSupabase.client

    func checkSession() async {
        do {
            _ = try await client.auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch let err {
            self.error = err.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        error = nil
        do {
            try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            isAuthenticated = true
        } catch let err {
            self.error = err.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
        } catch let err {
            self.error = err.localizedDescription
        }
    }
}
