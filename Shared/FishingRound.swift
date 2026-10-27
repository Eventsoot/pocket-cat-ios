import Foundation

struct FishingRound {
    enum Phase { case idle, waiting, bite, reeling, caught, escaped }
    var phase = Phase.idle
    var species = 0
    var elapsed = 0.0
    var tension = 25.0
    var pulls = 0
    private var wait = 2.0
    private var cooldown = 0.0
    private var claimed = false
    var marker: Double { 0.5 + sin(elapsed * (3.2 + Double(species) * 0.5)) * 0.46 }
    var inZone: Bool { (0.32...0.68).contains(marker) }

    mutating func cast(wait: Double, species: Int) {
        self = FishingRound(); self.wait = max(1, wait)
        self.species = min(3, max(0, species)); phase = .waiting
    }
    mutating func step(_ dt: Double) {
        guard phase == .waiting || phase == .bite || phase == .reeling else { return }
        let dt = max(0, min(0.1, dt))
        elapsed += dt; cooldown = max(0, cooldown - dt)
        if phase == .waiting && elapsed >= wait { phase = .bite; elapsed = 0 }
        else if phase == .bite && elapsed > 1.4 { phase = .escaped }
        else if phase == .reeling {
            tension = min(100, tension + dt * 4)
            if tension >= 100 || elapsed > 15 { phase = .escaped }
        }
    }
    @discardableResult mutating func hookOrPull() -> Bool {
        if phase == .waiting { phase = .escaped; return false }
        if phase == .bite { phase = .reeling; elapsed = 0; return true }
        guard phase == .reeling, cooldown == 0 else { return false }
        cooldown = 0.4
        if inZone {
            pulls += 1; tension = max(0, tension - 8)
            if pulls == 3 { phase = .caught }
            return true
        }
        tension = min(100, tension + 27)
        if tension >= 100 { phase = .escaped }
        return false
    }
    mutating func claimCatch() -> Int? {
        guard phase == .caught, !claimed else { return nil }
        claimed = true; return species
    }
}
