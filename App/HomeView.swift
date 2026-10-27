import SwiftUI
import ActivityKit

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var pet = PetStore.load()
    @State private var error: String?
    @State private var active = !Activity<CatAttributes>.activities.isEmpty
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.91)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ТВОЙ МАЛЕНЬКИЙ СПУТНИК").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
                        Text("Привет, Мурчик").font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: "pawprint.fill").font(.title2).foregroundStyle(.orange)
                }
                TimelineView(.animation(minimumInterval: 0.35, paused: scenePhase != .active)) { timeline in
                    let date = timeline.date
                    let tick = Int(date.timeIntervalSince1970 / 0.35)
                    VStack(spacing: 16) {
                        HStack {
                            Label("ДОМА", systemImage: "sparkle").font(.caption.weight(.bold))
                            Spacer()
                            Text("всё хорошо").font(.caption)
                        }.foregroundStyle(.white.opacity(0.7))
                        ZStack {
                            Ellipse().fill(.white.opacity(0.06)).frame(width: 220, height: 60).offset(y: 60)
                            Text(pet.isSleeping(at: date) ? "z Z" : "✦").foregroundStyle(.white.opacity(0.65)).offset(x: 70, y: -55)
                            PixelCat(sleeping: pet.isSleeping(at: date), frame: tick % 2)
                                .frame(width: 128, height: 112)
                                .scaleEffect(x: sin(date.timeIntervalSince1970 / 12) < 0 ? -1 : 1, y: 1)
                                .offset(x: pet.isSleeping(at: date) ? 0 : sin(date.timeIntervalSince1970 / 12) * 65)
                                .onTapGesture { care(.pet) }
                        }.frame(height: 190).accessibilityAddTraits(.isButton)
                        Text(pet.mood(at: date)).font(.system(.headline, design: .rounded)).foregroundStyle(.white)
                        Text("Нажми на котика, чтобы погладить").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(24).frame(maxWidth: .infinity)
                    .background(Color(red: 0.17, green: 0.23, blue: 0.22), in: RoundedRectangle(cornerRadius: 30))
                }
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let current = pet.at(context.date)
                    HStack(spacing: 14) {
                        meter("Сытость", "fish.fill", current.food, .orange)
                        meter("Радость", "heart.fill", current.joy, .pink)
                        meter("Энергия", "moon.fill", current.energy, .indigo)
                    }
                }
                HStack(spacing: 12) {
                    careButton("Кормить", "fish.fill", .feed)
                    careButton("Играть", "tennisball.fill", .play)
                    careButton("Спать", "moon.stars.fill", .sleep)
                }
                #if !BASIC_BUILD
                VStack(alignment: .leading, spacing: 14) {
                    Label("Всегда рядом", systemImage: "platter.filled.top.iphone").font(.title3.bold())
                    Text("Посели Мурчика в Dynamic Island и на экране блокировки.").font(.subheadline).foregroundStyle(.secondary)
                    Button {
                        Task {
                            if active { await CatActivity.stop() }
                            else {
                                do { try CatActivity.start(pet) }
                                catch { self.error = error.localizedDescription }
                            }
                            active = !Activity<CatAttributes>.activities.isEmpty
                        }
                    } label: {
                        Text(active ? "Убрать с островка" : "Поселить на островке")
                            .font(.headline).frame(maxWidth: .infinity).padding(16)
                            .background(Color(red: 0.27, green: 0.37, blue: 0.29), in: Capsule()).foregroundStyle(.white)
                    }
                    Text("Зажми Dynamic Island, чтобы покормить котика или поиграть. На iPhone без островка он появится на экране блокировки.").font(.caption).foregroundStyle(.secondary)
                }.padding(22).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 24))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Домик на главном экране").font(.headline)
                    Text("Зажми свободное место на экране «Домой» → добавь виджет → найди «Мурчик». Выбери маленький или средний домик.").font(.subheadline).foregroundStyle(.secondary)
                    Text("iOS сама выбирает время обновления виджетов. Live Activity работает ограниченное время; прогулки и реакции обновляются при взаимодействии и открытии приложения.").font(.caption).foregroundStyle(.secondary)
                }
                #else
                Text("Мурчик живёт в этом приложении. Эта версия для бесплатной установки не использует виджеты и Dynamic Island.")
                    .font(.caption).foregroundStyle(.secondary)
                #endif
            }.padding(24)
        }
        .background(cream.ignoresSafeArea()).foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.21))
        .alert("Не удалось включить островок", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Понятно") { error = nil }
        } message: { Text(error ?? "") }
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
    }

    private func refresh() async {
        pet = PetStore.load().at(Date())
        PetStore.save(pet)
        active = !Activity<CatAttributes>.activities.isEmpty
        await CatActivity.sync(pet)
    }

    private func care(_ action: CatAction) {
        Task { pet = await PetStore.act(action) }
    }

    private func meter(_ title: String, _ icon: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text("\(Int(value))%").font(.system(.title3, design: .rounded).bold())
            ProgressView(value: value, total: 100).tint(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.padding(12).frame(maxWidth: .infinity).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
    }

    private func careButton(_ title: String, _ symbol: String, _ action: CatAction) -> some View {
        Button { care(action) } label: {
            VStack(spacing: 9) {
                Image(systemName: symbol).font(.title2)
                Text(title).font(.caption.bold())
            }.frame(maxWidth: .infinity).padding(.vertical, 19)
                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}
