import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // App branding
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)
                    Text("Personal EHR")
                        .font(.largeTitle.bold())
                    Text("Your health records, intelligently organized")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Email/password form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)

                    if let error = authViewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task {
                            await authViewModel.signInWithEmail(email: email, password: password)
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                }
                .padding(.horizontal)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.secondary.opacity(0.3))
                }
                .padding(.horizontal)

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { _ in
                    // Will be fully implemented in Step 3
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal)

                Spacer()

                // Register link
                Button("Don't have an account? Sign up") {
                    showRegister = true
                }
                .font(.subheadline)
            }
            .padding()
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}
