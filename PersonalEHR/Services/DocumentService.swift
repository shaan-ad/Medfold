import Foundation
import Supabase

protocol DocumentServiceProtocol {
    func fetchDocuments() async throws -> [Document]
    func getDocument(id: UUID) async throws -> Document
    func createDocument(_ document: DocumentInsert) async throws -> Document
    func updateDocument(id: UUID, updates: DocumentUpdate) async throws
    func deleteDocument(id: UUID) async throws
}

struct DocumentInsert: Codable {
    let title: String
    let category: DocumentCategory
    let filePath: String
    let fileType: String
    let fileSize: Int64
    let documentDate: Date?
    let providerName: String?
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case title, category, tags
        case filePath = "file_path"
        case fileType = "file_type"
        case fileSize = "file_size"
        case documentDate = "document_date"
        case providerName = "provider_name"
    }
}

struct DocumentUpdate: Codable {
    var title: String?
    var category: DocumentCategory?
    var documentDate: Date?
    var providerName: String?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case title, category, tags
        case documentDate = "document_date"
        case providerName = "provider_name"
    }
}

final class SupabaseDocumentService: DocumentServiceProtocol {
    private let client = AppSupabase.client

    func fetchDocuments() async throws -> [Document] {
        try await client
            .from("documents")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func getDocument(id: UUID) async throws -> Document {
        try await client
            .from("documents")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    func createDocument(_ document: DocumentInsert) async throws -> Document {
        try await client
            .from("documents")
            .insert(document)
            .select()
            .single()
            .execute()
            .value
    }

    func updateDocument(id: UUID, updates: DocumentUpdate) async throws {
        try await client
            .from("documents")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteDocument(id: UUID) async throws {
        try await client
            .from("documents")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
