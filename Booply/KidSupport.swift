import AVFoundation
import CoreHaptics
import SwiftUI
import Vortex

enum Haptics {
    private static let engine = try? CHHapticEngine()
    private static var supportsHaptics: Bool { CHHapticEngine.capabilitiesForHardware().supportsHaptics }

    static func softTap() {
        guard supportsHaptics, let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []) else { return }
        try? engine.start()
        if let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }

    static func gentlePulse() {
        guard supportsHaptics, let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity], relativeTime: 0, duration: 0.6)
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []) else { return }
        try? engine.start()
        if let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}

enum SoundBank {
    enum Tone {
        case pop, harp, balloon, cheer, transition, success, chime

        var frequency: Double {
            switch self {
            case .pop: return 660
            case .harp: return 880
            case .balloon: return 523
            case .cheer: return 784
            case .transition: return 440
            case .success: return 659
            case .chime: return 587
            }
        }

        var duration: Double {
            switch self {
            case .pop: return 0.12
            case .harp: return 0.5
            case .balloon: return 0.2
            case .cheer: return 0.6
            case .transition: return 0.3
            case .success: return 0.4
            case .chime: return 0.8
            }
        }
    }

    private static var players: [Int: AVAudioPlayer] = [:]

    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    static func play(_ tone: Tone, volume: Double) {
        let key = tone.hashValue
        if let cached = players[key] {
            cached.volume = Float(volume)
            cached.currentTime = 0
            cached.play()
            return
        }
        guard let data = sineWave(freq: tone.frequency, seconds: tone.duration, fade: true) else { return }
        let player = try? AVAudioPlayer(data: data)
        guard let player else { return }
        player.volume = Float(volume)
        player.prepareToPlay()
        player.play()
        players[key] = player
    }

    static func cheerSequence(volume: Double) {
        play(.cheer, volume: volume)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { play(.success, volume: volume) }
    }

    private static func sineWave(freq: Double, seconds: Double, fade: Bool) -> Data? {
        let sampleRate = 44100
        let count = Int(Double(sampleRate) * seconds)
        var samples = [Int16](repeating: 0, count: count)
        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)
            var amp = 0.35
            if fade {
                let ramp = min(t / 0.02, 1.0) * min((seconds - t) / 0.05, 1.0)
                amp *= max(0, min(1, ramp))
            }
            samples[i] = Int16(sin(2 * .pi * freq * t) * amp * Double(Int16.max))
        }
        var data = Data()
        appendWaveHeader(to: &data, sampleCount: count, sampleRate: sampleRate)
        samples.withUnsafeBufferPointer { buffer in
            data.append(UnsafeBufferPointer(start: UnsafePointer(buffer.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count * 2) { $0 }), count: count * 2))
        }
        return data
    }

    private static func appendWaveHeader(to data: inout Data, sampleCount: Int, sampleRate: Int) {
        let dataSize = UInt32(sampleCount * 2)
        func le32(_ v: UInt32) -> [UInt8] {
            [UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 24) & 0xff)]
        }
        func le16(_ v: UInt16) -> [UInt8] {
            [UInt8(v & 0xff), UInt8((v >> 8) & 0xff)]
        }
        data.append(contentsOf: Array("RIFF".utf8))
        data.append(contentsOf: le32(36 + dataSize))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        data.append(contentsOf: le32(16))
        data.append(contentsOf: le16(1))
        data.append(contentsOf: le16(1))
        data.append(contentsOf: le32(UInt32(sampleRate)))
        data.append(contentsOf: le32(UInt32(sampleRate * 2)))
        data.append(contentsOf: le16(2))
        data.append(contentsOf: le16(16))
        data.append(contentsOf: Array("data".utf8))
        data.append(contentsOf: le32(dataSize))
    }
}

@MainActor
final class SpeechHelper: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechHelper()
    private let synthesizer = AVSpeechSynthesizer()
    var onSpeakFinish: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.38
        utterance.volume = 0.8
        utterance.postUtteranceDelay = 0.5
        synthesizer.speak(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.onSpeakFinish?()
        }
    }
}

struct BurstOverlay: View {
    let burstPoint: CGPoint?
    let effect: VortexSystem

    var body: some View {
        VortexViewReader { proxy in
            VortexView(effect) {
                Group {
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .blendMode(.plusLighter)
                        .tag("circle")
                    Rectangle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .blendMode(.plusLighter)
                        .tag("square")
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .onChange(of: burstPoint) { _, newValue in
                if let point = newValue {
                    proxy.move(to: point)
                    proxy.burst()
                }
            }
        }
    }
}
