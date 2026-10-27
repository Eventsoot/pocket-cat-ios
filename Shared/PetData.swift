import Foundation

enum CatAction: String, Codable { case feed, play, sleep, pet, brush, drink }

struct Pet: Codable {
    var name = "Мурчик"
    var food = 85.0
    var joy = 80.0
    var energy = 90.0
    var water = 85.0
    var updated = Date()
    var lastAction: CatAction = .pet
    var actionDate = Date.distantPast
    var sleeping = false
    var coat = 0
    var room = 0
    var hat = 0
    var coins = 30
    var xp = 0
    var strokes = 0
    var meals = 0
    var fish = 3
    var fishCaught = [0, 0, 0, 0]
    var games = 0
    var stars = 0
    var streak = 0
    var lastGift = Date.distantPast
    var missionDay = Date.distantPast
    var todayMeals = 0
    var todayStrokes = 0
    var todayGames = 0
    var missionClaimed = false
    var ownedHats = [0]
    var soundEnabled = true
    var hapticsEnabled = true
    var focusEnd: Date?
    var focusMinutes = 0
    var focusSessions = 0

    var level: Int { xp / 100 + 1 }
    var missionsDone: Bool { todayMeals >= 3 && todayStrokes >= 5 && todayGames >= 1 }
    var achievements: [Bool] {
        [strokes >= 1, meals >= 10, games >= 1, stars >= 20, streak >= 3, level >= 5, ownedHats.count >= 3, focusSessions >= 1]
    }

