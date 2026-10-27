import SwiftUI

enum CatTheme {
    static let paper = Color(hex: 0xF8F3EC)
    static let ink = Color(hex: 0x493846)
    static let rose = Color(hex: 0xA66378)
    static let sage = Color(hex: 0x879B83)
    static let lavender = Color(hex: 0xAAA1C2)
    static let coats: [Color] = [Color(hex: 0xECAF7A), Color(hex: 0xAAA8BD), Color(hex: 0x5F5669), Color(hex: 0xEEE0CA), Color(hex: 0xD59D93), Color(hex: 0xB28D70)]
    static let roomNames = ["Сонячна вітальня", "Місячна мансарда", "Таємний сад"]
    static let hatNames = ["Без прикрас", "Бантик", "Берет", "Корона"]
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
}

struct SoftCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20).background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(CatTheme.ink.opacity(0.07), lineWidth: 1))
    }
}

extension View { func softCard() -> some View { modifier(SoftCard()) } }
