import Foundation
import Supabase

@MainActor
final class DocumentViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCategory: DocumentCategory?
    @Published var searchText = ""

    private let client = AppSupabase.client

    var filteredDocuments: [Document] {
        var result = documents
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { doc in
                doc.title.lowercased().contains(query)
                || (doc.aiSummary?.lowercased().contains(query) ?? false)
                || doc.tags.contains(where: { $0.lowercased().contains(query) })
                || (doc.providerName?.lowercased().contains(query) ?? false)
            }
        }
        return result
    }

    func fetchDocuments() async {
        isLoading = true
        error = nil
        do {
            let response: [Document] = try await client
                .from("documents")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            documents = response
        } catch let err {
            self.error = err.localizedDescription
        }
        isLoading = false
    }
}
