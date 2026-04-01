import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await authViewModel.checkSession()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DocumentListView()
                .tabItem {
                    Label("Records", systemImage: "folder.fill")
                }

            AIChatView()
                .tabItem {
                    Label("AI Chat", systemImage: "bubble.left.and.text.bubble.right.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
