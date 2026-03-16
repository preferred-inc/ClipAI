import SwiftUI

struct ContentView: View {
    let clipboardText: String
    let onClose: () -> Void

    @StateObject private var claude = ClaudeService()
    @State private var prompt: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Input bar — Spotlight style
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)

                TextField("聞きたいことを入力…", text: $prompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($isFocused)
                    .onSubmit { send() }

                if claude.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Response
            if !claude.response.isEmpty || claude.errorMessage != nil {
                Divider()

                ScrollView {
                    Group {
                        if let error = claude.errorMessage {
                            Text(error).foregroundStyle(.red)
                        } else {
                            Text(claude.response)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 520, maxHeight: claude.response.isEmpty && claude.errorMessage == nil ? 48 : 400)
        .background(.ultraThinMaterial)
        .onAppear {
            isFocused = true
            if !clipboardText.isEmpty {
                send()
            }
        }
    }

    private func send() {
        let apiKey = UserDefaults.standard.string(forKey: "claude_api_key") ?? ""
        guard !apiKey.isEmpty else {
            claude.errorMessage = "API Key未設定 → メニューバー ✦ → Settings"
            return
        }

        let input: String
        if prompt.isEmpty {
            guard !clipboardText.isEmpty else { return }
            input = "以下の内容について、簡潔に説明・要約してください:\n\n\(clipboardText)"
        } else {
            let context = clipboardText.isEmpty ? "" : "\n\n---\n\n\(clipboardText)"
            input = prompt + context
        }

        claude.send(prompt: input, apiKey: apiKey)
    }
}
