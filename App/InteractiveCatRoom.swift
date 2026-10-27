import SwiftUI

/// Gestures stay on the cat and food, leaving the surrounding page scrollable.
struct InteractiveCatRoom: View {
    @ObservedObject var model: CatModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var foodOffset = CGSize.zero
    @State private var draggingFood = false
    @State private var strokePoint: CGPoint?
    @State private var strokeDistance: CGFloat = 0
    @State private var lastReward = Date.distantPast
    @State private var reactionUntil = Date.distantPast
    @State private var reaction = "♡"
    @State private var fishing = false

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.12)) { timeline in
                let size = geometry.size
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.49)
                let foodOrigin = CGPoint(x: size.width * 0.5, y: size.height - 40)
                let foodPosition = CGPoint(x: foodOrigin.x + foodOffset.width, y: foodOrigin.y + foodOffset.height)
                let nearMouth = hypot(foodPosition.x - center.x, foodPosition.y - center.y) < 64
                let reacting = timeline.date < reactionUntil
                let seconds = timeline.date.timeIntervalSince1970
                ZStack {
                    RoomArtwork(scene: model.pet.room)
                    Ellipse().fill(.black.opacity(0.08)).frame(width: 100, height: 13)
                        .position(x: center.x, y: center.y + 53)
                    if draggingFood {
                        Circle().strokeBorder(CatTheme.rose.opacity(nearMouth ? 0.9 : 0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .frame(width: 128, height: 128).position(center).allowsHitTesting(false)
                    }
                    PixelCat(sleeping: model.pet.sleeping, frame: reacting ? Int(timeline.date.timeIntervalSince1970 * 4) % 2 : 0,
                             color: CatTheme.coats[model.pet.coat], hat: model.pet.hat, happy: reacting || nearMouth && draggingFood,
                             blinking: seconds.truncatingRemainder(dividingBy: 5) < 0.24)
                        .frame(width: 146, height: 132)
                        .scaleEffect(reacting && !reduceMotion ? 1.04 : 1)
                        .rotationEffect(.degrees(reacting && !reduceMotion ? sin(seconds * 8) * 3 : 0))
                        .offset(y: reduceMotion ? 0 : sin(seconds * (model.pet.sleeping ? 2 : 1.5)) * 2)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 4).onChanged { value in
                            if let previous = strokePoint {
                                strokeDistance += min(30, hypot(value.location.x - previous.x, value.location.y - previous.y))
                            }
                            strokePoint = value.location
                            if strokeDistance >= 65 && Date().timeIntervalSince(lastReward) >= 1.5 {
                                strokeDistance = 0; lastReward = .now
                                model.care(.pet); respond("♡ ♡ ♡")
                            }
                        }.onEnded { _ in strokePoint = nil; strokeDistance = 0 })
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(model.pet.name). Проведи пальцем по котику, щоб погладити")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction(named: Text("Погладити")) { model.care(.pet); respond("♡ ♡ ♡") }
                        .position(center)
                    if reacting {
                        Text(reaction).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(CatTheme.rose)
                            .position(x: center.x, y: center.y - 84).allowsHitTesting(false)
                    } else if model.pet.sleeping {
                        Text("z Z").font(.title3).foregroundStyle(CatTheme.lavender)
                            .position(x: center.x + 65, y: center.y - 50).allowsHitTesting(false)
                    }
                    Text(draggingFood ? (nearMouth ? "Відпусти — хрум-хрум!" : "Піднеси рибку до котика") : "Погладь котика пальцем · пригости рибкою ↓")
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(CatTheme.ink)
                        .padding(.horizontal, 12).padding(.vertical, 7).background(.regularMaterial, in: Capsule())
                        .position(x: center.x, y: 24).allowsHitTesting(false)
                    Image(systemName: "fish.fill").font(.system(size: 29)).foregroundStyle(Color(hex: 0xBE805B))
                        .frame(width: 66, height: 54).background(Color(hex: 0xFFF6E8), in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(CatTheme.rose.opacity(0.3)))
                        .scaleEffect(draggingFood ? 1.12 : 1)
                        .gesture(DragGesture(minimumDistance: 3).onChanged { value in
                            draggingFood = true; foodOffset = value.translation
                        }.onEnded { value in
                            let landing = CGPoint(x: foodOrigin.x + value.translation.width, y: foodOrigin.y + value.translation.height)
                            if hypot(landing.x - center.x, landing.y - center.y) < 64 {
                                if model.care(.feed) { respond("Хрум! ♡") } else { fishing = true }
                            }
                            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                                foodOffset = .zero; draggingFood = false
                            }
                        })
                        .accessibilityLabel("Рибка. Перетягни до котика, щоб нагодувати")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { if model.care(.feed) { respond("Хрум! ♡") } else { fishing = true } }
                        .position(foodPosition)
                    Text("×\(model.pet.fish)").font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(CatTheme.ink).position(x: foodOrigin.x + 47, y: foodOrigin.y + 5).allowsHitTesting(false)
                    Button { fishing = true } label: {
                        Label("До річки", systemImage: "water.waves").font(.system(size: 10, weight: .semibold))
                            .padding(10).background(.regularMaterial, in: Capsule())
                    }.position(x: size.width - 52, y: size.height - 40)
                }.clipped()
            }
        }
        .onDisappear { foodOffset = .zero; draggingFood = false; strokePoint = nil; strokeDistance = 0 }
        .fullScreenCover(isPresented: $fishing) { FishingView(model: model) }
    }

    private func respond(_ text: String) {
        reaction = text; reactionUntil = Date().addingTimeInterval(2)
    }
}
