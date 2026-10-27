import SwiftUI
import AVKit

/// A device experiment: a clear video-call content view is not a guarantee
/// that the system PiP window underneath will also be transparent.
@MainActor final class TransparentCatProbe: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var message = "Проверка другого механизма PiP. Прозрачность окна зависит от iOS."
    @Published var active = false
    private var pip: AVPictureInPictureController?
    private var content: AVPictureInPictureVideoCallViewController?
    private var surface: CatProbeSurface?
    private var pending = false

    func attach(_ source: UIView, pet: Pet) {
        guard pip == nil, source.window != nil else { return }
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            message = "Устройство не поддерживает PiP"; return
        }
        let vc = AVPictureInPictureVideoCallViewController()
        vc.preferredContentSize = CGSize(width: 240, height: 160)
        vc.loadViewIfNeeded()
        vc.view.backgroundColor = .clear; vc.view.isOpaque = false
        let drawing = CatProbeSurface()
        drawing.configure(pet)
        drawing.frame = vc.view.bounds
        drawing.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(drawing)
        let source = AVPictureInPictureController.ContentSource(activeVideoCallSourceView: source, contentViewController: vc)
        let controller = AVPictureInPictureController(contentSource: source)
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        content = vc; surface = drawing; pip = controller
    }

    func toggle() {
        guard let pip else { message = "Прокрути до предпросмотра и попробуй ещё раз"; return }
        if active { pip.stopPictureInPicture(); return }
        guard !pending else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            pending = true; message = "Проверяю готовность системного окна…"
            Task { @MainActor [weak self] in
                for _ in 0..<20 {
                    guard let self, self.pending else { return }
                    if pip.isPictureInPicturePossible {
                        self.pending = false; pip.startPictureInPicture(); return
                    }
                    try? await Task.sleep(for: .milliseconds(100))
                }
                self?.pending = false
                self?.message = "iOS не разрешила запуск. Проверь Настройки → Основные → Картинка в картинке."
            }
        } catch { message = "Не удалось запустить: \(error.localizedDescription)" }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in self.active = true; self.message = "Открой другое приложение. Если вокруг котика чёрный фон — iOS сохранила непрозрачную подложку." }
    }
    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in self.active = false }
    }
    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        let detail = error.localizedDescription
        Task { @MainActor in self.active = false; self.message = "iOS отклонила запуск: \(detail)" }
    }
    nonisolated func pictureInPictureController(_ controller: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}

final class CatProbeSurface: UIView {
    private let cat = CALayer()
    var becameVisible: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear; isOpaque = false
        layer.addSublayer(cat)
        cat.contentsGravity = .resizeAspect
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @MainActor func configure(_ pet: Pet) {
        let renderer = ImageRenderer(content: PixelCat(color: CatTheme.coats[pet.coat], hat: pet.hat).frame(width: 120, height: 110))
        renderer.scale = 2
        cat.contents = renderer.cgImage
        cat.contentsScale = 2
    }
    override func didMoveToWindow() { super.didMoveToWindow(); if window != nil { becameVisible?() } }
    override func layoutSubviews() {
        super.layoutSubviews()
        cat.bounds = CGRect(x: 0, y: 0, width: min(100, bounds.width * 0.45), height: min(95, bounds.height * 0.75))
        cat.position = CGPoint(x: bounds.midX, y: bounds.midY)
        let movement = CABasicAnimation(keyPath: "position.x")
        movement.fromValue = bounds.width * 0.28; movement.toValue = bounds.width * 0.72
        movement.duration = 3; movement.autoreverses = true; movement.repeatCount = .infinity
        cat.add(movement, forKey: "walk")
        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.fromValue = -2; bob.toValue = 2; bob.duration = 0.18; bob.autoreverses = true; bob.repeatCount = .infinity
        cat.add(bob, forKey: "bob")
    }
}

struct TransparentCatPreview: UIViewRepresentable {
    let probe: TransparentCatProbe
    let pet: Pet
    func makeUIView(context: Context) -> CatProbeSurface {
        let view = CatProbeSurface()
        view.configure(pet)
        view.becameVisible = { [weak view] in if let view { probe.attach(view, pet: pet) } }
        return view
    }
    func updateUIView(_ view: CatProbeSurface, context: Context) { view.configure(pet) }
}

struct TransparentCatCard: View {
    @ObservedObject var model: CatModel
    @StateObject private var probe = TransparentCatProbe()
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Без фона · эксперимент").font(.system(.headline, design: .rounded))
            TransparentCatPreview(probe: probe, pet: model.pet).frame(height: 110)
                .background(CatTheme.sage.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            Button { probe.toggle() } label: {
                Label(probe.active ? "Закрыть проверку" : "Проверить без фона", systemImage: "pip.enter")
                    .font(.system(size: 13, weight: .semibold)).padding(15).frame(maxWidth: .infinity)
                    .foregroundStyle(.white).background(CatTheme.rose, in: Capsule())
            }
            Text(probe.message).font(.system(size: 11)).foregroundStyle(.secondary)
            Text("Без джейлбрейка. Это проверка на устройстве, а не подтверждённый режим: рамка и движение окна остаются под управлением iOS.")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }.softCard()
    }
}
