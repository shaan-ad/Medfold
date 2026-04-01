import Foundation
import Supabase

protocol StorageServiceProtocol {
    func uploadFile(data: Data, path: String, contentType: String) async throws -> String
    func getSignedURL(path: String) async throws -> URL
    func deleteFile(path: String) async throws
}

final class SupabaseStorageService: StorageServiceProtocol {
    private let client = AppSupabase.client
    private let bucket = Constants.documentsBucket

    func uploadFile(data: Data, path: String, contentType: String) async throws -> String {
        try await client.storage
            .from(bucket)
            .upload(path, data: data, options: .init(contentType: contentType))
        return path
    }

    func getSignedURL(path: String) async throws -> URL {
        try await client.storage
            .from(bucket)
            .createSignedURL(path: path, expiresIn: 3600)
    }

    func deleteFile(path: String) async throws {
        try await client.storage
            .from(bucket)
            .remove(paths: [path])
    }
}
