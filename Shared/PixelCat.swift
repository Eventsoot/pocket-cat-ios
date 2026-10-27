import SwiftUI

/// Original code-drawn artwork, shared by the app, widgets and Dynamic Island.
struct LegacyPixelCat: View {
    var sleeping = false
    var frame = 0
    var color: Color = Color(red: 1, green: 0.71, blue: 0.43)
    var hat = 0
    var happy = false

    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / 22, size.height / 18)
            let origin = CGPoint(x: (size.width - unit * 22) / 2, y: (size.height - unit * 18) / 2)
            func block(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ fill: Color) {
                context.fill(Path(CGRect(x: origin.x + CGFloat(x) * unit, y: origin.y + CGFloat(y) * unit, width: CGFloat(w) * unit, height: CGFloat(h) * unit)), with: .color(fill))
            }
            let ink = Color(red: 0.24, green: 0.16, blue: 0.23)
            if sleeping {
                block(3, 9, 15, 6, ink); block(4, 8, 13, 6, color)
                block(2, 10, 7, 4, color); block(2, 8, 2, 3, color); block(7, 8, 2, 3, color)
                block(3, 11, 2, 1, ink); block(6, 11, 2, 1, ink)
                block(11, 12, 7, 2, .white.opacity(0.6))
                return
            }
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
            block(7, 8, happy ? 2 : 1, happy ? 1 : 2, ink)
            block(11, 8, happy ? 2 : 1, happy ? 1 : 2, ink)
            block(9, 10, 1, 1, .pink)
            block(9, 12, 4, 2, Color.white.opacity(0.6))
            block(2, 10, 3, 1, ink.opacity(0.5)); block(14, 10, 3, 1, ink.opacity(0.5))
            block(8, 5, 1, 2, ink.opacity(0.22)); block(10, 5, 1, 2, ink.opacity(0.22))
            if hat == 1 {
                block(11, 3, 2, 2, Color(hex: 0xB7718B)); block(14, 3, 2, 2, Color(hex: 0xB7718B)); block(13, 4, 1, 1, .pink)
            } else if hat == 2 {
                block(6, 1, 9, 3, Color(hex: 0x899C83)); block(9, 0, 3, 1, Color(hex: 0x71836B))
            } else if hat == 3 {
                block(6, 1, 1, 3, .yellow); block(9, 0, 1, 4, .yellow); block(12, 1, 1, 3, .yellow); block(6, 3, 7, 1, .orange)
            }
        }
        .accessibilityLabel(sleeping ? "Котик спит" : "Твой пиксельный котик")
    }
}
