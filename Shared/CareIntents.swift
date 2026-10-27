import AppIntents

struct FeedCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Нагодувати котика"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.feed)
        return .result()
    }
}

struct PlayCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Пограти з котиком"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.play)
        return .result()
    }
}

struct PetCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Погладити котика"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.pet)
        return .result()
    }
}

struct SleepCatIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Укласти спати або розбудити котика"
    static var openAppWhenRun = false
    func perform() async throws -> some IntentResult {
        await PetStore.act(.sleep)
        return .result()
    }
}
