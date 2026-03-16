import SwiftUI

struct HistoryView: View {
    @ObservedObject var store = HistoryStore.shared
    @State private var selected: HistoryItem?

    var body: some View {
        NavigationSplitView {
            List(store.items, selection: Binding(
                get: { selected?.id },
                set: { id in selected = store.items.first { $0.id == id } }
            )) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.prompt.prefix(60).replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text(item.date, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
                .tag(item.id)
            }
            .frame(minWidth: 220)
            .toolbar {
                ToolbarItem {
                    Button(action: { store.clear() }) {
                        Image(systemName: "trash")
                    }
                    .disabled(store.items.isEmpty)
                    .help("Clear all")
                }
            }
        } detail: {
            if let item = selected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Prompt
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Prompt", systemImage: "text.bubble")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.prompt)
                                .font(.system(size: 13))
                                .textSelection(.enabled)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Response
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Response", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            MarkdownText(item.response)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(20)
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: { copyResponse(item.response) }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
            } else {
                Text("履歴を選択")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func copyResponse(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
