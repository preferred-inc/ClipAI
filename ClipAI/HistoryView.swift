import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @ObservedObject var store = HistoryStore.shared
    @State private var selected: HistoryItem?
    @State private var query = ""

    private var filteredItems: [HistoryItem] {
        HistoryStore.filter(store.items, query: query)
    }

    var body: some View {
        NavigationSplitView {
            List(filteredItems, selection: Binding(
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
            .searchable(text: $query, placement: .sidebar, prompt: "履歴を検索")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("Markdown で書き出す…") { export(as: .markdown) }
                        Button("JSON で書き出す…") { export(as: .json) }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(filteredItems.isEmpty)
                    .help("Export")
                }
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

    private enum ExportFormat {
        case markdown, json
    }

    /// 表示中（検索で絞り込んだ後）の履歴をファイルに書き出す。
    private func export(as format: ExportFormat) {
        let items = filteredItems
        let panel = NSSavePanel()
        switch format {
        case .markdown:
            panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
            panel.nameFieldStringValue = "ClipAI-history.md"
        case .json:
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "ClipAI-history.json"
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let data: Data?
        switch format {
        case .markdown:
            data = HistoryStore.exportMarkdown(items).data(using: .utf8)
        case .json:
            data = try? HistoryStore.exportJSON(items)
        }
        guard let data else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func copyResponse(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
