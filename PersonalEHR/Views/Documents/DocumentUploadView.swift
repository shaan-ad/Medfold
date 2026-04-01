import SwiftUI

struct DocumentUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var category: DocumentCategory = .other
    @State private var providerName = ""
    @State private var documentDate = Date()
    @State private var tagText = ""
    @State private var tags: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    // File picker buttons
                    HStack(spacing: 20) {
                        FileSourceButton(icon: "camera.fill", label: "Camera") {
                            // Will implement camera capture in Step 4
                        }
                        FileSourceButton(icon: "photo.fill", label: "Photos") {
                            // Will implement photo picker in Step 4
                        }
                        FileSourceButton(icon: "folder.fill", label: "Files") {
                            // Will implement document picker in Step 4
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(DocumentCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    DatePicker("Document Date", selection: $documentDate, displayedComponents: .date)
                    TextField("Provider / Facility", text: $providerName)
                }

                Section("Tags") {
                    HStack {
                        TextField("Add tag", text: $tagText)
                        Button("Add") {
                            let tag = tagText.trimmingCharacters(in: .whitespaces)
                            if !tag.isEmpty && !tags.contains(tag) {
                                tags.append(tag)
                                tagText = ""
                            }
                        }
                        .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                        .font(.caption)
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Will implement upload in Step 4
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct FileSourceButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .frame(width: 80, height: 70)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
