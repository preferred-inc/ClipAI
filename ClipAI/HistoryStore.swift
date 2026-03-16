import Foundation

struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let prompt: String
    let response: String

    init(prompt: String, response: String) {
        self.id = UUID()
        self.date = Date()
        self.prompt = prompt
        self.response = response
    }
}

@MainActor
class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published var items: [HistoryItem] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()

    private init() {
        load()
    }

    func add(prompt: String, response: String) {
        let item = HistoryItem(prompt: prompt, response: response)
        items.insert(item, at: 0)
        // Keep last 100
        if items.count > 100 {
            items = Array(items.prefix(100))
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        items.removeAll()
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
}
