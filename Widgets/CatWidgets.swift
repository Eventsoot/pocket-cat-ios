import SwiftUI
import WidgetKit
import AppIntents
import ActivityKit

@main
struct CatWidgets: WidgetBundle {
    var body: some Widget {
        CozyHomeWidget()
        CatNeedsWidget()
        CozyLiveActivity()
    }
}

struct CatEntry: TimelineEntry {
    var date: Date
    var pet: Pet
}

struct CatProvider: TimelineProvider {
    func placeholder(in context: Context) -> CatEntry { .init(date: .now, pet: Pet()) }
    func getSnapshot(in context: Context, completion: @escaping (CatEntry) -> Void) {
        completion(.init(date: .now, pet: PetStore.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CatEntry>) -> Void) {
        let now = Date()
        let pet = PetStore.load()
        let dates = [now, now.addingTimeInterval(90)] + (1...16).map { now.addingTimeInterval(Double($0) * 900) }
        completion(Timeline(entries: dates.map { CatEntry(date: $0, pet: pet.at($0)) }, policy: .atEnd))
    }
}

struct CatHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatHome", provider: CatProvider()) { entry in
            CatHomeView(entry: entry)
                .containerBackground(Color(red: 0.94, green: 0.95, blue: 0.88), for: .widget)
        }
        .configurationDisplayName("Домик Мурчика")
        .description("Котик, его настроение и немного заботы.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct CatHomeView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CatEntry

    var body: some View {
        if family == .accessoryRectangular {
            HStack {
                cat.frame(width: 40, height: 38)
                VStack(alignment: .leading) {
                    Text(entry.pet.name).font(.headline)
                    Text(entry.pet.mood(at: entry.date)).font(.caption)
                }
            }
        } else {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.pet.name).font(.system(.headline, design: .rounded))
                    cat.frame(width: 64, height: 56)
                    Text(entry.pet.mood(at: entry.date)).font(.caption).lineLimit(2)
                    if family == .systemSmall {
                        Button(intent: FeedCatIntent()) { Label("Кормить", systemImage: "fish.fill").font(.caption2) }
                            .tint(.brown)
                    }
                }
                if family == .systemMedium {
                    VStack(alignment: .leading, spacing: 9) {
                        Label("\(Int(entry.pet.food))%", systemImage: "fish.fill")
                        ProgressView(value: entry.pet.food, total: 100).tint(.orange)
                        HStack {
                            Button(intent: FeedCatIntent()) { Image(systemName: "fish.fill") }
                            Button(intent: PlayCatIntent()) { Image(systemName: "tennisball.fill") }
                        }.buttonStyle(.bordered).tint(.brown)
                    }
                }
            }.foregroundStyle(Color(red: 0.23, green: 0.29, blue: 0.22))
        }
    }

    private var cat: some View {
        PixelCat(sleeping: entry.pet.isSleeping(at: entry.date), frame: Int(entry.date.timeIntervalSince1970 / 900) % 2)
    }
}

struct CatLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CatAttributes.self) { context in
            HStack(spacing: 16) {
                PixelCat(sleeping: context.state.sleeping).frame(width: 60, height: 54)
                VStack(alignment: .leading, spacing: 5) {
                    Text(context.attributes.name).font(.headline)
                    Text(context.isStale ? "Котик ждёт тебя" : context.state.mood).font(.caption)
                    Text("Сытость \(context.state.food)% · Радость \(context.state.joy)%").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(intent: FeedCatIntent()) { Image(systemName: "fish.fill") }
                    .buttonStyle(.bordered).tint(.orange).accessibilityLabel("Покормить котика")
            }.padding(16)
                .activityBackgroundTint(Color(red: 0.97, green: 0.95, blue: 0.88))
                .activitySystemActionForegroundColor(.brown)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PixelCat(sleeping: context.state.sleeping).frame(width: 52, height: 44)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label("\(context.state.food)%", systemImage: "fish.fill").font(.caption).foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.name).font(.headline)
                        Text(context.isStale ? "Котик ждёт тебя" : context.state.mood).font(.caption2)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Button(intent: FeedCatIntent()) { Label("Кормить", systemImage: "fish.fill") }
                        Button(intent: PlayCatIntent()) { Label("Играть", systemImage: "tennisball.fill") }
                    }.buttonStyle(.bordered).tint(.orange)
                }
            } compactLeading: {
                PixelCat(sleeping: context.state.sleeping).frame(width: 26, height: 24)
                    .id(context.state.revision).transition(.opacity)
            } compactTrailing: {
                Image(systemName: context.state.sleeping ? "moon.fill" : "heart.fill").foregroundStyle(.orange)
            } minimal: {
                PixelCat(sleeping: context.state.sleeping).frame(width: 22, height: 20)
            }.keylineTint(.orange)
        }
    }
}
