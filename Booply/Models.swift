import Foundation
import SwiftData

@Model
final class BabyProfile {
    var birthdate: Date
    var companionName: String
    var createdAt: Date

    init(birthdate: Date, companionName: String) {
        self.birthdate = birthdate
        self.companionName = companionName
        self.createdAt = .now
    }
}

@Model
final class PlaySession {
    var startedAt: Date
    var endedAt: Date
    var worldIDs: String
    var tapCount: Int
    var focusedSeconds: Int
    var soundFollows: Int

    var durationMinutes: Int {
        max(1, Int(endedAt.timeIntervalSince(startedAt) / 60))
    }

    init(startedAt: Date, endedAt: Date, worldIDs: [String], tapCount: Int, focusedSeconds: Int, soundFollows: Int) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.worldIDs = worldIDs.joined(separator: ",")
        self.tapCount = tapCount
        self.focusedSeconds = focusedSeconds
        self.soundFollows = soundFollows
    }
}

@Model
final class Milestone {
    var title: String
    var category: String
    var suggestedAt: Date
    var confirmedAt: Date?
    var photoData: Data?
    var aiTag: String?

    init(title: String, category: String) {
        self.title = title
        self.category = category
        self.suggestedAt = .now
    }
}
