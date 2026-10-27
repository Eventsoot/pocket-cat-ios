import SwiftUI
import WidgetKit
import ActivityKit

struct CozyHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatHome", provider: CatProvider()) { entry in
            CozyWidgetView(entry: entry)
                .containerBackground(CatTheme.paper, for: .widget)
        }
        .configurationDisplayName("Уютный домик")
        .description("Комната, твой котик и забота одним касанием.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct CozyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CatEntry
    private var large: Bool { family == .systemLarge }
    private var small: Bool { family == .systemSmall }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "pawprint.fill").foregroundStyle(CatTheme.rose).font(.system(size: 10))
                Text(entry.pet.name).font(.system(size: 12, weight: .bold, design: .rounded)).lineLimit(1)
                Spacer(minLength: 0)
                if !small { Text("LV \(entry.pet.level)").font(.system(size: 8, weight: .semibold)).foregroundStyle(CatTheme.rose) }
            }.padding(.horizontal, 15).padding(.top, 12).padding(.bottom, 5)
            if small {
                ZStack {
                    CozyRoom(pet: entry.pet, time: entry.date)
                    VStack { Spacer(); Text(entry.pet.mood(at: entry.date)).font(.system(size: 8, weight: .medium)).lineLimit(1).padding(5).background(CatTheme.paper.opacity(0.9), in: Capsule()).padding(.bottom, 3) }
                }
                HStack {
                    Button(intent: FeedCatIntent()) { Image(systemName: "fish.fill") }.accessibilityLabel("Покормить")
                    Spacer()
                    Button(intent: PetCatIntent()) { Image(systemName: "heart.fill") }.accessibilityLabel("Погладить")
                }.font(.system(size: 11)).buttonStyle(.plain).foregroundStyle(CatTheme.rose).padding(.horizontal, 24).padding(.vertical, 9)
            } else {
                HStack(spacing: 0) {
                    CozyRoom(pet: entry.pet, time: entry.date).frame(maxWidth: .infinity)
                    VStack(alignment: .leading, spacing: 9) {
                        Text(entry.pet.mood(at: entry.date)).font(.system(size: 10, weight: .medium, design: .rounded)).lineLimit(2)
                        widgetMeter("fish.fill", entry.pet.food, Color(hex: 0xC9A075))
                        widgetMeter("heart.fill", entry.pet.joy, CatTheme.rose)
                        if large { widgetMeter("moon.fill", entry.pet.energy, CatTheme.lavender) }
                    }.frame(width: 95).padding(.horizontal, 12)
                }.frame(maxHeight: .infinity)
                if large {
                    HStack {
                        Label("\(entry.pet.streak) дней вместе", systemImage: "flame.fill")
                        Spacer()
                        Text("\(entry.pet.coins) ✦")
                    }.font(.system(size: 10)).foregroundStyle(CatTheme.rose).padding(.horizontal, 18).padding(.vertical, 8)
                }
                HStack(spacing: 10) {
                    Button(intent: FeedCatIntent()) { Label("Кормить", systemImage: "fish.fill") }
                    Button(intent: PetCatIntent()) { Label("Гладить", systemImage: "heart.fill") }
                    Button(intent: SleepCatIntent()) { Image(systemName: entry.pet.sleeping ? "sun.max.fill" : "moon.fill") }.accessibilityLabel(entry.pet.sleeping ? "Разбудить" : "Спать")
                }.font(.system(size: 10)).buttonStyle(.bordered).tint(CatTheme.rose).padding(.bottom, 9)
            }
        }.foregroundStyle(CatTheme.ink)
    }

    private func widgetMeter(_ symbol: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 9)).foregroundStyle(color)
            ProgressView(value: value, total: 100).tint(color)
            Text("\(Int(value))").font(.system(size: 8)).foregroundStyle(.secondary)
        }
    }
}

