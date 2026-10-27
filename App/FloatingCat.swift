import SwiftUI
import AVKit

/// PiP plays an actual locally rendered video. It is not a transparent overlay.
@MainActor
final class FloatingCat: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var preparing = false
    @Published var active = false
    @Published var message = "Твій маленький супутник — у плавучому вікні"
    @Published var ready = false
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var controller: AVPictureInPictureController?
    private var observation: NSKeyValueObservation?
    private var identity = ""

    func attach(_ layer: AVPlayerLayer) {
        guard controller == nil, AVPictureInPictureController.isPictureInPictureSupported() else { return }
        let pip = AVPictureInPictureController(playerLayer: layer)
        pip?.delegate = self
        pip?.canStartPictureInPictureAutomaticallyFromInline = false
        controller = pip
        observation = pip?.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] pip, _ in
            Task { @MainActor in self?.ready = pip.isPictureInPicturePossible }
        }
    }

    func prepare(pet: Pet) async {
        let key = "\(pet.coat)-\(pet.room)-\(pet.hat)-\(pet.sleeping)"
        guard !preparing, key != identity, !active else { return }
        preparing = true; ready = false
        message = "Готую маленький світ…"
        defer { preparing = false }
        do {
            let url = try await render(pet: pet)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player.pause(); looper = nil; player.removeAllItems()
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            player.volume = 0
            player.play()
            identity = key
            message = "Натисни «Поверх застосунків», потім відкрий Telegram або Safari"
        } catch { message = "Не вдалося підготувати вікно: \(CatLanguage.error(error))" }
    }

    func toggle() {
        guard let controller else { message = "Плавуче відео недоступне на цьому пристрої"; return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player.play()
        } catch { message = "Не вдалося ввімкнути відео: \(CatLanguage.error(error))"; return }
        if active { controller.stopPictureInPicture() }
        else if controller.isPictureInPicturePossible { controller.startPictureInPicture() }
        else { message = "Зачекай, поки відео буде готове, і натисни ще раз" }
    }

    private func render(pet: Pet) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cat-\(UUID().uuidString).mp4")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 640, AVVideoHeightKey: 400,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 900_000]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: 640, kCVPixelBufferHeightKey as String: 400,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ])
        guard writer.canAdd(input) else { throw VideoError.failed }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? VideoError.failed }
        writer.startSession(atSourceTime: .zero)
        let start = Date(timeIntervalSince1970: 0)
        for frame in 0..<180 {
            while !input.isReadyForMoreMediaData {
                guard writer.status == .writing else { throw writer.error ?? VideoError.failed }
                try await Task.sleep(for: .milliseconds(10))
            }
            let scene = FloatingScene(pet: pet, time: start.addingTimeInterval(Double(frame) / 15))
                .frame(width: 640, height: 400).environment(\.colorScheme, .light)
            let renderer = ImageRenderer(content: scene)
            renderer.scale = 1
            guard let image = renderer.cgImage, let pool = adaptor.pixelBufferPool else { throw VideoError.failed }
            var buffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess, let buffer else { throw VideoError.failed }
            CVPixelBufferLockBaseAddress(buffer, [])
            guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: 640, height: 400, bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                CVPixelBufferUnlockBaseAddress(buffer, []); throw VideoError.failed
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: 640, height: 400))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 15)) else { throw writer.error ?? VideoError.failed }
            if frame % 6 == 0 { await Task.yield() }
        }
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? VideoError.failed }
        return url
    }

    enum VideoError: LocalizedError {
        case failed
        var errorDescription: String? { "Не вдалося створити відео котика" }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in self.active = true; self.message = "Котик поруч. Вікно можна переміщувати та змінювати його розмір." }
    }
    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in self.active = false }
    }
    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        let text = CatLanguage.error(error)
        Task { @MainActor in self.message = "Не вдалося відкрити PiP: \(text)" }
    }
    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}

