import Foundation
import Supabase

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var conversations: [AIConversation] = []
    @Published var messages: [AIMessage] = []
    @Published var currentConversation: AIConversation?
    @Published var isLoading = false
    @Published var isStreaming = false
    @Published var error: String?

    private let client = AppSupabase.client

    func fetchConversations() async {
        do {
            let response: [AIConversation] = try await client
                .from("ai_conversations")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            conversations = response
        } catch let err {
            self.error = err.localizedDescription
        }
    }

    func fetchMessages(for conversationId: UUID) async {
        do {
            let response: [AIMessage] = try await client
                .from("ai_messages")
                .select()
                .eq("conversation_id", value: conversationId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            messages = response
        } catch let err {
            self.error = err.localizedDescription
        }
    }

    func sendMessage(_ content: String, conversationId: UUID?) async {
        // Will be implemented in Step 6
    }
}
