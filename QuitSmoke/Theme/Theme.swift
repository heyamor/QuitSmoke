import SwiftUI

enum Theme {
    static let primary = Color(red: 0.12, green: 0.55, blue: 0.39)
    static let secondary = Color(red: 0.25, green: 0.72, blue: 0.56)
    static let softGreen = Color(red: 0.91, green: 0.97, blue: 0.94)
    static let warm = Color(red: 0.96, green: 0.63, blue: 0.27)
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
    }
}

extension View {
    func appCard() -> some View { modifier(CardModifier()) }
}
