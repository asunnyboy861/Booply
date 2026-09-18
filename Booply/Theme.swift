import SwiftUI

enum Theme {
    static let sage = Color(red: 0.659, green: 0.765, blue: 0.627)
    static let sageDeep = Color(red: 0.435, green: 0.561, blue: 0.408)
    static let cream = Color(red: 1.0, green: 0.976, blue: 0.941)
    static let cardCorner: CGFloat = 20

    static var background: Color { Color(uiColor: .systemGroupedBackground) }
    static var card: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    static var separator: Color { Color(uiColor: .separator) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.sageDeep, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
