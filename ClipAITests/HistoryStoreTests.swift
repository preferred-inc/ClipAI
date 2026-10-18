import XCTest

@MainActor
final class HistoryStoreTests: XCTestCase {
    private var fileURL: URL!
    private var defaults: UserDefaults!
    private let suiteName = "ClipAITests.HistoryStore"

    override func setUp() async throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("clipai-history-\(UUID().uuidString).json")
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: fileURL)
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func item(_ prompt: String, _ response: String, daysAgo: Double = 0, now: Date = Date()) -> HistoryItem {
        HistoryItem(date: now.addingTimeInterval(-daysAgo * 86_400), prompt: prompt, response: response)
    }

    func testAddPersistsAndReloads() {
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        store.add(prompt: "p1", response: "r1")
        store.add(prompt: "p2", response: "r2")

        let reloaded = HistoryStore(fileURL: fileURL, defaults: defaults)
        XCTAssertEqual(reloaded.items.map(\.prompt), ["p2", "p1"])
    }

    func testKeepsAtMostMaxItems() {
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        for i in 0..<(HistorySettings.maxItems + 5) {
            store.add(prompt: "p\(i)", response: "r")
        }
        XCTAssertEqual(store.items.count, HistorySettings.maxItems)
        XCTAssertEqual(store.items.first?.prompt, "p\(HistorySettings.maxItems + 4)")
    }

    func testFilterMatchesPromptOrResponseCaseInsensitively() {
        let items = [item("Swift の質問", "回答A"), item("翻訳して", "Hello World"), item("other", "none")]
        XCTAssertEqual(HistoryStore.filter(items, query: "swift").map(\.prompt), ["Swift の質問"])
        XCTAssertEqual(HistoryStore.filter(items, query: "world").map(\.prompt), ["翻訳して"])
        XCTAssertEqual(HistoryStore.filter(items, query: "  ").count, 3)
    }

    func testFilterRequiresAllTerms() {
        let items = [item("Swift async", "x"), item("Swift", "sync")]
        XCTAssertEqual(HistoryStore.filter(items, query: "swift async").map(\.prompt), ["Swift async"])
    }

    func testPurgedRemovesItemsOlderThanRetention() {
        let now = Date()
        let items = [item("new", "r", daysAgo: 1, now: now), item("old", "r", daysAgo: 40, now: now)]
        XCTAssertEqual(HistoryStore.purged(items, retentionDays: 30, now: now).map(\.prompt), ["new"])
        XCTAssertEqual(HistoryStore.purged(items, retentionDays: 0, now: now).count, 2, "0 は無期限")
    }

    func testApplyRetentionUsesSetting() {
        let store = HistoryStore(fileURL: fileURL, defaults: defaults)
        store.items = [item("new", "r", daysAgo: 1), item("old", "r", daysAgo: 10)]
        defaults.set(7, forKey: HistorySettings.retentionDaysKey)
        store.applyRetention()
        XCTAssertEqual(store.items.map(\.prompt), ["new"])
    }

    func testExportJSONRoundTrips() throws {
        let items = [item("p", "r")]
        let data = try HistoryStore.exportJSON(items)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([HistoryItem].self, from: data)
        XCTAssertEqual(decoded.map(\.prompt), ["p"])
        XCTAssertEqual(decoded.first?.id, items.first?.id)
    }

    func testExportMarkdownContainsPromptAndResponse() {
        let md = HistoryStore.exportMarkdown([item("質問です", "回答です")])
        XCTAssertTrue(md.hasPrefix("# ClipAI History"))
        XCTAssertTrue(md.contains("### Prompt\n\n質問です"))
        XCTAssertTrue(md.contains("### Response\n\n回答です"))
    }
}

@MainActor
final class HistoryStoreRemoveTests: XCTestCase {
    func testRemoveAtOffsets() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("clipai-rm-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = HistoryStore(fileURL: url, defaults: UserDefaults(suiteName: "ClipAITests.Remove")!)
        store.items = ["a", "b", "c", "d"].map { HistoryItem(prompt: $0, response: "") }
        store.remove(at: IndexSet([0, 2]))
        XCTAssertEqual(store.items.map(\.prompt), ["b", "d"])
    }
}
