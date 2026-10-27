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
                        Text("ТВІЙ МАЛЕНЬКИЙ СУПУТНИК").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2)
                        Text("Привіт, Мурчику").font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: "pawprint.fill").font(.title2).foregroundStyle(.orange)
                }
                TimelineView(.animation(minimumInterval: 0.35, paused: scenePhase != .active)) { timeline in
                    let date = timeline.date
                    let tick = Int(date.timeIntervalSince1970 / 0.35)
                    VStack(spacing: 16) {
                        HStack {
                            Label("ВДОМА", systemImage: "sparkle").font(.caption.weight(.bold))
                            Spacer()
                            Text("усе добре").font(.caption)
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
                        Text("Торкнися котика, щоб погладити").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(24).frame(maxWidth: .infinity)
                    .background(Color(red: 0.17, green: 0.23, blue: 0.22), in: RoundedRectangle(cornerRadius: 30))
                }
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let current = pet.at(context.date)
                    HStack(spacing: 14) {
                        meter("Ситість", "fish.fill", current.food, .orange)
                        meter("Радість", "heart.fill", current.joy, .pink)
                        meter("Енергія", "moon.fill", current.energy, .indigo)
                    }
                }
                HStack(spacing: 12) {
                    careButton("Годувати", "fish.fill", .feed)
                    careButton("Грати", "tennisball.fill", .play)
                    careButton("Спати", "moon.stars.fill", .sleep)
                }
                #if !BASIC_BUILD
                VStack(alignment: .leading, spacing: 14) {
                    Label("Завжди поруч", systemImage: "platter.filled.top.iphone").font(.title3.bold())
                    Text("Посели Мурчика в Dynamic Island і на екрані блокування.").font(.subheadline).foregroundStyle(.secondary)
                    Button {
                        Task {
                            if active { await CatActivity.stop() }
                            else {
                                do { try CatActivity.start(pet) }
                                catch { self.error = CatLanguage.error(error) }
                            }
                            active = !Activity<CatAttributes>.activities.isEmpty
                        }
                    } label: {
                        Text(active ? "Прибрати з острівця" : "Поселити на острівці")
                            .font(.headline).frame(maxWidth: .infinity).padding(16)
                            .background(Color(red: 0.27, green: 0.37, blue: 0.29), in: Capsule()).foregroundStyle(.white)
                    }
                    Text("Затисни Dynamic Island, щоб нагодувати котика або пограти. На iPhone без острівця він з’явиться на екрані блокування.").font(.caption).foregroundStyle(.secondary)
                }.padding(22).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 24))
                VStack(alignment: .leading, spacing: 10) {
                    Text("Хатинка на початковому екрані").font(.headline)
                    Text("Затисни вільне місце на початковому екрані → додай віджет → знайди «Мурчик». Вибери малу або середню хатинку.").font(.subheadline).foregroundStyle(.secondary)
                    Text("iOS самостійно обирає час оновлення віджетів. Live Activity працює обмежений час; прогулянки й реакції оновлюються під час взаємодії та відкриття застосунку.").font(.caption).foregroundStyle(.secondary)
                }
                #else
                Text("Мурчик живе в цьому застосунку. Ця версія для безкоштовного встановлення не використовує віджети та Dynamic Island.")
                    .font(.caption).foregroundStyle(.secondary)
                #endif
            }.padding(24)
        }
        .background(cream.ignoresSafeArea()).foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.21))
        .alert("Не вдалося ввімкнути острівець", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Зрозуміло") { error = nil }
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
