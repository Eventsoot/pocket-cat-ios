import SwiftUI

struct CozyMiniGames: View {
    @ObservedObject var model: CatModel
    @State private var selected = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Маленькі радощі").font(.system(.title2, design: .serif))
            Text("Три гри для затишного вечора. Нагороди — на прикраси котика.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            Picker("Мінігра", selection: $selected) {
                Text("Пам’ять").tag(0)
                Text("Мишка").tag(1)
                Text("Букет").tag(2)
            }.pickerStyle(.segmented)
            if selected == 0 { MemoryGarden(model: model) }
            else if selected == 1 { MouseHunt(model: model) }
            else { BouquetGame(model: model) }
        }.softCard()
    }
}

struct MemoryGarden: View {
    @ObservedObject var model: CatModel
    @State private var cards = Array(repeating: 0, count: 12)
    @State private var open: [Int] = []
    @State private var matched: Set<Int> = []
    @State private var turns = 0
    @State private var started = false
    @State private var message = "Знайди шість пар маленьких скарбів"
    @State private var session = UUID()
    private let symbols = ["heart.fill", "leaf.fill", "gift.fill", "fish.fill", "moon.fill", "pawprint.fill"]

    var body: some View {
        VStack(spacing: 14) {
            HStack { Text("Сад спогадів").font(.headline); Spacer(); Text("\(matched.count / 2)/6 · \(turns) ходів").font(.caption) }
            Text(message).font(.caption).foregroundStyle(CatTheme.rose).frame(minHeight: 32)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<12) { index in
                    Button { choose(index) } label: {
                        let revealed = open.contains(index) || matched.contains(index)
                        Image(systemName: revealed ? symbols[cards[index]] : "sparkle")
                            .font(.system(size: 24)).foregroundStyle(revealed ? CatTheme.rose : CatTheme.lavender)
                            .frame(maxWidth: .infinity).frame(height: 66)
                            .background(matched.contains(index) ? Color(hex: 0xE2EBD9) : revealed ? Color(hex: 0xF4DDE6) : Color(hex: 0xEEE7F0), in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain).disabled(!started || matched.contains(index) || open.contains(index) || open.count == 2)
                        .accessibilityLabel(open.contains(index) || matched.contains(index) ? "Відкрита картка \(cards[index] + 1)" : "Картка \(index + 1)")
                }
            }
            Button(started ? "Почати знову" : "Відкрити сад") {
                session = UUID(); cards = (Array(0..<6) + Array(0..<6)).shuffled(); open = []; matched = []; turns = 0; started = true
                message = "Перевертай по дві картки"
            }.buttonStyle(.borderedProminent).tint(CatTheme.rose)
        }
        .onDisappear { session = UUID() }
    }

    private func choose(_ index: Int) {
        guard started, open.count < 2, !open.contains(index), !matched.contains(index) else { return }
        open.append(index); model.feedback("sparkle")
        guard open.count == 2 else { return }
        turns += 1
        if cards[open[0]] == cards[open[1]] {
            matched.formUnion(open); open = []
            if matched.count == 12 {
                started = false
                let reward = max(12, 36 - turns)
                model.change { $0.completeGame(score: reward) }
                message = "Усі пари знайдено! +\(reward) зірок ♡"
            }
        } else {
            let current = session
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(850))
                guard session == current else { return }
                open = []
            }
        }
    }
}

