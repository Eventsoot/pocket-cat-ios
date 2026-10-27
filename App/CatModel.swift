import SwiftUI
import WidgetKit
import AVFoundation
import UIKit

@MainActor
final class CatModel: ObservableObject {
    @Published var pet = PetStore.load().at(Date())
    @Published var message = "Твой маленький мир, полный мурчания"
    @Published var activityRunning = !ActivityBridge.isEmpty
    private var players: [AVAudioPlayer] = []
    private var ticks = 0

    func tick() {
        ticks += 1
        if ticks % 30 == 0 || (pet.focusEnd.map { $0 <= Date() } ?? false) { refresh() }
        else { pet = pet.at(Date()) }
    }

    func refresh() {
        let previous = pet.focusSessions
        pet = PetStore.load().at(Date())
        if pet.focusSessions > previous { message = "Отличный фокус! Награда уже в копилке ✦" }
        PetStore.save(pet)
        activityRunning = !ActivityBridge.isEmpty
        Task { await CatActivity.sync(pet) }
    }

    func change(_ mutation: (inout Pet) -> Void) {
        pet = pet.at(Date())
        mutation(&pet)
        PetStore.save(pet)
        WidgetCenter.shared.reloadAllTimelines()
        Task { await CatActivity.sync(pet) }
    }

    func care(_ action: CatAction) {
        change { $0.care(action) }
        let response: String
        let sound: String
        switch action {
        case .feed: response = "Хрум-хрум. Самая вкусная рыбка!"; sound = "crunch"
        case .pet: response = ["Мур-р-р… ещё за ушком ♡", "Ты мой любимый человек", "Я бы выбрал тебя снова", "Счастье — это твои ладошки"].randomElement()!; sound = "purr"
        case .sleep: response = pet.sleeping ? "Разбудишь, когда соскучишься?" : "Доброе утро, мой человек!"; sound = pet.sleeping ? "sleep" : "meow"
        case .play: response = "Давай ловить звёздочки!"; sound = "meow"
        case .brush: response = "Теперь я самый пушистый на свете"; sound = "purr"
        case .drink: response = "Буль-буль. Свежая водичка!"; sound = "water"
        }
        message = response
        feedback(sound)
    }

    func feedback(_ sound: String) {
        if pet.hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        guard pet.soundEnabled, let url = Bundle.main.url(forResource: sound, withExtension: "wav") else { return }
        do {
            // Do not replace the playback session while the floating cat uses it.
            if AVAudioSession.sharedInstance().category != .playback {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            }
            try AVAudioSession.sharedInstance().setActive(true)
            players.removeAll { !$0.isPlaying }
            if players.count >= 3 { players.removeFirst().stop() }
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = sound == "purr" ? 0.6 : 0.4
            players.append(player); player.play()
        } catch { message = "Звук недоступен. Котик всё равно рад тебе ♡" }
    }

    func silence() { players.forEach { $0.stop() }; players.removeAll() }

    func toggleActivity() {
        Task {
            do {
                if activityRunning { await CatActivity.stop() }
                else { try CatActivity.start(pet) }
                activityRunning = !ActivityBridge.isEmpty
                message = activityRunning ? "Котик поселился на экране блокировки" : "Котик вернулся в домик"
            } catch { message = error.localizedDescription }
        }
    }
}

import ActivityKit
enum ActivityBridge { static var isEmpty: Bool { Activity<CatAttributes>.activities.isEmpty } }
