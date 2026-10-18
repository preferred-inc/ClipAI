import Foundation

struct HistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let prompt: String
    let response: String

    init(id: UUID = UUID(), date: Date = Date(), prompt: String, response: String) {
        self.id = id
        self.date = date
        self.prompt = prompt
        self.response = response
    }
}

enum HistorySettings {
    /// 履歴の保存期間（日）。0 は無期限。
    static let retentionDaysKey = "history_retention_days"
    static let retentionOptions: [(days: Int, label: String)] = [
        (0, "無期限"),
        (7, "7日"),
        (30, "30日"),
        (90, "90日"),
    ]
    static let maxItems = 100
}

@MainActor
class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published var items: [HistoryItem] = []

    private let fileURL: URL
    private let defaults: UserDefaults

    private static let defaultFileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()

    init(fileURL: URL? = nil, defaults: UserDefaults = .standard) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        self.defaults = defaults
        load()
        applyRetention()
    }

    var retentionDays: Int {
        defaults.integer(forKey: HistorySettings.retentionDaysKey)
    }

    func add(prompt: String, response: String) {
        let item = HistoryItem(prompt: prompt, response: response)
        items.insert(item, at: 0)
        if items.count > HistorySettings.maxItems {
            items = Array(items.prefix(HistorySettings.maxItems))
        }
        items = Self.purged(items, retentionDays: retentionDays)
        save()
    }

    func remove(at offsets: IndexSet) {
        // remove(atOffsets:) は SwiftUI の拡張なので、Foundation だけで済む形にしておく
        for index in offsets.sorted(by: >) where items.indices.contains(index) {
            items.remove(at: index)
        }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    /// 保存期間を過ぎた履歴を削除する。
    func applyRetention(now: Date = Date()) {
        let kept = Self.purged(items, retentionDays: retentionDays, now: now)
        guard kept.count != items.count else { return }
        items = kept
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Pure helpers

    static func purged(_ items: [HistoryItem], retentionDays: Int, now: Date = Date()) -> [HistoryItem] {
        guard retentionDays > 0 else { return items }
        let cutoff = now.addingTimeInterval(-TimeInterval(retentionDays) * 24 * 60 * 60)
        return items.filter { $0.date >= cutoff }
    }

    /// プロンプトと回答の全文から、空白区切りのすべての語を含む履歴を返す（大文字小文字は区別しない）。
    static func filter(_ items: [HistoryItem], query: String) -> [HistoryItem] {
        let terms = query.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !terms.isEmpty else { return items }
        return items.filter { item in
            terms.allSatisfy { term in
                item.prompt.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                    || item.response.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }

    static func exportJSON(_ items: [HistoryItem]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(items)
    }

    static func exportMarkdown(_ items: [HistoryItem]) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = ["# ClipAI History", ""]
        for item in items {
            lines.append("## \(formatter.string(from: item.date))")
            lines.append("")
            lines.append("### Prompt")
            lines.append("")
            lines.append(item.prompt)
            lines.append("")
            lines.append("### Response")
            lines.append("")
            lines.append(item.response)
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
