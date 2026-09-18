import Combine
import Foundation
import UIKit

enum KeychainHelper {
    static func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveString(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(data, service: service, account: account)
    }

    static func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

@MainActor
final class BYOKeyStore: ObservableObject {
    static let shared = BYOKeyStore()
    private static let service = "com.zzoutuo.Booply"
    private static let account = "zai-api-key"

    @Published var hasKey: Bool

    private init() {
        hasKey = KeychainHelper.readString(service: Self.service, account: Self.account) != nil
    }

    var apiKey: String? {
        KeychainHelper.readString(service: Self.service, account: Self.account)
    }

    func setKey(_ key: String) {
        KeychainHelper.saveString(key, service: Self.service, account: Self.account)
        hasKey = !key.isEmpty
    }

    func deleteKey() {
        KeychainHelper.delete(service: Self.service, account: Self.account)
        hasKey = false
    }
}

enum GLMProxy {
    static let url = ""
}

enum GLMService {
    static let endpoint = "https://api.z.ai/api/paas/v4/chat/completions"
    static let model = "glm-5.3-flash"

    static func chat(body: [String: Any]) async -> String? {
        let target = GLMProxy.url
        if !target.isEmpty {
            guard let url = URL(string: target) else { return nil }
            return await send(body: body, to: url, key: nil)
        }
        guard let key = BYOKeyStore.shared.apiKey, !key.isEmpty else { return nil }
        guard let url = URL(string: endpoint) else { return nil }
        return await send(body: body, to: url, key: key)
    }

    private static func send(body: [String: Any], to url: URL, key: String?) async -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 8
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String else { return nil }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum MilestoneVisionService {
    static func tagMilestone(image: UIImage) async -> String? {
        guard let jpeg = image.jpegData(compressionQuality: 0.6) else { return nil }
        let b64 = jpeg.base64EncodedString()
        let body: [String: Any] = [
            "model": GLMService.model,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]],
                    ["type": "text", "text": "Describe in <=6 words which gross/fine motor or language milestone this baby photo shows. Examples: 'standing independently', 'stacking blocks'. Output only the phrase."]
                ]
            ]],
            "temperature": 0.2,
            "max_tokens": 32
        ]
        return await GLMService.chat(body: body)
    }
}

struct WeeklySummary {
    var sessions: Int
    var totalMinutes: Int
    var totalTaps: Int
    var totalFocusSeconds: Int
    var topWorld: String
}

enum WeeklyReportService {
    static func buildSummary(sessions: [PlaySession], worldNames: [String: String]) -> WeeklySummary {
        let count = sessions.count
        let minutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let taps = sessions.reduce(0) { $0 + $1.tapCount }
        let focus = sessions.reduce(0) { $0 + $1.focusedSeconds }
        var counts: [String: Int] = [:]
        for session in sessions {
            for id in session.worldIDs.split(separator: ",") {
                counts[String(id), default: 0] += 1
            }
        }
        let top = counts.max { $0.value < $1.value }?.key ?? "bubbles"
        return WeeklySummary(sessions: count, totalMinutes: minutes, totalTaps: taps, totalFocusSeconds: focus, topWorld: worldNames[top] ?? top)
    }

    static func insight(summary: WeeklySummary, babyName: String) async -> String {
        let template = "\(babyName) had \(summary.sessions) calm sessions (\(summary.totalMinutes) min) this week, most in \(summary.topWorld)."
        let body: [String: Any] = [
            "model": GLMService.model,
            "messages": [[
                "role": "user",
                "content": "Write ONE gentle development insight (max 30 words) for a parent. Baby stats this week: sessions=\(summary.sessions), minutes=\(summary.totalMinutes), taps=\(summary.totalTaps), focusSeconds=\(summary.totalFocusSeconds), favoriteWorld=\(summary.topWorld). Tone: warm, concrete, no medical claims, no emojis."
            ]],
            "temperature": 0.4,
            "max_tokens": 64
        ]
        return await GLMService.chat(body: body) ?? template
    }
}
