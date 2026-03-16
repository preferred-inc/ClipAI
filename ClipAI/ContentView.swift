import SwiftUI

struct ContentView: View {
    let clipboardText: String
    let onClose: () -> Void

    @StateObject private var claude = ClaudeService()
    @State private var prompt: String
    @State private var appeared = false
    @State private var savedToHistory = false
    @FocusState private var isFocused: Bool

    init(clipboardText: String, onClose: @escaping () -> Void) {
        self.clipboardText = clipboardText
        self.onClose = onClose
        self._prompt = State(initialValue: clipboardText)
    }

    private var hasResponse: Bool {
        !claude.response.isEmpty || claude.errorMessage != nil || claude.isLoading
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
        .frame(width: 540)
        .fixedSize(horizontal: false, vertical: true)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }

    // MARK: - Accent bar

    private var accentBar: some View {
        Theme.gradient
            .frame(height: 3)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 10) {
            SparkleIcon(isAnimating: claude.isLoading)

            TextField("聞きたいことを入力してEnter…", text: $prompt)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular))
                .focused($isFocused)
                .onSubmit { send() }

            Spacer(minLength: 0)

            Button(action: send) {
                Image(systemName: claude.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(prompt.isEmpty ? Theme.accentDim : Theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(prompt.isEmpty && !claude.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
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
                    } else if claude.response.isEmpty && claude.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Thinking…")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 13))
                        }
                        .padding(.top, 20)
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
            .onChange(of: claude.isLoading) { loading in
                if !loading && !claude.response.isEmpty && !savedToHistory {
                    HistoryStore.shared.add(prompt: prompt, response: claude.response)
                    savedToHistory = true
                }
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 6) {
            if claude.isLoading && !claude.response.isEmpty {
                TypingDots()
            }
            Spacer()
            if !claude.response.isEmpty {
                Button(action: copyResponse) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    // MARK: - Actions

    private func send() {
        if claude.isLoading {
            claude.cancel()
            return
        }

        let apiKey = UserDefaults.standard.string(forKey: "claude_api_key") ?? ""
        guard !apiKey.isEmpty else {
            claude.errorMessage = "API Key未設定 → メニューバー ✦ → Settings"
            return
        }

        guard !prompt.isEmpty else { return }
        claude.send(prompt: prompt, apiKey: apiKey)
    }

    private func copyResponse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(claude.response, forType: .string)
    }
}

// MARK: - Sparkle Icon

struct SparkleIcon: View {
    let isAnimating: Bool
    @State private var pulse = false

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(isAnimating ? Theme.accent : Theme.accentDim)
            .scaleEffect(pulse ? 1.15 : 1.0)
            .opacity(pulse ? 1.0 : 0.7)
            .animation(
                isAnimating
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                    : .easeOut(duration: 0.2),
                value: pulse
            )
            .onChange(of: isAnimating) { val in
                pulse = val
            }
    }
}

// MARK: - Typing Dots

struct TypingDots: View {
    @State private var phase = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.accent.opacity(phase == i ? 0.8 : 0.25))
                    .frame(width: 4, height: 4)
                    .animation(.easeInOut(duration: 0.2), value: phase)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
