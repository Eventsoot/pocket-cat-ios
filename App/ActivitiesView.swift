import SwiftUI

struct DailyCareView: View {
    @ObservedObject var model: CatModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Ритуалы нежности", systemImage: "sun.max.fill").font(.system(.headline, design: .rounded))
                Spacer()
                Text("НА СЕГОДНЯ").font(.system(size: 8, weight: .semibold)).tracking(1).foregroundStyle(.secondary)
            }
            mission("Вкусный день", "Покорми 3 раза", model.pet.todayMeals, 3, "fish.fill")
            mission("Пять маленьких объятий", "Погладь 5 раз", model.pet.todayStrokes, 5, "heart.fill")
            mission("Вместе веселее", "Заверши одну игру", model.pet.todayGames, 1, "sparkles")
            Button {
                var claimed = false
                model.change { claimed = $0.claimMission() }
                if claimed { model.message = "Все ритуалы выполнены! +40 звёзд ✦"; model.feedback("sparkle") }
            } label: {
                Text(model.pet.missionClaimed ? "Награда уже в копилке ♡" : "Забрать 40 звёзд ✦")
                    .font(.system(size: 11, weight: .semibold)).padding(13).frame(maxWidth: .infinity)
                    .background(Color(hex: 0xEEE3D1), in: Capsule())
            }.disabled(!model.pet.missionsDone || model.pet.missionClaimed)
            Divider()
            Button {
                var claimed = false
                model.change { claimed = $0.claimGift() }
                if claimed { model.message = "Подарок за встречу: +25 звёзд!"; model.feedback("sparkle") }
            } label: {
                HStack {
                    Image(systemName: "gift.fill").foregroundStyle(CatTheme.rose)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Подарок за встречу").font(.system(size: 12, weight: .semibold))
                        Text(Calendar.current.isDateInToday(model.pet.lastGift) ? "Завтра будет ещё один" : "+25 звёзд каждый новый день").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: Calendar.current.isDateInToday(model.pet.lastGift) ? "checkmark.circle.fill" : "arrow.up.right")
                }
            }.buttonStyle(.plain).disabled(Calendar.current.isDateInToday(model.pet.lastGift))
        }.softCard()
    }

    private func mission(_ title: String, _ detail: String, _ value: Int, _ goal: Int, _ symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: value >= goal ? "checkmark.circle.fill" : symbol).foregroundStyle(value >= goal ? CatTheme.sage : CatTheme.rose)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 11, weight: .medium))
                Text(detail).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(min(value, goal))/\(goal)").font(.system(size: 10, design: .rounded)).foregroundStyle(.secondary)
        }
    }
}

