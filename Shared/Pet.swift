import Foundation
import ActivityKit
import WidgetKit

enum CatAction: String, Codable {
    case feed, play, sleep, pet
}

struct Pet: Codable {
    var name = "Мурчик"
    var food = 85.0
    var joy = 80.0
    var energy = 90.0
    var updated = Date()
    var lastAction: CatAction = .pet
    var actionDate = Date.distantPast

    func at(_ date: Date) -> Pet {
        var result = self
        let hours = max(0, date.timeIntervalSince(updated) / 3600)
        result.food = max(0, food - hours * 4)
        result.joy = max(0, joy - hours * 3)
        result.energy = max(0, energy - hours * 2)
        result.updated = date
        return result
    }

    func mood(at date: Date) -> String {
        if date.timeIntervalSince(actionDate) < 90 {
            switch lastAction {
            case .feed: return "Вкусно хрустит"
            case .play: return "Ловит клубочек"
            case .sleep: return "Сладко спит"
            case .pet: return "Мурчит для тебя"
            }
        }
        let current = at(date)
        if current.food < 25 { return "Мечтает о рыбке" }
        if current.energy < 25 { return "Дремлет на облаке" }
        return ["Гуляет по островку", "Умывает лапки", "Смотрит на звёзды", "Потягивается", "Ловит свой хвост"][Int(date.timeIntervalSince1970 / 900) % 5]
    }

    func isSleeping(at date: Date) -> Bool {
        (lastAction == .sleep && date.timeIntervalSince(actionDate) < 90) || at(date).energy < 25
    }
}

enum PetStore {
    static let group = "group.com.example.PocketCat"
    static var defaults: UserDefaults {
        #if BASIC_BUILD
        return .standard
        #else
        return UserDefaults(suiteName: group) ?? .standard
        #endif
    }

    static func load() -> Pet {
        guard let data = defaults.data(forKey: "pet"),
              let pet = try? JSONDecoder().decode(Pet.self, from: data) else { return Pet() }
        return pet
    }

    static func save(_ pet: Pet) {
        if let data = try? JSONEncoder().encode(pet) { defaults.set(data, forKey: "pet") }
    }

    @discardableResult
    static func act(_ action: CatAction) async -> Pet {
        var pet = load().at(Date())
        switch action {
        case .feed: pet.food = min(100, pet.food + 25)
        case .play:
            pet.joy = min(100, pet.joy + 25)
            pet.energy = max(0, pet.energy - 8)
        case .sleep: pet.energy = min(100, pet.energy + 30)
        case .pet: pet.joy = min(100, pet.joy + 10)
        }
        pet.lastAction = action
        pet.actionDate = Date()
        save(pet)
        WidgetCenter.shared.reloadAllTimelines()
        await CatActivity.sync(pet)
        return pet
    }
}

struct CatAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var mood: String
        var food: Int
        var joy: Int
        var sleeping: Bool
        var revision: Date
    }
    var name: String
}

enum CatActivity {
    static func state(_ pet: Pet) -> CatAttributes.ContentState {
        let now = Date()
        let current = pet.at(now)
        return .init(mood: pet.mood(at: now), food: Int(current.food), joy: Int(current.joy), sleeping: pet.isSleeping(at: now), revision: now)
    }

    static func start(_ pet: Pet) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw CatError.disabled }
        guard Activity<CatAttributes>.activities.isEmpty else { return }
        _ = try Activity.request(attributes: CatAttributes(name: pet.name), content: ActivityContent(state: state(pet), staleDate: Date().addingTimeInterval(900)), pushType: nil)
    }

    static func sync(_ pet: Pet) async {
        for activity in Activity<CatAttributes>.activities {
            await activity.update(ActivityContent(state: state(pet), staleDate: Date().addingTimeInterval(900)))
        }
    }

    static func stop() async {
        for activity in Activity<CatAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    enum CatError: LocalizedError {
        case disabled
        var errorDescription: String? { "Разреши Live Activities в настройках iPhone для Мурчика." }
    }
}
