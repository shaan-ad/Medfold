import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var messageText = ""

    private let suggestedPrompts = [
        "Summarize my recent lab results",
        "What trends do you see in my health data?",
        "List my current medications",
        "Are there any concerning patterns?"
    ]

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.messages.isEmpty {
                    // Empty state with suggestions
                    Spacer()
                    VStack(spacing: 24) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue.opacity(0.6))
                        Text("Health Assistant")
                            .font(.title2.bold())
                        Text("Ask me about your health records")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 8) {
                            ForEach(suggestedPrompts, id: \.self) { prompt in
                                Button {
                                    messageText = prompt
                                } label: {
                                    Text(prompt)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    // Message list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                AIMessageView(message: message)
                            }
                        }
                        .padding()
                    }
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Ask about your records...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        let text = messageText
                        messageText = ""
                        Task {
                            await viewModel.sendMessage(text, conversationId: viewModel.currentConversation?.id)
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming)
                }
                .padding()
            }
            .navigationTitle("AI Chat")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.currentConversation = nil
                        viewModel.messages = []
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}
