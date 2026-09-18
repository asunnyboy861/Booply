import SwiftUI
import Vortex

struct WorldScene: View {
    let world: World
    let interactions: SessionInteractions
    let volume: Double
    let onTouch: (CGPoint, VortexSystem) -> Void

    var body: some View {
        switch world.id {
        case "contrast": ContrastWorldView()
        case "bubbles": BubblesWorldView(onTouch: onTouch)
        case "starrain": StarRainWorldView(onTouch: onTouch)
        case "farm": FarmWorldView(interactions: interactions, volume: volume, onTouch: onTouch)
        case "balloons": BalloonsWorldView(onTouch: onTouch)
        case "matching": MatchingWorldView(onTouch: onTouch)
        case "shapes": ShapesWorldView(onTouch: onTouch)
        case "repeatme": RepeatMeWorldView(interactions: interactions, volume: volume)
        default: BubblesWorldView(onTouch: onTouch)
        }
    }
}

struct ContrastWorldView: View {
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                VStack(spacing: 0) {
                    Circle()
                        .stroke(.white, lineWidth: 14)
                        .frame(width: geo.size.width * 0.7)
                        .offset(x: drift ? geo.size.width * 0.08 : -geo.size.width * 0.08)
                    Stripes()
                        .opacity(0.9)
                        .frame(height: geo.size.height * 0.3)
                        .offset(x: drift ? -40 : 40)
                    Circle()
                        .fill(.white)
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: drift ? -geo.size.width * 0.1 : geo.size.width * 0.1)
                }
            }
        }
        .onAppear { drift = true }
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: drift)
    }
}

private struct Stripes: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { i in
                Rectangle()
                    .fill(i % 2 == 0 ? .white : .black)
            }
        }
    }
}

struct BubblesWorldView: View {
    let onTouch: (CGPoint, VortexSystem) -> Void
    @State private var bubbles: [BubbleItem] = (0..<9).map { BubbleItem(id: $0) }

    struct BubbleItem: Identifiable {
        let id: Int
        var x: CGFloat = .random(in: 0.12...0.88)
        var y: CGFloat = .random(in: 0.15...0.85)
        var size: CGFloat = .random(in: 60...110)
        var hue: Double = .random(in: 0.5...0.62)
        var alive = true
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.92, blue: 0.97), Color(red: 0.93, green: 0.97, blue: 0.94)],
                    startPoint: .top, endPoint: .bottom
                )
                ForEach(bubbles) { bubble in
                    if bubble.alive {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hue: bubble.hue, saturation: 0.25, brightness: 1).opacity(0.9), Color(hue: bubble.hue, saturation: 0.5, brightness: 0.95).opacity(0.5)],
                                    center: .topLeading, startRadius: 4, endRadius: bubble.size
                                )
                            )
                            .frame(width: bubble.size, height: bubble.size)
                            .position(x: bubble.x * geo.size.width, y: bubble.y * geo.size.height)
                            .onTapGesture { location in
                                pop(bubble: bubble, location: location)
                            }
                    }
                }
            }
        }
        .onTapGesture { location in
            onTouch(location, .spark)
        }
    }

    private func pop(bubble: BubbleItem, location: CGPoint) {
        if let idx = bubbles.firstIndex(where: { $0.id == bubble.id }) {
            bubbles[idx].alive = false
        }
        onTouch(location, .spark)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if let idx = bubbles.firstIndex(where: { $0.id == bubble.id }) {
                bubbles[idx].x = .random(in: 0.12...0.88)
                bubbles[idx].y = .random(in: 0.15...0.85)
                bubbles[idx].alive = true
            }
        }
    }
}

