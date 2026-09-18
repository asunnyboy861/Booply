import SwiftUI

struct ParentGateView: View {
    let onPass: () -> Void
    @State private var answer = ""
    @State private var round = 1
    @State private var a = Int.random(in: 4...9)
    @State private var b = Int.random(in: 4...9)
    @State private var shake = false

    private let pad = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["clear", "0", "ok"]]

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Theme.sageDeep)
            Text("Grown-ups only")
                .font(.title2.bold())
            Text("\(a) + \(b) = ?")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(answer.isEmpty ? " " : answer)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .frame(width: 160, height: 64)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(shake ? Color.red : Theme.separator, lineWidth: shake ? 2 : 1)
                )
                .offset(x: shake ? -8 : 0)
                .animation(.default, value: shake)
            keypad
                .padding(.horizontal, 40)
            if round > 1 {
                Text("One more to confirm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private var keypad: some View {
        VStack(spacing: 14) {
            ForEach(pad, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(row, id: \.self) { key in
                        Button { press(key) } label: {
                            Text(key == "clear" ? "C" : key == "ok" ? "OK" : key)
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    key == "ok" ? Theme.sageDeep : Theme.card,
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                                .foregroundStyle(key == "ok" ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(key == "ok" ? "Submit answer" : "Digit \(key)")
                    }
                }
            }
        }
    }

    private func press(_ key: String) {
        switch key {
        case "clear":
            answer = ""
        case "ok":
            submit()
        default:
            if answer.count < 3 { answer += key }
        }
    }

    private func submit() {
        guard Int(answer) == a + b else {
            shakeWrong()
            return
        }
        if round >= 2 {
            onPass()
        } else {
            round += 1
            answer = ""
            a = Int.random(in: 4...9)
            b = Int.random(in: 4...9)
        }
    }

    private func shakeWrong() {
        answer = ""
        withAnimation(.easeInOut(duration: 0.08)) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { shake = false }
        }
        a = Int.random(in: 4...9)
        b = Int.random(in: 4...9)
    }
}
