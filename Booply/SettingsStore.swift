import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var sessionMinutes: Int {
        didSet { defaults.set(sessionMinutes, forKey: "sessionMinutes") }
    }
    @Published var volume: Double {
        didSet { defaults.set(volume, forKey: "volume") }
    }
    @Published var hapticsOn: Bool {
        didSet { defaults.set(hapticsOn, forKey: "hapticsOn") }
    }
    @Published var windDownChime: Bool {
        didSet { defaults.set(windDownChime, forKey: "windDownChime") }
    }
    @Published var windowEnabled: Bool {
        didSet { defaults.set(windowEnabled, forKey: "windowEnabled") }
    }
    @Published var windowStartHour: Int {
        didSet { defaults.set(windowStartHour, forKey: "windowStartHour") }
    }
    @Published var windowEndHour: Int {
        didSet { defaults.set(windowEndHour, forKey: "windowEndHour") }
    }
    @Published var disabledWorlds: Set<String> {
        didSet { defaults.set(Array(disabledWorlds).joined(separator: ","), forKey: "disabledWorlds") }
    }
    @Published var iCloudSyncPreferred: Bool {
        didSet { defaults.set(iCloudSyncPreferred, forKey: "iCloudSyncPreferred") }
    }
    @Published var receiptCount: Int {
        didSet { defaults.set(receiptCount, forKey: "receiptCount") }
    }
    @Published var pricingShown: Bool {
        didSet { defaults.set(pricingShown, forKey: "pricingShown") }
    }
    @Published var lastAIReceiptAt: Date? {
        didSet {
            if let date = lastAIReceiptAt {
                defaults.set(date.timeIntervalSince1970, forKey: "lastAIReceiptAt")
            }
        }
    }

    private let defaults: UserDefaults

    private init() {
        defaults = .standard
        sessionMinutes = defaults.object(forKey: "sessionMinutes") as? Int ?? 10
        volume = defaults.object(forKey: "volume") as? Double ?? 0.6
        hapticsOn = defaults.object(forKey: "hapticsOn") as? Bool ?? true
        windDownChime = defaults.object(forKey: "windDownChime") as? Bool ?? true
        windowEnabled = defaults.object(forKey: "windowEnabled") as? Bool ?? false
        windowStartHour = defaults.object(forKey: "windowStartHour") as? Int ?? 7
        windowEndHour = defaults.object(forKey: "windowEndHour") as? Int ?? 20
        let raw = defaults.string(forKey: "disabledWorlds") ?? ""
        disabledWorlds = Set(raw.split(separator: ",").map(String.init))
        iCloudSyncPreferred = defaults.object(forKey: "iCloudSyncPreferred") as? Bool ?? false
        receiptCount = defaults.integer(forKey: "receiptCount")
        pricingShown = defaults.bool(forKey: "pricingShown")
        let stamp = defaults.double(forKey: "lastAIReceiptAt")
        lastAIReceiptAt = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
    }

    func isWithinWindow(now: Date = .now) -> Bool {
        guard windowEnabled else { return true }
        let hour = Calendar.current.component(.hour, from: now)
        if windowStartHour <= windowEndHour {
            return hour >= windowStartHour && hour < windowEndHour
        }
        return hour >= windowStartHour || hour < windowEndHour
    }

    func windowText() -> String {
        String(format: "%02d:00–%02d:00", windowStartHour, windowEndHour)
    }
}
