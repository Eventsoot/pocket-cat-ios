import AppIntents

struct FeedCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Покормить котика"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.feed)
        return .result()
    }
}

struct PlayCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Поиграть с котиком"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.play)
        return .result()
    }
}

struct PetCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Погладить котика"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.pet)
        return .result()
    }
}

struct SleepCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Уложить или разбудить котика"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.sleep)
        return .result()
    }
}