struct MouseHunt: View {
    @ObservedObject var model: CatModel
    @Environment(\.scenePhase) private var phase
    @State private var end: Date?
    @State private var hole = 4
    @State private var nextMove = Date.distantPast
    @State private var score = 0
    @State private var misses = 0
    @State private var message = "Лови іграшкову мишку, поки вона не сховалася"
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Тихе полювання").font(.headline); Spacer()
                if let end { Text(end, style: .timer).monospacedDigit() }
                else { Text("25 секунд").font(.caption) }
            }
            Text(message).font(.caption).foregroundStyle(CatTheme.rose).frame(minHeight: 32)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(0..<9) { index in
                    Button {
                        guard end != nil else { return }
                        if index == hole { score += 1; move(); model.feedback("sparkle") }
                        else { misses += 1 }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20).fill(Color(hex: 0xE8E5D8))
                            Ellipse().fill(Color(hex: 0xD1B8AA)).frame(width: 56, height: 22).offset(y: 16)
                            if end != nil && hole == index { Text("🐭").font(.system(size: 35)).offset(y: -2) }
                        }.frame(height: 82)
                    }.buttonStyle(.plain).disabled(end == nil).accessibilityLabel("Хатинка мишки \(index + 1)")
                }
            }
            Text("Спіймано \(score) · промахів \(misses)").font(.caption).foregroundStyle(.secondary)
            Button("Почати полювання") { score = 0; misses = 0; end = Date().addingTimeInterval(25); move(); message = "Мишка прискорюється — стеж за хатинками!" }
                .buttonStyle(.borderedProminent).tint(CatTheme.sage).disabled(end != nil)
        }
        .onReceive(timer) { now in
            guard let finish = end else { return }
            if now >= finish {
                end = nil; let reward = min(40, max(0, score - misses / 3))
                model.change { $0.completeGame(score: reward) }; message = "Мишка задоволена! +\(reward) зірок"
            } else if now >= nextMove { move() }
        }
        .onChange(of: phase) { _, p in if p != .active { end = nil; message = "Полювання перервалося. Почнемо ще раз?" } }
        .onDisappear { end = nil }
    }
    private func move() {
        hole = (hole + Int.random(in: 1...8)) % 9
        nextMove = Date().addingTimeInterval(max(0.42, 1.15 - Double(score) * 0.025))
    }
}

struct BouquetGame: View {
    @ObservedObject var model: CatModel
    @State private var order = [0, 1, 2]
    @State private var bouquet: [Int] = []
    @State private var round = 0
    @State private var correct = 0
    @State private var playing = false
    @State private var showOrder = true
    @State private var message = "Запам’ятай букет і збери квіти в тому самому порядку"
    @State private var session = UUID()
    private let flowers = ["🌷", "🌼", "🌸", "🌹", "🪻", "🌻"]
    var body: some View {
        VStack(spacing: 16) {
            HStack { Text("Букет для тебе").font(.headline); Spacer(); Text("\(min(round, 5))/5").font(.caption) }
            Text(message).font(.caption).foregroundStyle(CatTheme.rose).frame(minHeight: 35)
            HStack(spacing: 9) {
                ForEach(0..<order.count, id: \.self) { index in
                    Text(showOrder ? flowers[order[index]] : bouquet.indices.contains(index) ? flowers[bouquet[index]] : "♡")
                        .font(.system(size: 29)).frame(maxWidth: .infinity).frame(height: 70)
                        .background(Color(hex: 0xF5E1E7), in: RoundedRectangle(cornerRadius: 17))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(0..<6) { index in
                    Button { pick(index) } label: {
                        Text(flowers[index]).font(.system(size: 33)).frame(maxWidth: .infinity).padding(12)
                            .background(Color(hex: 0xEFE9D9), in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain).disabled(!playing || showOrder || bouquet.count >= order.count)
                        .accessibilityLabel("Квітка \(index + 1)")
                }
            }
            Button(playing ? "Показати замовлення знову" : "Відкрити квіткову крамничку") {
                if !playing { round = 0; correct = 0; playing = true; nextOrder() }
                else { reveal() }
            }.buttonStyle(.borderedProminent).tint(CatTheme.rose).disabled(playing && showOrder)
        }.onDisappear { session = UUID(); playing = false }
    }
    private func reveal() {
        session = UUID(); let current = session; showOrder = true; bouquet = []
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard session == current && playing else { return }
            showOrder = false; message = "Які квіти були в замовленні?"
        }
    }
    private func nextOrder() {
        order = (0..<(round < 3 ? 3 : 4)).map { _ in Int.random(in: 0..<6) }
        message = "Запам’ятовуй замовлення ♡"; reveal()
    }
    private func pick(_ index: Int) {
        guard playing && !showOrder && bouquet.count < order.count else { return }
        bouquet.append(index); model.feedback("sparkle")
        if bouquet.count == order.count {
            if bouquet == order { correct += 1 }
            round += 1
            if round >= 5 {
                playing = false; showOrder = true
                let reward = correct * 6
                model.change { $0.completeGame(score: reward) }
                message = "Букети готові! Правильно \(correct)/5 · +\(reward) зірок"
            } else {
                message = bouquet == order ? "Ідеальний букет!" : "Милий букет! Спробуймо наступний"
                showOrder = true; session = UUID(); let current = session
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    guard session == current && playing else { return }; nextOrder()
                }
            }
        }
    }
}
