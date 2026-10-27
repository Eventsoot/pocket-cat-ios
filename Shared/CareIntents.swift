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
