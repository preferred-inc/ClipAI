import XCTest

final class ClaudeRequestTests: XCTestCase {
    private let suiteName = "ClipAITests.ClaudeRequest"

    func testBodyWithoutSystemPrompt() {
        let body = ClaudeRequest.body(prompt: "hi", model: "m", systemPrompt: nil)
        XCTAssertEqual(body["model"] as? String, "m")
        XCTAssertEqual(body["stream"] as? Bool, true)
        XCTAssertNil(body["system"])
        let messages = body["messages"] as? [[String: String]]
        XCTAssertEqual(messages?.first?["content"], "hi")
    }

    func testBodyIncludesTrimmedSystemPrompt() {
        let body = ClaudeRequest.body(prompt: "hi", model: "m", systemPrompt: "  要約して\n")
        XCTAssertEqual(body["system"] as? String, "要約して")
    }

    func testBlankSystemPromptIsOmitted() {
        let body = ClaudeRequest.body(prompt: "hi", model: "m", systemPrompt: "   ")
        XCTAssertNil(body["system"])
    }

    func testSystemPromptSettingRespectsToggle() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("翻訳して", forKey: SystemPromptSettings.textKey)
        defaults.set(false, forKey: SystemPromptSettings.enabledKey)
        XCTAssertNil(ClaudeRequest.systemPrompt(from: defaults))

        defaults.set(true, forKey: SystemPromptSettings.enabledKey)
        XCTAssertEqual(ClaudeRequest.systemPrompt(from: defaults), "翻訳して")

        defaults.set(" ", forKey: SystemPromptSettings.textKey)
        XCTAssertNil(ClaudeRequest.systemPrompt(from: defaults))
    }

    func testPresetsAreNonEmpty() {
        XCTAssertFalse(SystemPromptSettings.presets.isEmpty)
        XCTAssertTrue(SystemPromptSettings.presets.allSatisfy { !$0.text.isEmpty })
    }
}
