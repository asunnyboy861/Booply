import Combine
import Foundation
import SwiftData

@MainActor
final class SessionInteractions: ObservableObject {
    private(set) var tapCount = 0
    private(set) var focusedSeconds = 0
    private(set) var soundFollows = 0
    private(set) var worldIDs: Set<String> = []
    private var lastSoundAt: Date?
    private var lastWorldChange = Date()

    func tap() {
        tapCount += 1
        if let soundAt = lastSoundAt, Date().timeIntervalSince(soundAt) <= 1.0 {
            soundFollows += 1
            lastSoundAt = nil
        }
    }

    func soundPlayed() {
        lastSoundAt = Date()
    }

    func entered(worldID: String) {
        worldIDs.insert(worldID)
        let dwell = Date().timeIntervalSince(lastWorldChange)
        if dwell > 2 {
            focusedSeconds += Int(dwell)
        }
        lastWorldChange = Date()
    }

    func finalize() {
        let dwell = Date().timeIntervalSince(lastWorldChange)
        if dwell > 2 {
            focusedSeconds += Int(dwell)
        }
        lastWorldChange = Date()
    }

    func save(into context: ModelContext, startedAt: Date, endedAt: Date) {
        let session = PlaySession(
            startedAt: startedAt,
            endedAt: endedAt,
            worldIDs: Array(worldIDs),
            tapCount: tapCount,
            focusedSeconds: focusedSeconds,
            soundFollows: soundFollows
        )
        context.insert(session)
        try? context.save()
    }
}
