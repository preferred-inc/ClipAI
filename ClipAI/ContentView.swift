import SwiftUI

struct ContentView: View {
    let clipboardText: String
    let onClose: () -> Void

    @StateObject private var claude = ClaudeService()
    @State private var prompt: String = ""
    @FocusState private var isFocused: Bool

    private var hasResponse: Bool {
        !claude.response.isEmpty || claude.errorMessage != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            inputBar
            if hasResponse {
                Divider()
                responseArea
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        )
        .onAppear {
            isFocused = true
            if !clipboardText.isEmpty {
                send()
            }
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.purple.opacity(0.8))

            VStack(alignment: .leading, spacing: 2) {
                TextField("聞きたいことを入力…", text: $prompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .onSubmit { send() }

                if !clipboardText.isEmpty {
                    Text(clipboardText.prefix(80).replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if claude.isLoading {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, clipboardText.isEmpty ? 12 : 10)
    }

    // MARK: - Response

    private var responseArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if let error = claude.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    } else {
                        Text(claude.response)
                            .textSelection(.enabled)
                    }
                }
                .font(.system(size: 13.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .id("bottom")
            }
            .frame(maxHeight: 340)
            .onChange(of: claude.response) { _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Action

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
