import SwiftUI
import SwiftData

struct ReceiptView: View {
    let session: PlaySession
    let candidates: [MilestoneCandidate]
    let birthdate: Date
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var purchase: PurchaseManager
    @State private var summary = ""
    @State private var confirmed: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.sageDeep)

                    Text("Today's Quiet Time")
                        .font(.title.bold())
                    Text("\(session.durationMinutes) min")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.sageDeep)

                    card
                    milestones
                    suggestion
                }
                .padding(20)
            }
            .background(Theme.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { onDone() }
                        .font(.body.bold())
                }
            }
            .task {
                summary = await ReceiptComposer.compose(
                    startedAt: session.startedAt,
                    endedAt: session.endedAt,
                    tapCount: session.tapCount,
                    focusedSeconds: session.focusedSeconds,
                    hints: candidates,
                    isPro: purchase.isPro
                )
            }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(symbol: "hands.and.sparkles.fill", text: "\(session.tapCount) happy taps")
            row(symbol: "eye.fill", text: "\(formatFocus(session.focusedSeconds)) of focus")
            if session.soundFollows > 0 {
                row(symbol: "speaker.wave.2.fill", text: "Followed \(session.soundFollows) sounds")
            }
            Divider()
            Text(summary)
                .font(.body.italic())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !candidates.isEmpty {
                Text("New milestone spotted")
                    .font(.headline)
                ForEach(candidates) { candidate in
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(candidate.title)
                            .font(.body)
                        Spacer()
                        if confirmed.contains(candidate.id) {
                            Label("First!", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.sageDeep)
                        } else {
                            Button("Mark as First!") {
                                mark(candidate)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
    }

    private var suggestion: some View {
        Group {
            if let suggestion = suggestionText() {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Suggestion: \(suggestion)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func row(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.sageDeep)
                .frame(width: 24)
            Text(text)
        }
        .font(.body)
    }

    private func formatFocus(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60)m \(seconds % 60)s"
        }
        return "\(seconds)s"
    }

    private func suggestionText() -> String? {
        let worldIDs = Set(session.worldIDs.split(separator: ",").map(String.init))
        if worldIDs.contains("farm") { return "Try pointing at a cow in real life today." }
        if worldIDs.contains("bubbles") { return "Blow a few real bubbles at bath time." }
        if worldIDs.contains("matching") { return "Try stacking two blocks together later." }
        if worldIDs.contains("starrain") { return "Look for stars together before bedtime." }
        if worldIDs.contains("balloons") { return "Tap a balloon back and forth outside." }
        if worldIDs.contains("shapes") { return "Name circle shapes around the room today." }
        if worldIDs.contains("repeatme") { return "Repeat a favorite word slowly to your baby." }
        return "Try a few minutes of tummy time today."
    }

    private func mark(_ candidate: MilestoneCandidate) {
        let milestone = Milestone(title: candidate.title, category: candidate.category)
        milestone.confirmedAt = .now
        context.insert(milestone)
        try? context.save()
        confirmed.insert(candidate.id)
    }
}
