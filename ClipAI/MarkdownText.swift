import SwiftUI

struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                switch block {
                case .code(let lang, let code):
                    codeBlock(language: lang, code: code)
                case .text(let content):
                    if let attributed = try? AttributedString(markdown: content,
                        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributed)
                            .font(.system(size: 13.5))
                            .textSelection(.enabled)
                            .lineSpacing(3)
                    } else {
                        Text(content)
                            .font(.system(size: 13.5))
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    // MARK: - Code Block

    private func codeBlock(language: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                HStack {
                    Text(language)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: { copyCode(code) }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.codeBg.opacity(0.5))
            }

            Text(code)
                .font(.system(size: 12.5, design: .monospaced))
                .textSelection(.enabled)
                .lineSpacing(2)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.codeBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func copyCode(_ code: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }

    // MARK: - Parser

    private enum Block {
        case text(String)
        case code(lang: String, code: String)
    }

    private func parseBlocks() -> [Block] {
        var blocks: [Block] = []
        var current = ""
        var inCode = false
        var codeLang = ""
        var codeContent = ""

        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("```") && !inCode {
                if !current.isEmpty {
                    blocks.append(.text(current.trimmingCharacters(in: .whitespacesAndNewlines)))
                    current = ""
                }
                inCode = true
                codeLang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                codeContent = ""
            } else if line.hasPrefix("```") && inCode {
                blocks.append(.code(lang: codeLang, code: codeContent.trimmingCharacters(in: .newlines)))
                inCode = false
                codeLang = ""
                codeContent = ""
            } else if inCode {
                codeContent += (codeContent.isEmpty ? "" : "\n") + line
            } else {
                current += (current.isEmpty ? "" : "\n") + line
            }
        }

        if inCode {
            // Unclosed code block (still streaming)
            blocks.append(.code(lang: codeLang, code: codeContent.trimmingCharacters(in: .newlines)))
        }
        if !current.isEmpty {
            blocks.append(.text(current.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return blocks.filter {
            switch $0 {
            case .text(let s): return !s.isEmpty
            case .code(_, let s): return !s.isEmpty
            }
        }
    }
}
