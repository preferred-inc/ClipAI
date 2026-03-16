import SwiftUI

struct SettingsView: View {
    @AppStorage("claude_api_key") private var apiKey: String = ""
    @AppStorage("claude_model") private var model: String = "claude-sonnet-4-20250514"

    private let models = [
        "claude-sonnet-4-20250514",
        "claude-opus-4-20250514",
        "claude-haiku-4-5-20251001"
    ]

    var body: some View {
        Form {
            Section {
                SecureField("Anthropic API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("API Key")
            } footer: {
                Text("Get your key at console.anthropic.com")
                    .foregroundStyle(.secondary)
            }

            Section("Model") {
                Picker("Model", selection: $model) {
                    ForEach(models, id: \.self) { m in
                        Text(m).tag(m)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Shortcut") {
                HStack {
                    Text("Global Hotkey")
                    Spacer()
                    Text("⌘ ⌥ I")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 300)
    }
}
