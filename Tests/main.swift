import Foundation
func expect(_ condition: @autoclosure () -> Bool, _ message: String) { if !condition() { fatalError(message) } }
let now = Date(timeIntervalSince1970: 1793102400)
var pet = Pet(); pet.updated = now
let old = """
{"name":"Старый друг","food":42,"joy":71,"energy":80,"updated":0,"lastAction":"pet","actionDate":0}
""".data(using: .utf8)!
let migrated = try JSONDecoder().decode(Pet.self, from: old)
expect(migrated.name == "Старый друг" && migrated.food == 42 && migrated.coins == 30, "Old saves migrate")
expect(pet.claimGift(at: now), "Daily gift available")
let coins = pet.coins
expect(!pet.claimGift(at: now.addingTimeInterval(60)) && pet.coins == coins, "No duplicate gift")
expect(pet.claimGift(at: now.addingTimeInterval(86400)) && pet.streak == 2, "Consecutive-day streak")
pet = Pet(); pet.updated = now; pet.sleeping = true; pet.energy = 30
let rested = pet.at(now.addingTimeInterval(3600))
expect(rested.energy == 46 && rested.food < pet.food, "Sleep restores energy with offline decay")
pet = Pet(); pet.updated = now
pet.care(.pet, at: now); let xp = pet.xp
pet.care(.pet, at: now.addingTimeInterval(1)); expect(pet.xp == xp, "Care XP rate limited")
pet.care(.drink, at: now); expect(pet.water <= 100, "Water clamps")
pet.coins = 30; expect(pet.wear(1) && pet.coins == 0, "Purchase debits once")
expect(pet.wear(1) && pet.coins == 0, "Owned accessories stay free")
expect(!pet.wear(3) && pet.hat == 1, "Insufficient funds cannot buy crown")
pet.startFocus(minutes: 5, at: now)
let first = pet.at(now.addingTimeInterval(301)), second = first.at(now.addingTimeInterval(600))
expect(first.focusSessions == 1 && second.focusSessions == 1 && first.coins == second.coins, "Focus reward exactly once")
pet = Pet(); pet.updated = now
for _ in 0..<3 { pet.care(.feed, at: now) }
for _ in 0..<5 { pet.care(.pet, at: now) }
pet.completeGame(score: 10, at: now)
expect(pet.claimMission(at: now), "Completed daily missions award")
let balance = pet.coins
expect(!pet.claimMission(at: now) && pet.coins == balance, "No duplicate mission award")
expect(!pet.at(now.addingTimeInterval(86400)).missionsDone, "New day resets missions")
let encoded = try JSONEncoder().encode(pet), decoded = try JSONDecoder().decode(Pet.self, from: encoded)
expect(decoded.coins == pet.coins && decoded.stars == 10 && decoded.missionClaimed, "New save round trip")
print("PASS: migration, rewards, streak, sleep, XP limits, wardrobe, focus, missions and persistence.")
