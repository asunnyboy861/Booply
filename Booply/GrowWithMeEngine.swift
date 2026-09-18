import Foundation

enum Stage: Int, CaseIterable, Codable, Comparable {
    case newborn = 0
    case causeEffect = 1
    case soundsWords = 2
    case matching = 3

    nonisolated static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }

    nonisolated static func current(birthdate: Date, now: Date = .now) -> Stage {
        let months = Calendar.current.dateComponents([.month], from: birthdate, to: now).month ?? 0
        switch months {
        case ..<4: return .newborn
        case ..<8: return .causeEffect
        case ..<15: return .soundsWords
        default: return .matching
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .newborn: return "0–3 months"
        case .causeEffect: return "4–7 months"
        case .soundsWords: return "8–14 months"
        case .matching: return "15–24 months"
        }
    }
}

struct World: Identifiable, Codable, Hashable {
    let id: String
    let minStage: Stage
    let maxStage: Stage
    var displayName: String
}

enum WorldCatalog {
    nonisolated static let all: [World] = [
        .init(id: "contrast", minStage: .newborn, maxStage: .causeEffect, displayName: "Black & White"),
        .init(id: "bubbles", minStage: .causeEffect, maxStage: .soundsWords, displayName: "Bubble Pop"),
        .init(id: "starrain", minStage: .causeEffect, maxStage: .matching, displayName: "Star Rain"),
        .init(id: "farm", minStage: .soundsWords, maxStage: .matching, displayName: "Animal Farm"),
        .init(id: "balloons", minStage: .causeEffect, maxStage: .matching, displayName: "Balloons"),
        .init(id: "matching", minStage: .matching, maxStage: .matching, displayName: "Big & Small"),
        .init(id: "shapes", minStage: .soundsWords, maxStage: .matching, displayName: "Shape Glow"),
        .init(id: "repeatme", minStage: .matching, maxStage: .matching, displayName: "Say With Me")
    ]

    nonisolated static func worldsFor(birthdate: Date, now: Date = .now, enabled: Set<String>, pro: Bool) -> [World] {
        let stage = Stage.current(birthdate: birthdate, now: now)
        var eligible = all.filter { $0.minStage <= stage && $0.maxStage >= stage && enabled.contains($0.id) }
        if eligible.isEmpty {
            eligible = all.filter { $0.minStage <= stage && $0.maxStage >= stage }
        }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
        let rotated = eligible.enumerated().sorted { (a, b) in
            (a.offset + day) % eligible.count < (b.offset + day) % eligible.count
        }.map(\.element)
        return pro ? rotated : Array(rotated.prefix(2))
    }
}

struct MilestoneCandidate: Identifiable {
    let id = UUID()
    let title: String
    let category: String
}

enum MilestoneRules {
    nonisolated static func suggestions(tapCount: Int, focusedSeconds: Int, soundFollows: Int, stage: Stage) -> [MilestoneCandidate] {
        var out: [MilestoneCandidate] = []
        if soundFollows >= 3, stage >= .soundsWords {
            out.append(.init(title: "Imitates sounds", category: "language"))
        }
        if tapCount >= 25, stage == .causeEffect {
            out.append(.init(title: "Reaches with purpose", category: "motor"))
        }
        if focusedSeconds >= 150 {
            out.append(.init(title: "Sustained attention", category: "cognitive"))
        }
        return out
    }
}

extension Array {
    func rotated(by offset: Int) -> Array {
        guard !isEmpty else { return self }
        let shift = ((offset % count) + count) % count
        return Array(self[shift...] + self[..<shift])
    }
}
