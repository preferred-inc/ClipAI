import SwiftUI

struct ContentView: View {
    let clipboardText: String
    let onClose: () -> Void

    @StateObject private var claude = ClaudeService()
    @State private var prompt: String = ""
    @State private var appeared = false
    @FocusState private var isFocused: Bool

    private var hasResponse: Bool {
        !claude.response.isEmpty || claude.errorMessage != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            accentBar
            inputBar
            if hasResponse {
                responseDivider
                responseArea
                bottomBar
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
        )
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appeared = true
            }
            isFocused = true
            if !clipboardText.isEmpty {
                send()
            }
        }
    }

    // MARK: - Accent bar (brand identity)

    private var accentBar: some View {
        Theme.gradient
            .frame(height: 3)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            SparkleIcon(isAnimating: claude.isLoading)

            VStack(alignment: .leading, spacing: 3) {
                TextField("聞きたいことを入力…", text: $prompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular))
                    .focused($isFocused)
                    .onSubmit { send() }

                if !clipboardText.isEmpty && !hasResponse {
                    Text(clipboardText.prefix(100).replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer(minLength: 0)

            if !prompt.isEmpty && !claude.isLoading {
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .animation(.easeOut(duration: 0.15), value: prompt.isEmpty)
    }

    // MARK: - Divider

    private var responseDivider: some View {
        Rectangle()
            .fill(Theme.subtleGradient)
            .frame(height: 1)
    }

    // MARK: - Response

    private var responseArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    if let error = claude.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.system(size: 13))
                    } else {
                        MarkdownText(claude.response)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .id("bottom")
            }
            .frame(maxHeight: 360)
            .onChange(of: claude.response) { _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 6) {
            if claude.isLoading {
                TypingDots()
            }
            Spacer()
            Button(action: copyResponse) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Copy response  ⌘C")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    // MARK: - Actions

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

    private func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(claude.response, forType: .string)
    }
}

// MARK: - Sparkle Icon

struct SparkleIcon: View {
    let isAnimating: Bool
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(isAnimating ? Theme.gradient : LinearGradient(colors: [Theme.accentDim], startPoint: .top, endPoint: .bottom))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .onChange(of: isAnimating) { animating in
                if animating {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rotation = 0
                    }
                }
            }
    }
}

// MARK: - Typing Dots

struct TypingDots: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Theme.accent.opacity(phase == i ? 0.8 : 0.25))
                    .frame(width: 4, height: 4)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}
