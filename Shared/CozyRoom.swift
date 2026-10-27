import SwiftUI

struct CozyRoom: View {
    let pet: Pet
    var time: Date = .now
    var animated = false
    var onPet: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var seconds: Double { time.timeIntervalSince1970 }
    private var night: Bool { pet.room == 1 }
    private var walking: Bool { animated && !reduceMotion && !pet.sleeping && pet.focusEnd == nil }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoomArtwork(scene: pet.room)
                Ellipse().fill(.black.opacity(0.08)).frame(width: geometry.size.width * 0.18, height: 12)
                    .position(x: catX(geometry.size.width), y: geometry.size.height * 0.76)
                PixelCat(sleeping: pet.sleeping, frame: walking ? Int(seconds * 3) % 2 : 0,
                         color: CatTheme.coats[pet.coat], hat: pet.hat,
                         happy: time.timeIntervalSince(pet.actionDate) < 4)
                    .frame(width: geometry.size.width * 0.25, height: geometry.size.height * 0.32)
                    .scaleEffect(x: walking && cos(seconds / 8) < 0 ? -1 : 1, y: 1)
                    .rotationEffect(.degrees(walking ? sin(seconds * 5) * 2 : 0))
                    .position(x: catX(geometry.size.width), y: geometry.size.height * 0.61)
                    .onTapGesture { onPet?() }
                    .accessibilityAddTraits(onPet == nil ? [] : .isButton)
                    .accessibilityAction { onPet?() }
                if pet.sleeping {
                    Text("z Z").font(.system(.title3, design: .serif).italic()).foregroundStyle(night ? .white.opacity(0.7) : CatTheme.lavender)
                        .position(x: geometry.size.width * 0.59, y: geometry.size.height * 0.39)
                }
                if time.timeIntervalSince(pet.actionDate) < 3 && !pet.sleeping {
                    Image(systemName: pet.lastAction == .feed ? "fish.fill" : "heart.fill")
                        .foregroundStyle(CatTheme.rose).font(.title3)
                        .position(x: catX(geometry.size.width) + 12, y: geometry.size.height * 0.35)
                }
            }.clipped()
        }
        .accessibilityElement(children: .contain)
    }

    private func catX(_ width: CGFloat) -> CGFloat {
        width * (walking ? 0.5 + sin(seconds / 8) * 0.19 : 0.5)
    }
}

struct RoomArtwork: View {
    var scene: Int

    var body: some View {
        Canvas { context, size in
            let sx = size.width / 390, sy = size.height / 280
            context.scaleBy(x: sx, y: sy)
            let night = scene == 1, garden = scene == 2
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                context.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
            }
            func round(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ color: Color) {
                context.fill(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r), with: .color(color))
            }
            func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
            }
            let wall = Color(hex: night ? 0x373A54 : garden ? 0xD8E4D2 : 0xF1DDD2)
            let wood = Color(hex: night ? 0x6D5E77 : 0xC6A58C)
            rect(0, 0, 390, 280, wall)
            // Sunlit arched window with a painted view.
            round(134, 20, 124, 136, 52, wood)
            round(141, 27, 110, 120, 46, Color(hex: night ? 0x262E4E : 0xFFF0CD))
            oval(207, 47, 23, 23, Color(hex: night ? 0xFFE6AC : 0xEAC983))
            if night {
                oval(215, 43, 23, 23, Color(hex: 0x262E4E))
                for point in [CGPoint(x: 160,y: 60), CGPoint(x: 221,y: 100), CGPoint(x: 182,y: 40)] {
                    rect(point.x, point.y, 2, 2, .white.opacity(0.7))
                }
            } else {
                oval(151, 78, 42, 7, .white.opacity(0.7)); oval(204, 105, 33, 6, .white.opacity(0.6))
            }
            round(142, 125, 108, 22, 8, Color(hex: night ? 0x4C5D73 : 0xBCC4A2))
            rect(192, 27, 6, 121, wood); rect(141, 98, 110, 5, wood)
            round(124, 148, 144, 8, 3, wood)
            rect(119, 18, 12, 138, Color(hex: night ? 0x89718A : 0xE4C0B7))
            rect(261, 18, 12, 138, Color(hex: night ? 0x89718A : 0xE4C0B7))
            rect(123, 21, 2, 130, .white.opacity(0.2)); rect(264, 21, 2, 130, .white.opacity(0.2))
            rect(0, 174, 390, 106, Color(hex: night ? 0x695C70 : garden ? 0xBAC5A3 : 0xDEC2AA))
            rect(0, 172, 390, 5, wood)
            for y in stride(from: 200, through: 280, by: 28) {
                rect(0, CGFloat(y), 390, 1, wood.opacity(0.35))
            }
            oval(89, 190, 214, 58, Color(hex: night ? 0xA2849D : 0xF4DEBD))
            oval(99, 196, 194, 45, Color(hex: night ? 0xB199AD : 0xF9E9D0))
            context.stroke(Path(ellipseIn: CGRect(x: 108, y: 201, width: 175, height: 35)), with: .color(wood.opacity(0.35)), lineWidth: 1)
            // Bookshelf and little framed heart.
            round(26, 88, 77, 5, 2, wood)
            rect(34, 68, 9, 20, CatTheme.lavender); rect(45, 63, 8, 25, CatTheme.sage); rect(55, 72, 7, 16, Color(hex: 0xCDA17A))
            round(76, 74, 13, 14, 3, .white.opacity(0.8)); oval(76, 73, 13, 3, wood)
            round(44, 121, 33, 32, 2, wood); rect(48, 125, 25, 24, Color(hex: 0xFFF1D9))
            context.draw(Text("♡").font(.system(size: 18, design: .serif)).foregroundColor(CatTheme.rose), at: CGPoint(x: 61, y: 136))
            // Tall plant with layered leaves.
            rect(334, 114, 2, 62, Color(hex: 0x81916E))
            for i in 0..<5 {
                oval(i % 2 == 0 ? 322 : 336, CGFloat(112 + i * 10), 14, 24, Color(hex: i % 2 == 0 ? 0x8FA17A : 0xA9B58C))
            }
            round(322, 169, 28, 7, 2, Color(hex: 0xBB8B76)); round(325, 176, 22, 28, 3, Color(hex: 0xD6A58A))
            rect(329, 179, 3, 20, .white.opacity(0.2))
            // Cushion and a ball of yarn.
            oval(305, 221, 49, 9, .black.opacity(0.07)); round(302, 208, 52, 15, 8, CatTheme.lavender)
            round(307, 205, 42, 11, 5, Color(hex: 0xC8BBD4))
            oval(48, 209, 22, 22, CatTheme.rose.opacity(0.7))
            var yarn = Path(); yarn.move(to: CGPoint(x: 50,y: 214)); yarn.addLine(to: CGPoint(x: 69,y: 224)); yarn.addLine(to: CGPoint(x: 51,y: 228)); yarn.addLine(to: CGPoint(x: 66,y: 213))
            context.stroke(yarn, with: .color(.white.opacity(0.45)), lineWidth: 1.5)
            oval(273, 237, 26, 7, wood); oval(275, 236, 22, 4, Color(hex: 0xB3D5D7))
            if garden {
                for x in [20, 82, 311, 369] {
                    rect(CGFloat(x), 236, 2, 15, CatTheme.sage)
                    oval(CGFloat(x - 4), 232, 10, 7, Color(hex: 0xD399AF))
                    oval(CGFloat(x - 1), 234, 3, 3, .yellow)
                }
            }
        }.accessibilityHidden(true)
    }
}
