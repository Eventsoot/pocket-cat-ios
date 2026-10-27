import SwiftUI

struct CozyHomeView: View {
    @StateObject private var model = CatModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var settings = false
    @State private var name = ""
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        let argument = ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--preview-tab=") }
        let value = argument.flatMap { Int($0.replacingOccurrences(of: "--preview-tab=", with: "")) } ?? 0
        _tab = State(initialValue: min(2, max(0, value)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                introduction
                navigation
                if tab == 0 { home }
                else if tab == 1 { PlayRoomView(model: model) }
                else { CollectionView(model: model) }
                Text("Маленький котик. Велика любов.").font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(CatTheme.ink.opacity(0.4)).frame(maxWidth: .infinity).padding(.vertical, 12)
            }.padding(.horizontal, 22).padding(.top, 16)
        }
        .background(CatTheme.paper.ignoresSafeArea()).foregroundStyle(CatTheme.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 8) }
        .preferredColorScheme(.light)
        .sheet(isPresented: $settings) { settingsSheet }
        .task { model.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() } else { model.silence() }
        }
        .onReceive(clock) { _ in if scenePhase == .active { model.tick() } }
        .environment(\.locale, CatLanguage.locale)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Text("m.").font(.system(size: 24, weight: .bold, design: .serif).italic())
                    .foregroundStyle(.white).frame(width: 35, height: 35).background(CatTheme.rose, in: RoundedRectangle(cornerRadius: 12))
                Text("мур-мур").font(.system(.title3, design: .rounded).bold())
            }
            Spacer()
            Label("\(model.pet.coins)", systemImage: "sparkle").font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(Color(hex: 0xAB8558)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(hex: 0xF1E5CC), in: Capsule())
            Button { name = model.pet.name; settings = true } label: {
                Image(systemName: "slider.horizontal.3").frame(width: 36, height: 36).background(.white.opacity(0.7), in: Circle())
            }.accessibilityLabel("Ім’я, звук і налаштування")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("ТВІЙ МАЛЕНЬКИЙ СУПУТНИК").font(.system(size: 9, weight: .semibold)).tracking(2).foregroundStyle(CatTheme.rose)
            Text("Дім там,\nде муркочуть.").font(.system(size: 37, weight: .medium, design: .serif)).tracking(-1)
            HStack {
                Text("\(model.pet.name) радий, що ти тут.").font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Label("\(model.pet.streak) дн.", systemImage: "flame.fill").font(.caption).foregroundStyle(CatTheme.rose)
            }
        }.padding(.top, 8)
    }

    private var navigation: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Button { withAnimation(.easeInOut(duration: 0.2)) { tab = index } } label: {
                    Label(["Хатинка", "Пригоди", "Колекція"][index], systemImage: ["house.fill", "sparkles", "gift.fill"][index])
                        .font(.system(size: 10, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(tab == index ? Color.white : Color.clear, in: Capsule())
                        .foregroundStyle(tab == index ? CatTheme.rose : CatTheme.ink.opacity(0.5))
                }.buttonStyle(.plain)
            }
        }.padding(4).background(Color(hex: 0xECE4DE), in: Capsule())
    }

    private var home: some View {
        VStack(spacing: 18) {
            roomCard
            FloatingCatCard(model: model)
            TransparentCatCard(model: model)
            HStack(spacing: 10) {
                need("Ситість", "fish.fill", model.pet.food, Color(hex: 0xCEA273))
                need("Радість", "heart.fill", model.pet.joy, CatTheme.rose)
                need("Сон", "moon.fill", model.pet.energy, CatTheme.lavender)
                need("Вода", "drop.fill", model.pet.water, Color(hex: 0x8FB5BE))
            }
            careButtons
            levelCard
            DailyCareView(model: model)
            #if !BASIC_BUILD
            widgetCard
            #endif
        }
    }

    private var roomCard: some View {
        VStack(spacing: 0) {
            HStack {
                Circle().fill(CatTheme.sage).frame(width: 5, height: 5)
                Text(CatTheme.roomNames[model.pet.room]).font(.system(size: 10, weight: .medium))
                Spacer()
                Button { model.change { $0.room = ($0.room + 1) % 3 }; model.feedback("sparkle") } label: {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.caption)
                }.accessibilityLabel("Змінити кімнату")
            }.padding(16).background(Color(hex: 0xF4E8E0))
            InteractiveCatRoom(model: model).frame(height: 320)
            VStack(spacing: 7) {
                Text(model.pet.mood(at: .now)).font(.system(size: 12, weight: .semibold, design: .rounded))
                Text(model.message).font(.system(size: 10)).foregroundStyle(CatTheme.rose).multilineTextAlignment(.center).frame(minHeight: 25)
            }.padding(16).frame(maxWidth: .infinity).background(Color(hex: 0xFFF9F0))
        }.clipShape(RoundedRectangle(cornerRadius: 27))
            .overlay(RoundedRectangle(cornerRadius: 27).stroke(Color(hex: 0xDFCFC5), lineWidth: 1))
    }

    private func need(_ title: String, _ symbol: String, _ value: Double, _ tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 15)).foregroundStyle(tint)
            Text("\(Int(value))%").font(.system(size: 13, weight: .bold, design: .rounded)).monospacedDigit()
            ProgressView(value: value, total: 100).tint(tint)
            Text(title).font(.system(size: 8)).foregroundStyle(.secondary)
        }.padding(.vertical, 15).padding(.horizontal, 9).frame(maxWidth: .infinity)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 19))
    }

    private var careButtons: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            careButton(model.pet.sleeping ? "Розбудити" : "Спати", "moon.stars.fill", .sleep, 0xE6DFF0)
            careButton("Водичка", "drop.fill", .drink, 0xDDECF0)
            careButton("Причесати", "comb.fill", .brush, 0xE3E8D7)
            Button { tab = 1; model.feedback("meow") } label: { actionLabel("Грати", "sparkles", 0xF3E9C8) }.buttonStyle(.plain)
        }
    }

    private func actionLabel(_ title: String, _ symbol: String, _ hex: UInt32) -> some View {
        VStack(spacing: 9) {
            Image(systemName: symbol).font(.system(size: 19)).frame(width: 38, height: 36)
                .background(Color(hex: hex), in: RoundedRectangle(cornerRadius: 13))
            Text(title).font(.system(size: 10, weight: .medium))
        }.padding(.vertical, 14).frame(maxWidth: .infinity).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 19))
    }

    private func careButton(_ title: String, _ symbol: String, _ action: CatAction, _ hex: UInt32) -> some View {
        Button { model.care(action) } label: { actionLabel(title, symbol, hex) }.buttonStyle(.plain)
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pawprint.fill").foregroundStyle(CatTheme.rose)
                Text("Рівень \(model.pet.level)").font(.system(.subheadline, design: .rounded).bold())
                Spacer()
                Text("\(model.pet.xp % 100) / 100 XP").font(.caption2).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(model.pet.xp % 100), total: 100).tint(CatTheme.rose)
            Text("Турбота й пригоди зміцнюють вашу дружбу.").font(.system(size: 10)).foregroundStyle(.secondary)
        }.softCard()
    }

    private var widgetCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Котик завжди поруч", systemImage: "iphone").font(.system(.headline, design: .rounded))
            Text("На iPhone 13 Pro Max котик живе у віджетах і на екрані блокування.").font(.system(size: 12)).foregroundStyle(.secondary)
            Button { model.toggleActivity() } label: {
                Text(model.activityRunning ? "Прибрати з екрана блокування" : "На екран блокування ♡")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).padding(15).frame(maxWidth: .infinity).background(CatTheme.rose, in: Capsule())
            }
            Text("Додати віджет: затисни початковий екран → Змінити → Додати віджет → Мурчик.").font(.system(size: 11)).foregroundStyle(.secondary)
            if !PetStore.sharingAvailable {
                Label("Підпис не надав доступу до спільних даних. Віджет може показувати окремого котика; Live Activity отримує дані із застосунку.", systemImage: "info.circle")
                    .font(.system(size: 10)).foregroundStyle(CatTheme.rose)
            }
            Text("iOS керує оновленням віджетів. Безперервна прогулянка та звуки доступні у відкритому застосунку.").font(.system(size: 9)).foregroundStyle(.secondary)
        }.softCard()
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Знайомся, твій котик") { TextField("Ім’я котика", text: $name).onChange(of: name) { _, value in name = String(value.prefix(24)) } }
                Section("Маленькі радощі") {
                    Toggle("Звуки та муркотіння", isOn: Binding(get: { model.pet.soundEnabled }, set: { value in model.change { $0.soundEnabled = value }; if value { model.feedback("meow") } else { model.silence() } }))
                    Toggle("М’яка вібрація", isOn: Binding(get: { model.pet.hapticsEnabled }, set: { value in model.change { $0.hapticsEnabled = value } }))
                    Button("Послухати няв") { model.feedback("meow") }
                }
                Section { Text("Дані зберігаються на пристрої. Щоб зберегти котика, встановлюй оновлення поверх попередньої версії. Звуки й вібрацію можна вимкнути вище.").font(.caption).foregroundStyle(.secondary) }
            }.navigationTitle("Твій маленький друг").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") {
                    let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !clean.isEmpty { model.change { $0.name = clean } }
                    settings = false
                } } }
        }.tint(CatTheme.rose)
    }
}
