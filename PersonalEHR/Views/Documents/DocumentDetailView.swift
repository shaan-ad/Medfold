import SwiftUI

struct DocumentDetailView: View {
    let document: Document

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: document.category.iconName)
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text(document.category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let provider = document.providerName {
                        Label(provider, systemImage: "building.2")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let date = document.documentDate {
                        Label {
                            Text(date, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if !document.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(document.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Divider()

                // AI Summary
                if let summary = document.aiSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI Summary", systemImage: "sparkles")
                            .font(.headline)
                        Text(summary)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if document.status == .processing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("AI is analyzing your document...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Key Values (from ai_extracted)
                if let extracted = document.aiExtracted,
                   let keyValues = extracted["key_values"] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Values")
                            .font(.headline)
                        // Will render key-value pairs from JSONB in Step 5
                        Text("Extracted data available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        // Will open PDF/image viewer in Step 4
                    } label: {
                        Label("View Original Document", systemImage: "doc.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        // Will navigate to AI chat with context in Step 6
                    } label: {
                        Label("Ask AI About This", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
