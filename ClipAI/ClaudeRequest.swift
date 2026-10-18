import Foundation

/// Messages API に送るリクエストを組み立てる（ネットワークに触れない純粋な処理）。
enum ClaudeRequest {
    static let defaultModel = "claude-sonnet-4-20250514"
    static let maxTokens = 4096

    static func body(prompt: String, model: String, systemPrompt: String?) -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "stream": true,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        if let system = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !system.isEmpty {
            body["system"] = system
        }
        return body
    }

    /// 設定（UserDefaults）から有効なシステムプロンプトを返す。無効・空なら nil。
    static func systemPrompt(from defaults: UserDefaults = .standard) -> String? {
        guard defaults.bool(forKey: SystemPromptSettings.enabledKey) else { return nil }
        let text = defaults.string(forKey: SystemPromptSettings.textKey) ?? ""
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }
}

enum SystemPromptSettings {
    static let enabledKey = "system_prompt_enabled"
    static let textKey = "system_prompt"

    struct Preset: Identifiable {
        let id: String
        let label: String
        let text: String
    }

    static let presets: [Preset] = [
        Preset(id: "translate", label: "翻訳",
               text: "入力されたテキストを翻訳してください。日本語なら英語に、それ以外なら日本語に訳し、訳文だけを返してください。"),
        Preset(id: "code", label: "コード解説",
               text: "入力されたコードが何をしているかを、要点から順に日本語で簡潔に説明してください。問題点があれば最後に挙げてください。"),
        Preset(id: "summary", label: "要約",
               text: "入力されたテキストを日本語で3行以内に要約してください。"),
    ]
}
