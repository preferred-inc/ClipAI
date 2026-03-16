import SwiftUI

struct SettingsView: View {
    @AppStorage("claude_api_key") private var apiKey: String = ""
    @AppStorage("claude_model") private var model: String = "claude-sonnet-4-20250514"
    @State private var showKey = false

    private let models: [(id: String, label: String)] = [
        ("claude-sonnet-4-20250514", "Sonnet 4 — fast & balanced"),
        ("claude-opus-4-20250514", "Opus 4 — most capable"),
        ("claude-haiku-4-5-20251001", "Haiku 4.5 — fastest"),
    ]

    var body: some View {
        Form {
            Section {
                HStack {
                    Group {
                        if showKey {
                            TextField("sk-ant-...", text: $apiKey)
                        } else {
                            SecureField("sk-ant-...", text: $apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
            } header: {
                Text("Anthropic API Key")
            } footer: {
                Link("console.anthropic.com でキーを取得",
                     destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    .font(.caption)
            }

            Section("Model") {
                Picker("Model", selection: $model) {
                    ForEach(models, id: \.id) { m in
                        Text(m.label).tag(m.id)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Section {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    HStack(spacing: 4) {
                        KeyCap("⌘")
                        KeyCap("⌥")
                        KeyCap(".")
                    }
                }

                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 320)
    }
}

private struct KeyCap: View {
    let label: String
    init(_ label: String) { self.label = label }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