struct StarRainWorldView: View {
    let onTouch: (CGPoint, VortexSystem) -> Void
    @State private var stars: Int = 0
    @State private var raining = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.16)
                ForEach(0..<40, id: \.self) { i in
                    Circle()
                        .fill(.yellow)
                        .frame(width: 6, height: 6)
                        .opacity(opacityFor(i))
                        .position(x: (CGFloat(i % 10) + 0.5) / 10 * geo.size.width + (raining ? 10 : 0), y: raining ? geo.size.height * 0.9 : CGFloat((i / 10) + 1) / 5 * geo.size.height * 0.5)
                        .animation(raining ? .easeIn(duration: 1.1).delay(Double(i % 5) * 0.08) : .easeOut(duration: 0.6), value: raining)
                }
                VStack {
                    Spacer()
                    Text(stars > 0 ? "" : "")
                        .font(.system(size: 30))
                        .foregroundStyle(.yellow.opacity(0.8))
                        .padding(.bottom, 60)
                }
            }
        }
        .gesture(
            LongPressGesture(minimumDuration: .infinity)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onChanged { _ in
                    if !raining { stars = min(stars + 1, 12) }
                }
                .onEnded { _ in
                    release()
                }
        )
        .onTapGesture { location in
            onTouch(location, .spark)
            release()
        }
    }

    private func opacityFor(_ i: Int) -> Double {
        Double(min(stars, 12)) / 12.0 * 0.9
    }

    private func release() {
        guard stars > 0 else { return }
        onTouch(CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY), .spark)
        raining = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            raining = false
            stars = 0
        }
    }
}

struct FarmWorldView: View {
    let interactions: SessionInteractions
    let volume: Double
    let onTouch: (CGPoint, VortexSystem) -> Void

    private let animals: [(emoji: String, name: String)] = [
        ("🐮", "cow"), ("🐔", "chicken"), ("🐷", "pig"),
        ("🐑", "sheep"), ("🐴", "horse"), ("🦆", "duck")
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.88, green: 0.94, blue: 0.84), Color(red: 0.95, green: 0.91, blue: 0.8)], startPoint: .top, endPoint: .bottom)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                    ForEach(0..<6, id: \.self) { i in
                        Text(animals[i].emoji)
                            .font(.system(size: 64))
                            .onTapGesture { location in
                                touch(animal: animals[i], location: location)
                            }
                            .accessibilityLabel(animals[i].name)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
        }
    }

    private func touch(animal: (emoji: String, name: String), location: CGPoint) {
        onTouch(location, .spark)
        SpeechHelper.shared.onSpeakFinish = { interactions.soundPlayed() }
        SpeechHelper.shared.speak(animal.name)
        SoundBank.play(.transition, volume: volume * 0.6)
    }
}

struct BalloonsWorldView: View {
    let onTouch: (CGPoint, VortexSystem) -> Void
    @State private var balloons: [BalloonItem] = (0..<7).map { BalloonItem(id: $0) }

    struct BalloonItem: Identifiable {
        let id: Int
        var y: CGFloat = .random(in: 0.2...0.85)
        var x: CGFloat = .random(in: 0.15...0.85)
        var hue: Double = .random(in: 0.0...1.0)
        var driftPhase: Double = .random(in: 0...2)
        var size: CGFloat = .random(in: 70...100)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.93, green: 0.96, blue: 0.99)
                ForEach(balloons) { balloon in
                    BalloonShape(hue: balloon.hue)
                        .frame(width: balloon.size * 0.8, height: balloon.size)
                        .position(
                            x: balloon.x * geo.size.width + CGFloat(sin(balloon.driftPhase + balloon.y * 6) * 18),
                            y: balloon.y * geo.size.height
                        )
                        .onTapGesture(count: 2) { location in
                            pop(balloon: balloon, location: location)
                        }
                        .onTapGesture { location in
                            rise(balloon: balloon, location: location)
                        }
                }
            }
        }
    }

    private func rise(balloon: BalloonItem, location: CGPoint) {
        if let idx = balloons.firstIndex(where: { $0.id == balloon.id }) {
            balloons[idx].y = max(0.06, balloons[idx].y - 0.18)
            balloons[idx].driftPhase += 1.2
        }
        onTouch(location, .spark)
    }

    private func pop(balloon: BalloonItem, location: CGPoint) {
        if let idx = balloons.firstIndex(where: { $0.id == balloon.id }) {
            balloons[idx].y = .random(in: 0.5...0.85)
            balloons[idx].x = .random(in: 0.15...0.85)
            balloons[idx].hue = .random(in: 0...1)
        }
        onTouch(location, .confetti)
    }
}

private struct BalloonShape: View {
    let hue: Double

    var body: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Color(hue: hue, saturation: 0.45, brightness: 1), Color(hue: hue, saturation: 0.6, brightness: 0.85)], center: .topLeading, startRadius: 2, endRadius: 90))
                .aspectRatio(0.8, contentMode: .fit)
            Rectangle()
                .stroke(Color(hue: hue, saturation: 0.4, brightness: 0.7), lineWidth: 2)
                .frame(width: 2, height: 34)
                .offset(y: 52)
        }
    }
}

