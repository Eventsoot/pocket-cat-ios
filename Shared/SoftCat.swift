import SwiftUI

/// Rounded, expressive original mascot shared across the app, video and widgets.
struct PixelCat: View {
    var sleeping = false
    var frame = 0
    var color = Color(hex: 0xECAF7A)
    var hat = 0
    var happy = false
    var blinking = false

    var body: some View {
        Canvas { c, size in
            let scale = min(size.width / 160, size.height / 140)
            c.translateBy(x: (size.width - 160 * scale) / 2, y: (size.height - 140 * scale) / 2)
            c.scaleBy(x: scale, y: scale)
            let ink = Color(hex: 0x664C51)
            func shape(_ path: Path, _ fill: Color, stroke: Bool = true) {
                c.fill(path, with: .color(fill))
                if stroke { c.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)) }
            }
            func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ fill: Color, stroke: Bool = true) {
                shape(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), fill, stroke: stroke)
            }
            func line(_ points: [CGPoint], width: CGFloat = 2, tint: Color? = nil) {
                var p = Path(); guard let first = points.first else { return }; p.move(to: first)
                for point in points.dropFirst() { p.addLine(to: point) }
                c.stroke(p, with: .color(tint ?? ink), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            var tail = Path()
            tail.move(to: CGPoint(x: 112, y: 109))
            tail.addCurve(to: CGPoint(x: frame % 2 == 0 ? 142 : 137, y: 69), control1: CGPoint(x: 149,y: 114), control2: CGPoint(x: 153,y: 81))
            c.stroke(tail, with: .color(ink), style: StrokeStyle(lineWidth: 16,lineCap: .round))
            c.stroke(tail, with: .color(color), style: StrokeStyle(lineWidth: 11,lineCap: .round))
            if sleeping {
                oval(25, 76, 103, 48, color)
                oval(32, 84, 68, 31, .white.opacity(0.32), stroke: false)
                var ear = Path(); ear.move(to: CGPoint(x: 22,y: 92)); ear.addQuadCurve(to: CGPoint(x: 27,y: 68), control: CGPoint(x: 16,y: 54)); ear.addLine(to: CGPoint(x: 48,y: 85)); ear.closeSubpath(); shape(ear, color)
                oval(17, 82, 62, 41, color)
                line([CGPoint(x: 29,y: 101), CGPoint(x: 34,y: 104), CGPoint(x: 39,y: 101)])
                line([CGPoint(x: 53,y: 101), CGPoint(x: 58,y: 104), CGPoint(x: 63,y: 101)])
                oval(44, 108, 6, 4, Color(hex: 0xBD7E91), stroke: false)
                return
            }
            oval(42, 66, 78, 63, color)
            oval(58, 86, 43, 36, Color(hex: 0xFFF1DA).opacity(0.8), stroke: false)
            let step: CGFloat = frame % 2 == 0 ? 2 : -2
            oval(44, 115 + step, 28, 15, color)
            oval(92, 115 - step, 28, 15, color)
            var head = Path()
            head.move(to: CGPoint(x: 27,y: 62))
            head.addQuadCurve(to: CGPoint(x: 30,y: 15), control: CGPoint(x: 17,y: 5))
            head.addQuadCurve(to: CGPoint(x: 59,y: 30), control: CGPoint(x: 42,y: 13))
            head.addQuadCurve(to: CGPoint(x: 91,y: 29), control: CGPoint(x: 75,y: 22))
            head.addQuadCurve(to: CGPoint(x: 120,y: 16), control: CGPoint(x: 120,y: 4))
            head.addQuadCurve(to: CGPoint(x: 127,y: 64), control: CGPoint(x: 135,y: 38))
            head.addCurve(to: CGPoint(x: 27,y: 62), control1: CGPoint(x: 134,y: 111), control2: CGPoint(x: 18,y: 108))
            shape(head, color)
            var inner = Path(); inner.move(to: CGPoint(x: 31,y: 24)); inner.addLine(to: CGPoint(x: 34,y: 46)); inner.addLine(to: CGPoint(x: 49,y: 35)); inner.closeSubpath(); shape(inner, Color(hex: 0xD69A9E), stroke: false)
            var inner2 = Path(); inner2.move(to: CGPoint(x: 117,y: 24)); inner2.addLine(to: CGPoint(x: 103,y: 35)); inner2.addLine(to: CGPoint(x: 121,y: 47)); inner2.closeSubpath(); shape(inner2, Color(hex: 0xD69A9E), stroke: false)
            oval(37, 73, 19, 10, Color(hex: 0xE6A4A1).opacity(0.65), stroke: false)
            oval(99, 73, 19, 10, Color(hex: 0xE6A4A1).opacity(0.65), stroke: false)
            if happy || blinking {
                line([CGPoint(x: 48,y: 64),CGPoint(x: 55,y: 59),CGPoint(x: 62,y: 64)],width: 3)
                line([CGPoint(x: 91,y: 64),CGPoint(x: 98,y: 59),CGPoint(x: 105,y: 64)],width: 3)
            } else {
                oval(51, 56, 10, 16, ink, stroke: false); oval(93, 56, 10, 16, ink, stroke: false)
                oval(53, 58, 3, 4, .white, stroke: false); oval(95, 58, 3, 4, .white, stroke: false)
            }
            var nose = Path(); nose.move(to: CGPoint(x: 72,y: 74)); nose.addQuadCurve(to: CGPoint(x: 82,y: 74),control: CGPoint(x: 77,y: 71)); nose.addQuadCurve(to: CGPoint(x: 77,y: 80),control: CGPoint(x: 82,y: 78)); nose.closeSubpath(); shape(nose,Color(hex: 0xB7768B),stroke: false)
            var mouth = Path(); mouth.move(to: CGPoint(x: 65,y: 82)); mouth.addQuadCurve(to: CGPoint(x: 77,y: 80),control: CGPoint(x: 72,y: 91)); mouth.addQuadCurve(to: CGPoint(x: 89,y: 82),control: CGPoint(x: 82,y: 91)); c.stroke(mouth,with: .color(ink),style: StrokeStyle(lineWidth: 2,lineCap: .round))
            line([CGPoint(x: 20,y: 70),CGPoint(x: 41,y: 74)],tint: ink.opacity(0.55)); line([CGPoint(x: 19,y: 82),CGPoint(x: 39,y: 80)],tint: ink.opacity(0.55))
            line([CGPoint(x: 115,y: 74),CGPoint(x: 138,y: 69)],tint: ink.opacity(0.55)); line([CGPoint(x: 116,y: 80),CGPoint(x: 139,y: 83)],tint: ink.opacity(0.55))
            line([CGPoint(x: 68,y: 30),CGPoint(x: 70,y: 40)],width: 4,tint: ink.opacity(0.2)); line([CGPoint(x: 81,y: 29),CGPoint(x: 81,y: 39)],width: 4,tint: ink.opacity(0.2))
            if hat == 1 {
                oval(95,27,17,12,CatTheme.rose); oval(112,27,17,12,CatTheme.rose); oval(108,29,8,8,Color(hex: 0xE6B9CB))
            } else if hat == 2 {
                oval(48,12,67,18,CatTheme.sage); line([CGPoint(x: 82,y: 11),CGPoint(x: 85,y: 6)],width: 4,tint: CatTheme.sage)
            } else if hat == 3 {
                var crown = Path(); crown.move(to: CGPoint(x: 57,y: 26)); crown.addLine(to: CGPoint(x: 53,y: 6)); crown.addLine(to: CGPoint(x: 69,y: 15)); crown.addLine(to: CGPoint(x: 80,y: 1)); crown.addLine(to: CGPoint(x: 90,y: 15)); crown.addLine(to: CGPoint(x: 105,y: 6)); crown.addLine(to: CGPoint(x: 101,y: 26)); crown.closeSubpath(); shape(crown,Color(hex: 0xEDCC7E)); oval(77,17,5,5,CatTheme.rose,stroke: false)
            }
        }.accessibilityLabel(sleeping ? "Спящий котик" : "Котик с мягкими лапками")
    }
}
