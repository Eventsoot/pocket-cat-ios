import Foundation
import ActivityKit
import WidgetKit

enum PetStore {
    static let group = "group.com.example.PocketCat"
    static var defaults: UserDefaults {
        #if BASIC_BUILD
        return .standard
        #else
        guard let id = sharedGroup else { return .standard }
        return UserDefaults(suiteName: id) ?? .standard
        #endif
    }

    // Some sideloaders rewrite App Groups and declare the replacement in Info.plist.
    static var sharedGroup: String? {
        let rewritten = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] ?? []
        let candidates = rewritten + provisionedGroups + [group]
        return candidates.first { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil }
    }

    private static var provisionedGroups: [String] {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<plist".utf8)),
              let end = data.range(of: Data("</plist>".utf8)), start.lowerBound < end.upperBound,
              let plist = try? PropertyListSerialization.propertyList(from: data.subdata(in: start.lowerBound..<end.upperBound), format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any] else { return [] }
        return entitlements["com.apple.security.application-groups"] as? [String] ?? []
    }

    static var sharingAvailable: Bool { sharedGroup != nil }

    static func load() -> Pet {
        guard let data = defaults.data(forKey: "pet"),
              let pet = try? JSONDecoder().decode(Pet.self, from: data) else {
            // Preserve the first installed basic version when upgrading to widgets.
            if let legacy = UserDefaults.standard.data(forKey: "pet"), let pet = try? JSONDecoder().decode(Pet.self, from: legacy) { return pet }
            return Pet()
        }
        return pet
    }

    static func save(_ pet: Pet) {
        if let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: "pet")
            UserDefaults.standard.set(data, forKey: "pet")
        }
    }

    @discardableResult
    static func act(_ action: CatAction) async -> Pet {
        var pet = load().at(Date())
        pet.care(action)
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
        var coat: Int
        var hat: Int
        var focusEnd: Date?
    }
    var name: String
}

enum CatActivity {
    static func state(_ pet: Pet) -> CatAttributes.ContentState {
        let now = Date()
        let current = pet.at(now)
        return .init(mood: pet.mood(at: now), food: Int(current.food), joy: Int(current.joy), sleeping: pet.isSleeping(at: now), revision: now, coat: pet.coat, hat: pet.hat, focusEnd: pet.focusEnd)
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