struct MatchingWorldView: View {
    let onTouch: (CGPoint, VortexSystem) -> Void
    @State private var bearOffset: CGSize = .zero
    @State private var solved = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.96, green: 0.94, blue: 0.9)
                VStack(spacing: geo.size.height * 0.12) {
                    Text("🏠")
                        .font(.system(size: 110))
                        .opacity(solved ? 1 : 0.95)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Theme.sage, lineWidth: solved ? 5 : 2)
                                .frame(width: 130, height: 130)
                        )
                        .accessibilityLabel("Big house")
                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 60)

                Text("🧸")
                    .font(.system(size: 88))
                    .offset(bearOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !solved { bearOffset = value.translation }
                            }
                            .onEnded { value in
                                let bearPosition = CGPoint(x: geo.size.width / 2 + value.translation.width, y: geo.size.height * 0.18 + value.translation.height)
                                let house = CGPoint(x: geo.size.width / 2, y: 120)
                                if distance(bearPosition, house) < 90 {
                                    snap(to: house, from: geo)
                                } else {
                                    withAnimation(.easeOut(duration: 0.4)) { bearOffset = .zero }
                                }
                            }
                    )
                    .accessibilityLabel("Big bear")
            }
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private func snap(to house: CGPoint, from geo: GeometryProxy) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            bearOffset = CGSize(width: house.x - geo.size.width / 2, height: house.y - geo.size.height / 2)
        }
        solved = true
        onTouch(CGPoint(x: geo.size.width / 2, y: 120), .spark)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            solved = false
            withAnimation(.easeOut(duration: 0.5)) { bearOffset = .zero }
        }
    }
}

struct ShapesWorldView: View {
    let onTouch: (CGPoint, VortexSystem) -> Void
    @State private var activeHue: Double?

    private let palette: [Double] = [0.35, 0.08, 0.55, 0.62]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.94, green: 0.95, blue: 0.97)
                ForEach(0..<8, id: \.self) { i in
                    let hue = palette[i % palette.count]
                    Circle()
                        .fill(Color(hue: hue, saturation: activeHue == hue ? 0.65 : 0.2, brightness: 1))
                        .shadow(color: activeHue == hue ? Color(hue: hue, saturation: 0.6, brightness: 0.9).opacity(0.8) : .clear, radius: 24)
                        .frame(width: sizeFor(i, geo: geo))
                        .position(positionFor(i, geo: geo))
                        .animation(.easeOut(duration: 0.5), value: activeHue)
                        .onTapGesture { location in
                            onTouch(location, .spark)
                            activeHue = hue
                        }
                }
            }
        }
    }

    private func sizeFor(_ i: Int, geo: GeometryProxy) -> CGFloat {
        geo.size.width * (0.22 + CGFloat(i % 3) * 0.12)
    }

    private func positionFor(_ i: Int, geo: GeometryProxy) -> CGPoint {
        let xs: [CGFloat] = [0.25, 0.75, 0.5, 0.2, 0.8, 0.35, 0.65, 0.5]
        let ys: [CGFloat] = [0.25, 0.3, 0.5, 0.72, 0.68, 0.48, 0.85, 0.12]
        return CGPoint(x: xs[i] * geo.size.width, y: ys[i] * geo.size.height)
    }
}

struct RepeatMeWorldView: View {
    let interactions: SessionInteractions
    let volume: Double
    @State private var currentWord: String?
    @State private var listening = false

    private let words = ["mama", "dada", "ball", "moo", "bye", "up", "hi", "yum"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.9, green: 0.88, blue: 0.96), Color(red: 0.95, green: 0.93, blue: 0.87)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 40) {
                Image(systemName: listening ? "waveform" : "speech.bubble.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.sageDeep)
                Text(currentWord ?? "Tap to say a word")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
            }
        }
        .onTapGesture { location in
            guard !listening else { return }
            listening = true
            let word = words.randomElement() ?? "hi"
            currentWord = word
            SoundBank.play(.transition, volume: volume * 0.5)
            SpeechHelper.shared.onSpeakFinish = {
                interactions.soundPlayed()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    SoundBank.cheerSequence(volume: volume)
                    listening = false
                }
            }
            SpeechHelper.shared.speak(word)
        }
        .accessibilityLabel("Say with me")
    }
}