struct CatNeedsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CatLockScreen", provider: CatProvider()) { entry in
            LockCatView(entry: entry).containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Котик на экране блокировки")
        .description("Маленький друг и его настроение — прямо рядом с часами.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockCatView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CatEntry

    var body: some View {
        if family == .accessoryInline {
            Label("\(entry.pet.name) · \(entry.pet.mood(at: entry.date))", systemImage: "pawprint.fill")
        } else if family == .accessoryCircular {
            Gauge(value: entry.pet.food, in: 0...100) {
                Image(systemName: "pawprint.fill")
            } currentValueLabel: {
                PixelCat(sleeping: entry.pet.sleeping, color: CatTheme.coats[entry.pet.coat], hat: entry.pet.hat).frame(width: 32, height: 30)
            }.gaugeStyle(.accessoryCircular)
        } else {
            HStack(spacing: 8) {
                PixelCat(sleeping: entry.pet.sleeping, color: CatTheme.coats[entry.pet.coat], hat: entry.pet.hat).frame(width: 42, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.pet.name).font(.headline)
                    Text(entry.pet.mood(at: entry.date)).font(.caption2).lineLimit(1)
                    Text("Сытость \(Int(entry.pet.food))% · ♡ \(Int(entry.pet.joy))%").font(.system(size: 9))
                }
            }
        }
    }
}

struct CozyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CatAttributes.self) { context in
            VStack(spacing: 11) {
                HStack(spacing: 14) {
                    PixelCat(sleeping: context.state.sleeping, color: CatTheme.coats[min(5, max(0, context.state.coat))], hat: context.state.hat, happy: true)
                        .frame(width: 58, height: 50)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.name).font(.system(.headline, design: .rounded))
                        Text(context.isStale ? "Ждёт маленького знака внимания ♡" : context.state.mood).font(.caption).lineLimit(1)
                        if let end = context.state.focusEnd, end > Date() {
                            Text(timerInterval: Date()...end, countsDown: true).font(.system(.title3, design: .rounded)).monospacedDigit()
                        } else {
                            Text("Сытость \(context.state.food)% · Радость \(context.state.joy)%").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "heart.fill").foregroundStyle(CatTheme.rose.opacity(0.45))
                }
                HStack(spacing: 10) {
                    Button(intent: FeedCatIntent()) { Label("Кормить", systemImage: "fish.fill") }
                    Button(intent: PetCatIntent()) { Label("Гладить", systemImage: "heart.fill") }
                    Button(intent: SleepCatIntent()) { Image(systemName: context.state.sleeping ? "sun.max.fill" : "moon.fill") }.accessibilityLabel("Сон и пробуждение")
                }.font(.system(size: 11)).buttonStyle(.bordered).tint(CatTheme.rose)
            }.padding(17).foregroundStyle(CatTheme.ink)
                .activityBackgroundTint(CatTheme.paper).activitySystemActionForegroundColor(CatTheme.rose)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { cat(context.state).frame(width: 48, height: 42) }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.attributes.name).font(.headline)
                        Text(context.isStale ? "Ждёт тебя ♡" : context.state.mood).font(.caption2)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) { Text("\(context.state.food)%").font(.caption).foregroundStyle(.orange) }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Button(intent: FeedCatIntent()) { Label("Кормить", systemImage: "fish.fill") }
                        Button(intent: PetCatIntent()) { Label("Гладить", systemImage: "heart.fill") }
                    }.buttonStyle(.bordered).tint(.pink)
                }
            } compactLeading: { cat(context.state).frame(width: 26, height: 24) }
            compactTrailing: { Image(systemName: context.state.sleeping ? "moon.fill" : "heart.fill").foregroundStyle(.pink) }
            minimal: { cat(context.state).frame(width: 22, height: 21) }
        }
    }

    private func cat(_ state: CatAttributes.ContentState) -> some View {
        PixelCat(sleeping: state.sleeping, color: CatTheme.coats[min(5, max(0, state.coat))], hat: state.hat)
    }
}
