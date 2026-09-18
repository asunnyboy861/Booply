import Combine
import SwiftData
import SwiftUI
import Vortex

final class SessionTimer: ObservableObject {
    enum Phase { case playing, windingDown, asleep }

    @Published var remaining: TimeInterval
    @Published var phase: Phase = .playing

    private var ticker: Task<Void, Never>?
    let total: TimeInterval

    init(duration: TimeInterval) {
        remaining = duration
        total = duration
    }

    func start(chime: Bool, volume: Double) {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while let self, !Task.isCancelled, self.remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.remaining -= 1
                if self.remaining <= 8, self.phase == .playing {
                    self.phase = .windingDown
                    if chime {
                        SoundBank.play(.chime, volume: volume)
                    }
                }
                if self.remaining <= 0 {
                    self.phase = .asleep
                }
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }
}

struct KidSessionView: View {
    let profile: BabyProfile
    let duration: TimeInterval
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var timer: SessionTimer
    @StateObject private var interactions = SessionInteractions()
    @State private var worlds: [World] = []
    @State private var index = 0
    @State private var burstPoint: CGPoint?
    @State private var burstEffect: VortexSystem = .spark
    @State private var startedAt = Date()
    @State private var showGate = false
    @State private var showReceipt = false
    @State private var receiptSession: PlaySession?
    @State private var receiptCandidates: [MilestoneCandidate] = []

    init(profile: BabyProfile, duration: TimeInterval, onDone: @escaping () -> Void) {
        self.profile = profile
        self.duration = duration
        self.onDone = onDone
        _timer = StateObject(wrappedValue: SessionTimer(duration: duration))
    }

    var body: some View {
        ZStack {
            if timer.phase == .asleep {
                AsleepPageView(onUnlockRequest: { showGate = true })
            } else {
                feed
                    .brightness(timer.phase == .windingDown ? -0.55 : 0)
                    .saturation(timer.phase == .windingDown ? 0.4 : 1)
                    .animation(.easeInOut(duration: 8), value: timer.phase)
            }

            BurstOverlay(burstPoint: burstPoint, effect: burstEffect)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear { prepare() }
        .onDisappear { timer.stop() }
        .onChange(of: index) { oldValue, newValue in
            if let world = worlds.indices.contains(newValue) ? worlds[newValue] : nil {
                interactions.entered(worldID: world.id)
            }
        }
        .fullScreenCover(isPresented: $showGate, onDismiss: {
            if receiptSession != nil { showReceipt = true }
        }) {
            ParentGateView { unlock() }
                .background(Theme.cream)
        }
        .fullScreenCover(isPresented: $showReceipt) {
            if let session = receiptSession {
                ReceiptView(
                    session: session,
                    candidates: receiptCandidates,
                    birthdate: profile.birthdate,
                    onDone: {
                        showReceipt = false
                        onDone()
                    }
                )
            }
        }
    }

    private var feed: some View {
        TabView(selection: $index) {
            ForEach(Array(worlds.enumerated()), id: \.element.id) { i, world in
                WorldScene(
                    world: world,
                    interactions: interactions,
                    volume: settings.volume,
                    onTouch: { point, effect in
                        burstEffect = effect
                        burstPoint = point
                        if settings.hapticsOn { Haptics.softTap() }
                        interactions.tap()
                    }
                )
                .tag(i)
                .ignoresSafeArea()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .topTrailing) {
            unlockCorner
        }
    }

    private var unlockCorner: some View {
        Color.clear
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1.5) {
                showGate = true
            }
            .accessibilityLabel("Parent corner")
    }

    private func prepare() {
        SoundBank.configure()
        worlds = WorldCatalog.worldsFor(birthdate: profile.birthdate, enabled: proEnabledSet(), pro: PurchaseManager.shared.isPro)
        interactions.entered(worldID: worlds.first?.id ?? "bubbles")
        timer.start(chime: settings.windDownChime, volume: settings.volume)
    }

    private func proEnabledSet() -> Set<String> {
        var enabled = Set(WorldCatalog.all.map(\.id))
        enabled.formSymmetricDifference(settings.disabledWorlds)
        return enabled
    }

    private func unlock() {
        showGate = false
        timer.stop()
        interactions.finalize()
        let endedAt = Date()
        interactions.save(into: context, startedAt: startedAt, endedAt: endedAt)
        let stage = Stage.current(birthdate: profile.birthdate)
        receiptCandidates = MilestoneRules.suggestions(
            tapCount: interactions.tapCount,
            focusedSeconds: interactions.focusedSeconds,
            soundFollows: interactions.soundFollows,
            stage: stage
        )
        let record = PlaySession(
            startedAt: startedAt,
            endedAt: endedAt,
            worldIDs: Array(interactions.worldIDs),
            tapCount: interactions.tapCount,
            focusedSeconds: interactions.focusedSeconds,
            soundFollows: interactions.soundFollows
        )
        receiptSession = record
    }
}

struct AsleepPageView: View {
    let onUnlockRequest: () -> Void
    @State private var breathe = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white.opacity(0.85))
                    .scaleEffect(breathe ? 1.08 : 0.95)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathe)
            }
        }
        .onAppear { breathe = true }
        .overlay(alignment: .topTrailing) {
            Color.clear
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 1.5) {
                    Haptics.gentlePulse()
                    onUnlockRequest()
                }
                .accessibilityLabel("Parent corner")
        }
    }
}
