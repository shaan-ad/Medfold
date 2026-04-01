import SwiftUI

struct AIMessageView: View {
    let message: AIMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray6))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if !message.referencedDocs.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.caption2)
                        Text("\(message.referencedDocs.count) document(s) referenced")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }
}
