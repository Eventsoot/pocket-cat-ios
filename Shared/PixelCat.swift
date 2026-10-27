import SwiftUI

/// Original code-drawn artwork, shared by the app, widgets and Dynamic Island.
struct PixelCat: View {
    var sleeping = false
    var frame = 0
    var color: Color = Color(red: 1, green: 0.71, blue: 0.43)

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / 22, size.height / 18)
            let origin = CGPoint(x: (size.width - unit * 22) / 2, y: (size.height - unit * 18) / 2)
            func block(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ fill: Color) {
                context.fill(Path(CGRect(x: origin.x + CGFloat(x) * unit, y: origin.y + CGFloat(y) * unit, width: CGFloat(w) * unit, height: CGFloat(h) * unit)), with: .color(fill))
            }
            let ink = Color(red: 0.24, green: 0.16, blue: 0.23)
            block(4, 7, 13, 8, ink)
            block(5, 6, 11, 9, color)
            block(3, 2, 3, 8, ink); block(12, 2, 3, 8, ink)
            block(4, 3, 2, 5, color); block(12, 3, 2, 5, color)
            block(4, 5, 10, 7, color)
            block(5, 4, 1, 2, .pink.opacity(0.7)); block(12, 4, 1, 2, .pink.opacity(0.7))
            block(17, frame % 2 == 0 ? 8 : 6, 3, 2, ink)
            block(19, frame % 2 == 0 ? 5 : 3, 2, 5, color)
            block(6, 14, 3, frame % 2 == 0 ? 3 : 2, ink)
            block(13, 14, 3, frame % 2 == 0 ? 2 : 3, ink)
            block(7, 8, sleeping ? 2 : 1, 1, ink)
            block(11, 8, sleeping ? 2 : 1, 1, ink)
            block(9, 10, 1, 1, .pink)
            block(9, 12, 4, 2, Color.white.opacity(0.6))
            block(2, 10, 3, 1, ink.opacity(0.5)); block(14, 10, 3, 1, ink.opacity(0.5))
        }
        .accessibilityLabel(sleeping ? "Котик спит" : "Рыжий пиксельный котик")
    }
}
