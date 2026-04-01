import Foundation
import Supabase

protocol AIServiceProtocol {
    func sendMessage(_ content: String, conversationId: UUID?) async throws -> AIMessage
    func createConversation(title: String) async throws -> AIConversation
    func fetchConversations() async throws -> [AIConversation]
    func fetchMessages(conversationId: UUID) async throws -> [AIMessage]
}

final class SupabaseAIService: AIServiceProtocol {
    private let client = AppSupabase.client

    func sendMessage(_ content: String, conversationId: UUID?) async throws -> AIMessage {
        // Will call ai-chat Edge Function in Step 6
        fatalError("Not yet implemented")
    }

    func createConversation(title: String) async throws -> AIConversation {
        try await client
            .from("ai_conversations")
            .insert(["title": title])
            .select()
            .single()
            .execute()
            .value
    }

    func fetchConversations() async throws -> [AIConversation] {
        try await client
            .from("ai_conversations")
            .select()
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

    func fetchMessages(conversationId: UUID) async throws -> [AIMessage] {
        try await client
            .from("ai_messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }
}
