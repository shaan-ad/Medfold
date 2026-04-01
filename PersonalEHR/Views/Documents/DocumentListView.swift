import SwiftUI

struct DocumentListView: View {
    @StateObject private var viewModel = DocumentViewModel()
    @State private var showUpload = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(
                            title: "All",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(DocumentCategory.allCases) { category in
                            CategoryPill(
                                title: category.displayName,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Document list
                List(viewModel.filteredDocuments) { document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        DocumentCardView(document: document)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.fetchDocuments()
                }
                .overlay {
                    if viewModel.filteredDocuments.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "No Records",
                            systemImage: "folder.badge.plus",
                            description: Text("Upload your first health document to get started")
                        )
                    }
                }
            }
            .navigationTitle("My Records")
            .searchable(text: $viewModel.searchText, prompt: "Search records...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showUpload = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showUpload) {
                DocumentUploadView()
            }
            .task {
                await viewModel.fetchDocuments()
            }
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct DocumentCardView: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: document.category.iconName)
                    .foregroundStyle(.blue)
                Text(document.title)
                    .font(.headline)
                Spacer()
                if document.status == .processing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            HStack {
                if let provider = document.providerName {
                    Text(provider)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let date = document.documentDate {
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !document.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(document.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if let summary = document.aiSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
