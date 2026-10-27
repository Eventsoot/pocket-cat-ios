import SwiftUI

struct CatAdventureView: View {
    @ObservedObject var model: CatModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("cat-run-best") private var best = 0
    @State private var game = CatRun()
    @State private var lastTick = Date()
    @State private var rewarded = false
    private let clock = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()
    private let worlds = ["Сад желаний", "Лунные крыши", "Облачный берег"]

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark").padding(12).background(.white.opacity(0.8), in: Circle()) }
                    .accessibilityLabel("Выйти из игры")
                Spacer()
                Text("Кошачье путешествие").font(.system(.headline, design: .rounded))
                Spacer()
                Button {
                    if game.phase == .running { game.phase = .paused }
                    else if game.phase == .paused { lastTick = .now; game.phase = .running }
                } label: { Image(systemName: game.phase == .paused ? "play.fill" : "pause.fill").padding(12).background(.white.opacity(0.8), in: Circle()) }
                    .disabled(game.phase != .running && game.phase != .paused).accessibilityLabel("Пауза или продолжить")
            }
            HStack {
                Text(String(repeating: "♥", count: max(0, game.lives))).foregroundStyle(CatTheme.rose)
                Spacer()
                Label("\(game.score)", systemImage: "star.fill").foregroundStyle(Color(hex: 0xAC8039))
                Spacer()
                Text("Рекорд \(best)").font(.caption)
            }.font(.system(.headline, design: .rounded))
            VStack(spacing: 7) {
                Text("\(game.world + 1) / 3 · \(worlds[game.world])").font(.system(size: 13, weight: .semibold, design: .rounded))
                ProgressView(value: game.progress).tint(CatTheme.rose)
            }
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    landscape
                    ForEach(game.items) { item in
                        itemView(item)
                            .position(x: item.x, y: 350 - item.height)
                    }
                    PixelCat(sleeping: false, frame: Int(game.distance / 16) % 2,
                             color: CatTheme.coats[model.pet.coat], hat: model.pet.hat, happy: game.combo >= 3)
                        .frame(width: 65, height: 58)
                        .rotationEffect(.degrees(game.jumps == 2 ? -12 : 0))
                        .opacity(game.shield > 0 && Int(game.shield * 10) % 2 == 0 ? 0.4 : 1)
                        .position(x: 76, y: 324 - game.height)
                    if game.combo >= 3 {
                        Text("КОМБО ×\(game.combo)").font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(CatTheme.rose).position(x: 195, y: 80)
                    }
                    if game.phase != .running { overlay }
                }.frame(width: 390, height: 460)
                    .scaleEffect(geometry.size.width / 390, anchor: .topLeading)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped().contentShape(Rectangle())
                    .onTapGesture { jump() }
            }.aspectRatio(390.0 / 460, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            Button { jump() } label: {
                Label("Прыжок", systemImage: "arrow.up").font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity).padding(20).foregroundStyle(.white).background(CatTheme.rose, in: Capsule())
            }.disabled(game.phase != .running)
            Text("Касайся поля или кнопки. Два касания — двойной прыжок.\nПерепрыгивай ящики, избегай птиц, собирай звёзды и сердечки.")
                .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }.padding(20).background(CatTheme.paper.ignoresSafeArea()).foregroundStyle(CatTheme.ink)
            .onReceive(clock) { now in
                let elapsed = now.timeIntervalSince(lastTick); lastTick = now
                for sound in game.step(elapsed) { model.feedback(sound) }
                if (game.phase == .won || game.phase == .lost) && !rewarded {
                    rewarded = true; best = max(best, game.score)
                    if game.distance >= 150 {
                        model.change { $0.completeGame(score: min(40, game.stars + (game.phase == .won ? 20 : 0))) }
                    }
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active && game.phase == .running { game.phase = .paused }
                lastTick = .now
            }
    }

    private var landscape: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: game.world == 1 ? [Color(hex: 0x393C62), Color(hex: 0xA28CAD)] : [Color(hex: 0xC5E5E3), Color(hex: 0xFFF0D1)], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(hex: 0xFFF1BA)).frame(width: 62, height: 62).position(x: 310, y: 70)
            ForEach(0..<5) { i in
                let x = (Double(i) * 115 - game.distance * 0.16).truncatingRemainder(dividingBy: 575)
                Capsule().fill(.white.opacity(0.45)).frame(width: 80, height: 22)
                    .position(x: x < -80 ? x + 575 : x, y: 90 + Double(i % 3) * 43)
            }
            ForEach(0..<7) { i in
                let x = (Double(i) * 90 - game.distance * 0.4).truncatingRemainder(dividingBy: 630)
                Ellipse().fill((game.world == 1 ? CatTheme.lavender : CatTheme.sage).opacity(0.55))
                    .frame(width: 130, height: 120).position(x: x < -80 ? x + 630 : x, y: 320)
            }
            Rectangle().fill(Color(hex: game.world == 1 ? 0x77708F : 0xBED0AB)).frame(width: 390, height: 110).offset(y: 350)
            Rectangle().fill(Color(hex: 0xF5E3C3)).frame(width: 390, height: 6).offset(y: 350)
            ForEach(0..<12) { i in
                let x = (Double(i) * 40 - game.distance).truncatingRemainder(dividingBy: 480)
                Text(game.world == 2 ? "✧" : "✿").foregroundStyle(CatTheme.rose.opacity(0.6))
                    .position(x: x < -20 ? x + 480 : x, y: 390 + Double(i % 2) * 25)
            }
        }.frame(width: 390, height: 460)
    }

    @ViewBuilder private func itemView(_ item: CatRun.Item) -> some View {
        switch item.kind {
        case .star: Image(systemName: "star.fill").font(.system(size: 25)).foregroundStyle(Color(hex: 0xE8B75D)).shadow(color: .white.opacity(0.8), radius: 5)
        case .heart: Image(systemName: "heart.fill").font(.system(size: 25)).foregroundStyle(CatTheme.rose)
        case .bird: Image(systemName: "bird.fill").font(.system(size: 32)).foregroundStyle(Color(hex: 0x716181))
        case .crate:
            ZStack { RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xBA8D6C)); Image(systemName: "shippingbox").foregroundStyle(Color(hex: 0xF5DFC4)).font(.title2) }.frame(width: 36, height: 40)
        }
    }

    private var overlay: some View {
        VStack(spacing: 16) {
            Text(game.phase == .ready ? "За звёздами!" : game.phase == .paused ? "Передохнём?" : game.phase == .won ? "Вы дошли до моря!" : "Ещё одно приключение?")
                .font(.system(size: 25, weight: .semibold, design: .serif))
            Text(game.phase == .ready ? "Три мира, один храбрый котик.\nДвойной прыжок поможет добраться дальше." : game.phase == .paused ? "Котик подождёт тебя." : "\(game.score) очков · \(game.stars) звёзд\nРекорд сохраняется на этом iPhone.")
                .font(.system(size: 13)).multilineTextAlignment(.center)
            Button {
                if game.phase == .paused { game.phase = .running }
                else { game.start(); rewarded = false }
                lastTick = .now; model.feedback("meow")
            } label: {
                Text(game.phase == .paused ? "Продолжить" : game.phase == .ready ? "В путешествие" : "Играть снова")
                    .font(.system(size: 14, weight: .bold)).padding(16).foregroundStyle(.white).background(CatTheme.rose, in: Capsule())
            }.buttonStyle(.plain)
        }.padding(24).frame(width: 330).background(CatTheme.paper.opacity(0.97), in: RoundedRectangle(cornerRadius: 24))
            .position(x: 195, y: 225)
    }

    private func jump() {
        if game.jump() { model.feedback("jump") }
    }
}

struct CatAdventureCard: View {
    @ObservedObject var model: CatModel
    @State private var showing = false
    var body: some View {
        Button { showing = true } label: {
            HStack(spacing: 16) {
                PixelCat(color: CatTheme.coats[model.pet.coat], hat: model.pet.hat, happy: true).frame(width: 80, height: 75)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Кошачье путешествие").font(.system(.headline, design: .rounded))
                    Text("3 мира · двойной прыжок · звёзды · рекорды").font(.system(size: 11)).foregroundStyle(.secondary)
                    Label("Начать приключение", systemImage: "play.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(CatTheme.rose)
                }
                Spacer(minLength: 0)
            }.softCard()
        }.buttonStyle(.plain).fullScreenCover(isPresented: $showing) { CatAdventureView(model: model) }
            .task { if ProcessInfo.processInfo.arguments.contains("--preview-game") { showing = true } }
    }
}
