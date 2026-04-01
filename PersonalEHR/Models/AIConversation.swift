import Foundation

struct AIConversation: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct AIMessage: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let userId: UUID
    var role: MessageRole
    var content: String
    var referencedDocs: [UUID]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case userId = "user_id"
        case role, content
        case referencedDocs = "referenced_docs"
        case createdAt = "created_at"
    }
}
