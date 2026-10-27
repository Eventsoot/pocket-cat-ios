import SwiftUI

struct FishingView: View {
    @ObservedObject var model: CatModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var round = FishingRound()
    @State private var lastTick = Date()
    @State private var castX = 0.62
    private let clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    private let names = ["Карась", "Окунь", "Форель", "Золота рибка"]
    private let colors: [Color] = [Color(hex: 0xC4A47C), Color(hex: 0x8DA68C), Color(hex: 0xC78FAD), Color(hex: 0xE5B64E)]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.down").padding(12).background(.white, in: Circle()) }.accessibilityLabel("Повернутися до котика")
                    Spacer()
                    Label("\(model.pet.fish) у запасі", systemImage: "fish.fill").font(.system(.subheadline, design: .rounded).bold())
                }
                VStack(spacing: 7) {
                    Text("Тиха річка").font(.system(size: 34, weight: .medium, design: .serif))
                    Text("Спіймай обід для свого маленького друга.").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                river.frame(height: 310).clipShape(RoundedRectangle(cornerRadius: 28))
                Text(instruction).font(.system(size: 15, weight: .semibold, design: .rounded)).multilineTextAlignment(.center).frame(minHeight: 42)
                if round.phase == .reeling { reelControls }
                Button { action() } label: {
                    Label(buttonTitle, systemImage: round.phase == .waiting ? "clock" : "fish.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(20).frame(maxWidth: .infinity).foregroundStyle(.white)
                        .background(round.phase == .bite ? Color(hex: 0x7A9D8C) : CatTheme.rose, in: Capsule())
                }
                Text("1. Закинь вудку й дочекайся сплеску.\n2. Натисни «Підсікти», поки клює.\n3. Тягни, коли бігунок у зеленій зоні — три вдалі рази.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                journal
                Text("Спійманою рибкою можна нагодувати котика в хатинці. Один улов — одне годування.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding(22)
        }.background(CatTheme.paper.ignoresSafeArea()).foregroundStyle(CatTheme.ink)
            .onReceive(clock) { now in
                let delta = now.timeIntervalSince(lastTick); lastTick = now
                guard scenePhase == .active else { return }
                let previous = round.phase
                round.step(delta)
                announceChange(from: previous)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { round = FishingRound() }
                lastTick = .now
            }
    }

    private var instruction: String {
        switch round.phase {
        case .idle: return "Котик чекає на рибку. Закинемо вудку?"
        case .waiting: return "Тс-с… чекаємо на клювання. Не тягни завчасно."
        case .bite: return "Клює! Підсікай зараз!"
        case .reeling: return "Не поспішай: лови зелену зону!"
        case .caught: return "\(names[round.species]) у кошику! +1 рибка для котика"
        case .escaped: return "Рибка втекла. Спробуємо ще раз?"
        }
    }
    private var buttonTitle: String {
        switch round.phase {
        case .idle: return "Закинути вудку"
        case .waiting: return "Витягнути завчасно"
        case .bite: return "Підсікти!"
        case .reeling: return "Тягнути! · \(round.pulls)/3"
        case .caught: return "Спіймати ще"
        case .escaped: return "Закинути знову"
        }
    }

    private var reelControls: some View {
        VStack(spacing: 12) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xEADFD6))
                    Rectangle().fill(CatTheme.sage).frame(width: g.size.width * 0.36).offset(x: g.size.width * 0.32)
                    Capsule().fill(CatTheme.ink).frame(width: 7, height: 31).offset(x: (g.size.width - 7) * round.marker)
                }.clipShape(Capsule())
            }.frame(height: 28).accessibilityLabel("Бігунок \(round.inZone ? "у зеленій зоні" : "поза зеленою зоною")")
            HStack { Text("Натяг волосіні"); Spacer(); Text("\(Int(round.tension))%") }.font(.system(size: 10))
            ProgressView(value: round.tension, total: 100).tint(round.tension > 70 ? CatTheme.rose : CatTheme.sage)
        }
    }

    private var river: some View {
        GeometryReader { g in
            let waterY = g.size.height * 0.44
            let bob = CGPoint(x: g.size.width * castX, y: g.size.height * 0.67)
            ZStack {
                LinearGradient(colors: [Color(hex: 0xD7E8D5), Color(hex: 0xFAEBCF)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xFFE6AC)).frame(width: 44, height: 44).position(x: g.size.width * 0.8, y: 42)
                ForEach(0..<5) { index in
                    Ellipse().fill(CatTheme.sage.opacity(0.45)).frame(width: 150, height: 100)
                        .position(x: CGFloat(index) * 90, y: waterY - 8)
                }
                Rectangle().fill(LinearGradient(colors: [Color(hex: 0x9BC7C9), Color(hex: 0x5D939F)], startPoint: .top, endPoint: .bottom))
                    .frame(height: g.size.height - waterY).position(x: g.size.width / 2, y: (g.size.height + waterY) / 2)
                Canvas { context, size in
                    let time = Date().timeIntervalSince1970
                    for row in 0..<7 {
                        var wave = Path()
                        for x in stride(from: 0.0, through: Double(size.width), by: 5) {
                            let y = Double(waterY) + 18 + Double(row) * 24 + sin(x / 27 + time + Double(row)) * 3
                            if x == 0 { wave.move(to: CGPoint(x: x, y: y)) } else { wave.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        context.stroke(wave, with: .color(.white.opacity(0.23)), lineWidth: 1.5)
                    }
                }.allowsHitTesting(false)
                RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xB58E70)).frame(width: 120, height: 20)
                    .position(x: 52, y: waterY + 27)
                PixelCat(frame: Int(Date().timeIntervalSince1970 * 2) % 2, color: CatTheme.coats[model.pet.coat], hat: model.pet.hat, happy: round.phase == .caught)
                    .frame(width: 80, height: 75).position(x: 57, y: waterY - 17)
                if round.phase != .idle && round.phase != .caught && round.phase != .escaped {
                    Path { p in
                        p.move(to: CGPoint(x: 77, y: waterY)); p.addLine(to: CGPoint(x: 117, y: waterY - 80))
                    }.stroke(Color(hex: 0x795D4C), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    Path { p in
                        p.move(to: CGPoint(x: 117, y: waterY - 80)); p.addQuadCurve(to: bob, control: CGPoint(x: bob.x - 10, y: waterY - 70))
                    }.stroke(.white.opacity(0.8), lineWidth: 1)
                    Ellipse().stroke(.white.opacity(0.7), lineWidth: 2).frame(width: round.phase == .bite ? 65 : 35, height: 13).position(bob)
                    Capsule().fill(round.phase == .bite ? CatTheme.rose : .white).frame(width: 9, height: round.phase == .bite ? 12 : 25)
                        .position(x: bob.x, y: bob.y - 5 + sin(Date().timeIntervalSince1970 * (round.phase == .bite ? 20 : 3)) * 3)
                    if round.phase == .bite { Text("!").font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(CatTheme.rose).position(x: bob.x, y: bob.y - 42) }
                }
                if round.phase == .caught {
                    Image(systemName: "fish.fill").font(.system(size: 62)).foregroundStyle(colors[round.species])
                        .rotationEffect(.degrees(-18)).shadow(color: .white.opacity(0.5), radius: 8).position(x: g.size.width * 0.6, y: waterY + 35)
                    Text("+1").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.white).position(x: g.size.width * 0.6, y: waterY + 93)
                }
                ForEach(0..<3) { i in
                    Image(systemName: "fish.fill").font(.system(size: 23)).foregroundStyle(Color(hex: 0x416F79).opacity(0.3))
                        .position(x: g.size.width * (0.3 + Double(i) * 0.25) + sin(Date().timeIntervalSince1970 + Double(i)) * 15, y: g.size.height * 0.86)
                }
            }.clipped()
        }
    }

    private var journal: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Твій рибальський альбом").font(.system(.headline, design: .rounded))
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    VStack(spacing: 8) {
                        Image(systemName: "fish.fill").font(.system(size: 25)).foregroundStyle(model.pet.fishCaught[index] > 0 ? colors[index] : Color.gray.opacity(0.3))
                        Text(names[index]).font(.system(size: 9)).multilineTextAlignment(.center).frame(height: 24)
                        Text("×\(model.pet.fishCaught[index])").font(.system(size: 11, weight: .bold, design: .rounded))
                    }.frame(maxWidth: .infinity)
                }
            }
        }.softCard()
    }

    private func action() {
        let previous = round.phase
        if round.phase == .idle || round.phase == .caught || round.phase == .escaped {
            let roll = Int.random(in: 0..<100)
            let species = roll < 48 ? 0 : roll < 78 ? 1 : roll < 95 ? 2 : 3
            castX = Double.random(in: 0.52...0.82)
            round.cast(wait: Double.random(in: 2...4.5), species: species)
            lastTick = .now; model.feedback("cast")
        } else {
            let success = round.hookOrPull()
            if round.phase == .reeling { model.feedback(success ? "reel" : "water") }
        }
        announceChange(from: previous)
    }

    private func announceChange(from previous: FishingRound.Phase) {
        guard previous != round.phase else { return }
        if round.phase == .bite { model.feedback("bite") }
        if let species = round.claimCatch() {
            model.change { $0.catchFish(species: species) }
            model.message = "Улов: \(names[species])! Котик чекає на частування."
            model.feedback(species == 3 ? "victory" : "sparkle")
        }
        if round.phase == .escaped { model.feedback("water") }
    }
}

struct FishingCard: View {
    @ObservedObject var model: CatModel
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "water.waves").font(.system(size: 35)).foregroundStyle(Color(hex: 0x72A7AE)).frame(width: 65)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Риболовля з котиком").font(.system(.headline, design: .rounded))
                    Text("Спіймай рибку біля річки й нагодуй друга").font(.system(size: 11)).foregroundStyle(.secondary)
                    Text("У запасі: \(model.pet.fish) · 4 види риб").font(.system(size: 11, weight: .semibold)).foregroundStyle(CatTheme.rose)
                }
                Spacer(minLength: 0)
            }.softCard()
        }.buttonStyle(.plain).fullScreenCover(isPresented: $showing) { FishingView(model: model) }
            .task { if ProcessInfo.processInfo.arguments.contains("--preview-fishing") { showing = true } }
    }
}
