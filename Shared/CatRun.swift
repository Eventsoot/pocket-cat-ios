import Foundation

/// Fixed-step game rules, independent of rendering and screen size.
struct CatRun {
    enum Phase { case ready, running, paused, won, lost }
    enum Kind { case star, crate, bird, heart }
    struct Item: Identifiable {
        let id: Int
        let kind: Kind
        var x: Double
        let height: Double
    }
    var phase = Phase.ready
    var items: [Item] = []
    var height = 0.0
    var velocity = 0.0
    var jumps = 0
    var distance = 0.0
    var stars = 0
    var lives = 3
    var combo = 0
    var score = 0
    var shield = 0.0
    private var spawn = 0.8
    private var nextID = 0
    var world: Int { min(2, Int(distance / 1800)) }
    var progress: Double { min(1, distance / 5400) }

    mutating func start() { self = CatRun(); phase = .running }
    @discardableResult mutating func jump() -> Bool {
        guard phase == .running, jumps < 2 else { return false }
        velocity = jumps == 0 ? 480 : 415; jumps += 1
        return true
    }

    /// Returns sound events; the view applies settings and haptics.
    mutating func step(_ dt: Double) -> [String] {
        guard phase == .running else { return [] }
        let dt = min(max(dt, 0), 1.0 / 30)
        let speed = 145.0 + Double(world) * 24
        var events: [String] = []
        distance += speed * dt
        shield = max(0, shield - dt)
        velocity -= 1120 * dt; height += velocity * dt
        if height <= 0 { height = 0; velocity = 0; jumps = 0 }
        spawn -= dt
        if spawn <= 0 {
            nextID += 1
            let kind: Kind
            if nextID % 11 == 0 { kind = .heart }
            else if nextID % 3 == 0 { kind = world > 0 && nextID % 2 == 0 ? .bird : .crate }
            else { kind = .star }
            let altitude = kind == .bird ? 102.0 : kind == .crate ? 20.0 : nextID % 2 == 0 ? 110.0 : 40.0
            items.append(Item(id: nextID, kind: kind, x: 430, height: altitude))
            spawn = max(0.92, 1.45 - Double(world) * 0.15)
        }
        for index in items.indices { items[index].x -= speed * dt }
        var consumed: Set<Int> = []
        for item in items where abs(item.x - 76) < 29 && abs(item.height - (height + 25)) < 31 {
            switch item.kind {
            case .star:
                stars += 1; combo += 1; score += 10 + min(combo, 10) * 2; events.append("pickup")
                consumed.insert(item.id)
            case .heart:
                lives = min(3, lives + 1); score += 15; events.append("sparkle"); consumed.insert(item.id)
            case .crate, .bird:
                if shield == 0 {
                    lives -= 1; combo = 0; shield = 1.8; events.append("bump"); consumed.insert(item.id)
                    if lives <= 0 { phase = .lost }
                }
            }
        }
        for item in items where item.x < -30 && item.kind == .star { combo = 0 }
        items.removeAll { $0.x < -30 || consumed.contains($0.id) }
        if phase == .running && distance >= 5400 { phase = .won; score += lives * 100; events.append("victory") }
        return events
    }
}