struct PlayRoomView: View {
    @ObservedObject var model: CatModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var end: Date?
    @State private var score = 0
    @State private var star = CGPoint(x: 0.5, y: 0.5)
    @State private var remaining = 20
    @State private var result = "20 секунд маленького счастья"
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            CatAdventureCard(model: model)
            CozyMiniGames(model: model)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Лови звёздочки").font(.system(.title2, design: .serif))
                        Text(result).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(end == nil ? "✦" : "\(remaining) сек").font(.system(.title3, design: .rounded)).foregroundStyle(CatTheme.rose)
                }
                ZStack {
                    RoomArtwork(scene: 1)
                    if end != nil {
                        GeometryReader { geometry in
                            Button {
                                score += 1
                                star = CGPoint(x: Double.random(in: 0.14...0.86), y: Double.random(in: 0.18...0.76))
                                model.feedback("sparkle")
                            } label: {
                                Image(systemName: "star.fill").font(.system(size: 33)).foregroundStyle(Color(hex: 0xFFE5A5))
                                    .padding(12).background(.white.opacity(0.12), in: Circle())
                            }.buttonStyle(.plain).position(x: geometry.size.width * star.x, y: geometry.size.height * star.y)
                                .accessibilityLabel("Поймать звёздочку")
                        }
                    } else {
                        PixelCat(color: CatTheme.coats[model.pet.coat], hat: model.pet.hat)
                            .frame(width: 110, height: 95).offset(y: 26)
                    }
                    VStack { Spacer(); Text("\(score) ✦").font(.system(.title3, design: .rounded).bold()).foregroundStyle(.white).padding(12) }
                }.frame(height: 255).clipShape(RoundedRectangle(cornerRadius: 22))
                Button {
                    guard end == nil else { return }
                    score = 0; remaining = 20; end = Date().addingTimeInterval(20)
                    result = "Нажимай на звёздочки!"; model.care(.play)
                } label: {
                    Text(end == nil ? "За звёздами!" : "Поймай как можно больше")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).padding(15).frame(maxWidth: .infinity)
                        .background(CatTheme.rose, in: Capsule())
                }.disabled(end != nil)
                Text("Каждая звёздочка = 1 монетка и 2 XP. Украшения покупаются только за игровые монетки.").font(.system(size: 10)).foregroundStyle(.secondary)
            }.softCard()
            focusCard
        }
        .onReceive(timer) { _ in
            guard let finish = end else { return }
            remaining = max(0, Int(ceil(finish.timeIntervalSinceNow)))
            if remaining == 0 { finishGame() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && end != nil { end = nil; result = "Игра приостановлена. Попробуем ещё раз?"; score = 0 }
        }
        .onDisappear { end = nil }
    }

    private func finishGame() {
        guard end != nil else { return }
        end = nil
        let earned = min(score, 40)
        model.change { $0.completeGame(score: score) }
        result = "Отлично! +\(earned) монеток и +\(earned * 2) XP"
        model.message = "Вы поймали \(score) звёздочек вместе ♡"
        model.feedback("sparkle")
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Тихая компания", systemImage: "moon.stars.fill").font(.system(.headline, design: .rounded))
            Text("Занимайся своими делами, пока котик составляет компанию. За завершённый таймер — монетки и XP.").font(.system(size: 11)).foregroundStyle(.secondary)
            if let end = model.pet.focusEnd {
                Text(end, style: .timer).font(.system(size: 42, weight: .light, design: .rounded)).monospacedDigit().foregroundStyle(CatTheme.rose)
                Button("Завершить без награды") { model.change { $0.focusEnd = nil } }.font(.caption).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 10) {
                    ForEach([5, 15, 25], id: \.self) { minutes in
                        Button {
                            model.change { $0.startFocus(minutes: minutes) }
                            model.feedback("sleep")
                            #if !BASIC_BUILD
                            if !model.activityRunning { model.toggleActivity() }
                            #endif
                        } label: {
                            Text("\(minutes) мин").font(.system(size: 12, weight: .medium)).padding(.vertical, 14).frame(maxWidth: .infinity)
                                .background(Color(hex: 0xEEE5F0), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
            Text("Таймер сохраняется после закрытия приложения. Награда начислится при следующем открытии.").font(.system(size: 9)).foregroundStyle(.secondary)
        }.softCard()
    }
}

struct CollectionView: View {
    @ObservedObject var model: CatModel
    private let titles = ["Первое мур", "Гурман", "Звездолов", "Звёздный дождь", "Три дня вместе", "Лучшая дружба", "Модный кот", "Тихий час"]
    private let details = ["Погладь котика", "Покорми 10 раз", "Заверши игру", "Поймай 20 звёзд", "Забери подарок 3 дня подряд", "Достигни уровня 5", "Собери 3 украшения", "Заверши таймер фокуса"]
    private let symbols = ["heart.fill", "fish.fill", "star.fill", "sparkles", "flame.fill", "pawprint.fill", "crown.fill", "moon.fill"]

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Шесть оттенков счастья").font(.system(.title2, design: .serif))
                HStack(spacing: 12) {
                    ForEach(0..<6) { index in
                        Button { model.change { $0.coat = index }; model.feedback("meow") } label: {
                            Circle().fill(CatTheme.coats[index]).frame(height: 36)
                                .overlay { if model.pet.coat == index { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) } }
                                .overlay(Circle().stroke(CatTheme.rose.opacity(model.pet.coat == index ? 0.8 : 0), lineWidth: 2).padding(-4))
                        }.buttonStyle(.plain).accessibilityLabel(["Рыжий", "Серый", "Тёмный", "Кремовый", "Розовый", "Шоколадный"][index])
                    }
                }
                CozyRoom(pet: model.pet).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 20))
                HStack {
                    ForEach(0..<3) { index in
                        Button { model.change { $0.room = index } } label: {
                            Text(["Солнце", "Луна", "Сад"][index]).font(.system(size: 10, weight: .medium)).padding(11).frame(maxWidth: .infinity)
                                .background(model.pet.room == index ? Color(hex: 0xEDDAE3) : Color(hex: 0xF2EDE5), in: Capsule())
                        }
                    }
                }
            }.softCard()
            wardrobe
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("Ваши маленькие победы").font(.system(.headline, design: .rounded)); Spacer(); Text("\(model.pet.achievements.filter { $0 }.count)/8").font(.caption).foregroundStyle(.secondary) }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<8) { index in
                        VStack(spacing: 9) {
                            Image(systemName: symbols[index]).font(.system(size: 23)).foregroundStyle(model.pet.achievements[index] ? CatTheme.rose : Color(hex: 0xCFC6C4))
                            Text(titles[index]).font(.system(size: 11, weight: .semibold))
                            Text(details[index]).font(.system(size: 9)).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(minHeight: 28)
                        }.padding(14).frame(maxWidth: .infinity).background(Color(hex: 0xF5EEE6), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }.softCard()
        }
    }

    private var wardrobe: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Кошачья гардеробная").font(.system(.title2, design: .serif))
            Text("Без платежей. Только звёздочки из ваших игр.").font(.system(size: 10)).foregroundStyle(.secondary)
            ForEach(0..<4) { index in
                Button {
                    var success = false
                    model.change { success = $0.wear(index) }
                    model.message = success ? "Новый образ, тот же мур ♡" : "Нужно ещё немного звёздочек из игры"
                    if success { model.feedback("sparkle") }
                } label: {
                    HStack {
                        PixelCat(color: CatTheme.coats[model.pet.coat], hat: index).frame(width: 47, height: 43)
                        Text(CatTheme.hatNames[index]).font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text(model.pet.hat == index ? "Надето ✓" : model.pet.ownedHats.contains(index) ? "Надеть" : "\([0, 30, 60, 100][index]) ✦")
                            .font(.system(size: 10)).foregroundStyle(CatTheme.rose)
                    }.padding(10).background(Color(hex: 0xF5EEE6), in: RoundedRectangle(cornerRadius: 17))
                }.buttonStyle(.plain)
            }
            Text(model.message).font(.system(size: 10)).foregroundStyle(CatTheme.rose)
        }.softCard()
    }
}