struct FloatingScene: View {
    let pet: Pet
    let time: Date
    private var phase: Double { time.timeIntervalSince1970.truncatingRemainder(dividingBy: 12) / 12 }
    var body: some View {
        GeometryReader { g in
            ZStack {
                RoomArtwork(scene: pet.room)
                let path = sin(phase * .pi * 2)
                let x = g.size.width * (0.5 + (pet.sleeping ? 0 : path * 0.2))
                let bob = pet.sleeping ? 0 : sin(phase * .pi * 24) * 3
                Ellipse().fill(.black.opacity(0.08)).frame(width: 95, height: 13).position(x: x, y: g.size.height * 0.77)
                PixelCat(sleeping: pet.sleeping, frame: Int(phase * 24) % 2, color: CatTheme.coats[pet.coat], hat: pet.hat,
                         happy: phase > 0.78)
                    .frame(width: 160, height: 143).scaleEffect(x: cos(phase * .pi * 2) < 0 ? -1 : 1, y: 1)
                    .position(x: x, y: g.size.height * 0.61 + bob)
                VStack {
                    HStack {
                        Text(pet.name).font(.system(size: 17, weight: .semibold, design: .rounded))
                        Spacer()
                        Image(systemName: pet.sleeping ? "moon.fill" : "heart.fill").foregroundStyle(CatTheme.rose)
                    }.padding(.horizontal, 23).padding(.top, 18)
                    Spacer()
                }.foregroundStyle(CatTheme.ink)
                if pet.sleeping { Text("z Z").font(.system(size: 25, design: .serif).italic()).foregroundStyle(CatTheme.lavender).position(x: x + 50, y: g.size.height * 0.41) }
                if phase > 0.78 && !pet.sleeping {
                    Text("♡").font(.system(size: 26)).foregroundStyle(CatTheme.rose.opacity(sin((phase - 0.78) / 0.22 * .pi)))
                        .position(x: x + 18, y: g.size.height * 0.36 - (phase - 0.78) * 80)
                }
            }.clipped()
        }
    }
}

struct CatVideoSurface: UIViewRepresentable {
    @ObservedObject var floating: FloatingCat
    final class Surface: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var videoLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
    func makeUIView(context: Context) -> Surface {
        let view = Surface()
        view.videoLayer.player = floating.player
        view.videoLayer.videoGravity = .resizeAspectFill
        floating.attach(view.videoLayer)
        return view
    }
    func updateUIView(_ uiView: Surface, context: Context) {}
}

struct FloatingCatCard: View {
    @ObservedObject var model: CatModel
    @StateObject private var floating = FloatingCat()
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "pip.enter").foregroundStyle(CatTheme.rose)
                Text("Візьми мене із собою").font(.system(.title2, design: .serif))
            }
            Text("Маленький живий світ поверх Telegram, Safari та інших застосунків.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            ZStack {
                CatVideoSurface(floating: floating)
                if floating.preparing { CatTheme.paper.opacity(0.9); ProgressView("Готую котика…").tint(CatTheme.rose) }
            }.aspectRatio(1.6, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 22))
            Button { floating.toggle() } label: {
                Label(floating.active ? "Повернути до хатинки" : "Поверх застосунків", systemImage: floating.active ? "pip.exit" : "pip.enter")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).padding(16).frame(maxWidth: .infinity)
                    .background(CatTheme.rose, in: Capsule())
            }.disabled(floating.preparing)
            Text(floating.message).font(.system(size: 10)).foregroundStyle(CatTheme.rose)
            Text("Це плавуче відео PiP: вікно можна пересувати пальцем. iOS визначає рамку, розташування та кнопки. Відео без звуку; догляд та ігри залишаються в хатинці.")
                .font(.system(size: 9)).foregroundStyle(.secondary)
        }.softCard()
        .task(id: "\(model.pet.coat)-\(model.pet.room)-\(model.pet.hat)-\(model.pet.sleeping)") { await floating.prepare(pet: model.pet) }
    }
}
