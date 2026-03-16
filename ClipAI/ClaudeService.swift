import Foundation

@MainActor
class ClaudeService: ObservableObject {
    @Published var response: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var currentTask: Task<Void, Never>?

    func cancel() {
        currentTask?.cancel()
        isLoading = false
    }

    func send(prompt: String, apiKey: String) {
        currentTask?.cancel()
        response = ""
        errorMessage = nil
        isLoading = true

        currentTask = Task {
            do {
                try await streamRequest(prompt: prompt, apiKey: apiKey)
            } catch is CancellationError {
                // Cancelled, ignore
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    private func streamRequest(prompt: String, apiKey: String) async throws {
        let model = UserDefaults.standard.string(forKey: "claude_model") ?? "claude-sonnet-4-20250514"

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "stream": true,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, urlResponse) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            // Read error body
            var errorBody = ""
            for try await line in bytes.lines {
                errorBody += line
            }
            throw ClaudeError.apiError(httpResponse.statusCode, errorBody)
        }

        // Parse SSE stream
        for try await line in bytes.lines {
            try Task.checkCancellation()

            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))

            guard jsonString != "[DONE]",
                  let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String
            else { continue }

            if type == "content_block_delta",
               let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                self.response += text
            }
        }
    }
}

enum ClaudeError: LocalizedError {
    case invalidResponse
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code, let body):
            return "API Error \(code): \(body)"
        }
    }
}