    // Decode old installations with defaults for every new field.
    init() {}
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? name
        food = try c.decodeIfPresent(Double.self, forKey: .food) ?? food
        joy = try c.decodeIfPresent(Double.self, forKey: .joy) ?? joy
        energy = try c.decodeIfPresent(Double.self, forKey: .energy) ?? energy
        water = try c.decodeIfPresent(Double.self, forKey: .water) ?? water
        updated = try c.decodeIfPresent(Date.self, forKey: .updated) ?? updated
        lastAction = try c.decodeIfPresent(CatAction.self, forKey: .lastAction) ?? lastAction
        actionDate = try c.decodeIfPresent(Date.self, forKey: .actionDate) ?? actionDate
        sleeping = try c.decodeIfPresent(Bool.self, forKey: .sleeping) ?? sleeping
        coat = try c.decodeIfPresent(Int.self, forKey: .coat) ?? coat
        room = try c.decodeIfPresent(Int.self, forKey: .room) ?? room
        hat = try c.decodeIfPresent(Int.self, forKey: .hat) ?? hat
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? coins
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? xp
        strokes = try c.decodeIfPresent(Int.self, forKey: .strokes) ?? strokes
        meals = try c.decodeIfPresent(Int.self, forKey: .meals) ?? meals
        fish = max(0, try c.decodeIfPresent(Int.self, forKey: .fish) ?? fish)
        let catches = try c.decodeIfPresent([Int].self, forKey: .fishCaught) ?? fishCaught
        fishCaught = (0..<4).map { catches.indices.contains($0) ? max(0, catches[$0]) : 0 }
        games = try c.decodeIfPresent(Int.self, forKey: .games) ?? games
        stars = try c.decodeIfPresent(Int.self, forKey: .stars) ?? stars
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? streak
        lastGift = try c.decodeIfPresent(Date.self, forKey: .lastGift) ?? lastGift
        missionDay = try c.decodeIfPresent(Date.self, forKey: .missionDay) ?? missionDay
        todayMeals = try c.decodeIfPresent(Int.self, forKey: .todayMeals) ?? todayMeals
        todayStrokes = try c.decodeIfPresent(Int.self, forKey: .todayStrokes) ?? todayStrokes
        todayGames = try c.decodeIfPresent(Int.self, forKey: .todayGames) ?? todayGames
        missionClaimed = try c.decodeIfPresent(Bool.self, forKey: .missionClaimed) ?? missionClaimed
        ownedHats = try c.decodeIfPresent([Int].self, forKey: .ownedHats) ?? ownedHats
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? soundEnabled
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? hapticsEnabled
        focusEnd = try c.decodeIfPresent(Date.self, forKey: .focusEnd)
        focusMinutes = try c.decodeIfPresent(Int.self, forKey: .focusMinutes) ?? focusMinutes
        focusSessions = try c.decodeIfPresent(Int.self, forKey: .focusSessions) ?? focusSessions
        food = Self.clamp(food); joy = Self.clamp(joy); energy = Self.clamp(energy); water = Self.clamp(water)
        coat = min(5, max(0, coat)); room = min(2, max(0, room)); hat = min(3, max(0, hat))
        coins = max(0, coins); xp = max(0, xp)
    }

    static func clamp(_ value: Double) -> Double { value.isFinite ? min(100, max(0, value)) : 0 }

    func at(_ date: Date) -> Pet {
        var p = self
        let hours = max(0, date.timeIntervalSince(updated) / 3600)
        p.food = Self.clamp(food - hours * 4)
        p.joy = Self.clamp(joy - hours * 2)
        p.water = Self.clamp(water - hours * 3)
        p.energy = Self.clamp(energy + hours * (sleeping ? 16 : -2))
        p.updated = date
        if !Calendar.current.isDate(missionDay, inSameDayAs: date) {
            p.missionDay = date; p.todayMeals = 0; p.todayGames = 0; p.todayStrokes = 0; p.missionClaimed = false
        }
        if let end = focusEnd, date >= end {
            p.focusEnd = nil; p.coins += max(5, focusMinutes); p.xp += 20; p.focusSessions += 1
        }
        return p
    }

    mutating func care(_ action: CatAction, at date: Date = Date()) {
        self = at(date)
        guard action != .feed || fish > 0 else { return }
        switch action {
        case .feed: fish -= 1; food = Self.clamp(food + 22); meals += 1; todayMeals += 1
        case .play: joy = Self.clamp(joy + 15); energy = Self.clamp(energy - 4)
        case .sleep: sleeping.toggle()
        case .pet: joy = Self.clamp(joy + 6); strokes += 1; todayStrokes += 1
        case .brush: joy = Self.clamp(joy + 10)
        case .drink: water = Self.clamp(water + 30)
        }
        if action != .sleep { sleeping = false }
        // Care earns XP at most once per 20 seconds, regardless of tap speed.
        if date.timeIntervalSince(actionDate) >= 20 { xp += 3 }
        lastAction = action; actionDate = date
    }

    mutating func catchFish(species: Int, at date: Date = Date()) {
        guard (0..<4).contains(species) else { return }
        self = at(date)
        fish += 1; fishCaught[species] += 1
        xp += 3 + species; coins += 2 + species
        games += 1; todayGames += 1
    }

    mutating func completeGame(score: Int, at date: Date = Date()) {
        self = at(date)
        let earned = min(40, max(0, score))
        games += 1; todayGames += 1; stars += earned
        coins += earned; xp += earned * 2; joy = Self.clamp(joy + Double(earned) * 2)
    }

    @discardableResult
    mutating func claimGift(at date: Date = Date()) -> Bool {
        self = at(date)
        guard !Calendar.current.isDate(lastGift, inSameDayAs: date) else { return false }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        streak = Calendar.current.isDate(lastGift, inSameDayAs: yesterday) ? streak + 1 : 1
        coins += 25; xp += 10; lastGift = date
        return true
    }

    @discardableResult
    mutating func claimMission(at date: Date = Date()) -> Bool {
        self = at(date)
        guard missionsDone && !missionClaimed else { return false }
        missionClaimed = true; coins += 40; xp += 25
        return true
    }

    @discardableResult
    mutating func wear(_ item: Int) -> Bool {
        let prices = [0, 30, 60, 100]
        guard prices.indices.contains(item) else { return false }
        if !ownedHats.contains(item) {
            guard coins >= prices[item] else { return false }
            coins -= prices[item]; ownedHats.append(item)
        }
        hat = item; return true
    }

    mutating func startFocus(minutes: Int, at date: Date = Date()) {
        self = at(date)
        guard focusEnd == nil else { return }
        focusMinutes = min(60, max(1, minutes))
        focusEnd = date.addingTimeInterval(Double(focusMinutes) * 60)
    }

    func mood(at date: Date) -> String {
        if sleeping { return "Сладко спит" }
        if let end = focusEnd, date < end { return "Сосредоточен вместе с тобой" }
        if date.timeIntervalSince(actionDate) < 30 {
            switch lastAction {
            case .feed: return "Вкусно хрустит"
            case .play: return "Ловит клубочек"
            case .sleep: return "Потягивается после сна"
            case .pet: return "Мурчит для тебя"
            case .brush: return "Наводит пушистый порядок"
            case .drink: return "Пьёт свежую водичку"
            }
        }
        let current = at(date)
        if current.food < 25 { return "Мечтает о рыбке" }
        if current.water < 25 { return "Ждёт водичку" }
        if current.energy < 25 { return "Сонно щурит глазки" }
        let index = abs(Int(date.timeIntervalSince1970 / 18) % 6)
        return ["Исследует свой домик", "Умывает лапки", "Смотрит на звёзды", "Сладко потягивается", "Ловит свой хвост", "Охотится на пылинку"][index]
    }

    func isSleeping(at date: Date) -> Bool { sleeping }
}
