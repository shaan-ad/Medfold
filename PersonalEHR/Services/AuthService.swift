import Foundation
import Supabase

protocol AuthServiceProtocol {
    func signInWithEmail(email: String, password: String) async throws
    func signInWithApple(idToken: String, nonce: String) async throws
    func signUp(email: String, password: String, fullName: String) async throws
    func signOut() async throws
    func deleteAccount() async throws
    var currentUserId: UUID? { get async }
}

final class SupabaseAuthService: AuthServiceProtocol {
    private let client = AppSupabase.client

    func signInWithEmail(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signUp(email: String, password: String, fullName: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func deleteAccount() async throws {
        // Will be implemented in Step 7 via Edge Function
    }

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }
}
