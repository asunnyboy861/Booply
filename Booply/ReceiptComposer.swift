import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum ReceiptComposer {
    static func compose(startedAt: Date, endedAt: Date, tapCount: Int, focusedSeconds: Int, hints: [MilestoneCandidate], isPro: Bool, aiEnabledOverride: Bool = true) async -> String {
        let template = localTemplate(startedAt: startedAt, endedAt: endedAt, tapCount: tapCount, focusedSeconds: focusedSeconds, hints: hints)
        guard aiEnabledOverride else { return template }
        guard usageAllowed(isPro: isPro) else { return template }
        guard #available(iOS 26.0, *) else { return template }
        guard appleIntelligenceAvailable() else { return template }
        do {
            let facts = """
                taps=\(tapCount), focusedSeconds=\(focusedSeconds),
                hints=\(hints.map(\.title).joined(separator: ", ")),
                minutes=\(Int(endedAt.timeIntervalSince(startedAt) / 60))
                """
            return try await withTimeout(seconds: 8) {
                try await appleCompose(facts: facts)
            } ?? template
        } catch {
            return template
        }
    }

    static func localTemplate(startedAt: Date, endedAt: Date, tapCount: Int, focusedSeconds: Int, hints: [MilestoneCandidate]) -> String {
        let minutes = max(1, Int(endedAt.timeIntervalSince(startedAt) / 60))
        let focus = "\(minutes) min of calm play · \(tapCount) taps · \(focusedSeconds)s of focus"
        guard !hints.isEmpty else { return focus }
        return focus + " · " + hints.map(\.title).joined(separator: " · ")
    }

    private static func usageAllowed(isPro: Bool) -> Bool {
        guard !isPro else { return true }
        if let last = SettingsStore.shared.lastAIReceiptAt {
            return Date().timeIntervalSince(last) > 6 * 24 * 3600
        }
        return true
    }

    @available(iOS 26.0, *)
    private static func appleIntelligenceAvailable() -> Bool {
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else { return false }
        return true
        #else
        return false
        #endif
    }

    @available(iOS 26.0, *)
    private static func appleCompose(facts: String) async throws -> String {
        #if canImport(FoundationModels)
        let session = LanguageModelSession(instructions: """
            Write ONE warm sentence for a parent summarizing their baby's play session.
            Facts: \(facts). Tone: proud, gentle, under 22 words. No emojis.
            """)
        let response = try await session.respond(to: "Write the summary.")
        await markAIUsed()
        return response.content
        #else
        return ""
        #endif
    }

    private static func markAIUsed() async {
        await MainActor.run {
            SettingsStore.shared.lastAIReceiptAt = .now
        }
    }

    private static func withTimeout(seconds: TimeInterval, work: @escaping () async throws -> String) async throws -> String? {
        try await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask { try await work() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                return nil
            }
            let first = try await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
