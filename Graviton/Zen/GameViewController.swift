//  Created by Dominik Hauser on 22.12.21.
//

import UIKit
import SpriteKit
import GameplayKit
import ReplayKit
import Photos

class GameViewController: UIViewController {

  var gameScene: GameScene?
  private var pinchBaseScale: CGFloat = 1.0
  private var isFastForward = false
  private var isRecording = false
  private var recordingIndicator: UIView?

  var contentView: GameView { view as! GameView }
  private var onboardingOverlay: OnboardingOverlayView?

  override func loadView() {
    let contentView = GameView(frame: .zero)

    // Sun picker
    contentView.sunPickerView.button1.addTarget(self, action: #selector(sun1Tapped), for: .touchUpInside)
    contentView.sunPickerView.button2.addTarget(self, action: #selector(sun2Tapped), for: .touchUpInside)
    contentView.sunPickerView.button3.addTarget(self, action: #selector(sun3Tapped), for: .touchUpInside)

    // Round buttons
    contentView.speedButton.button.addTarget(self, action: #selector(fastForwardToggled), for: .touchUpInside)
    contentView.clearButton.button.addTarget(self, action: #selector(clear), for: .touchUpInside)
    contentView.infoButton.button.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

    // Capture (tap = screenshot, long press = video)
    contentView.captureButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(cameraLongPressed(_:)))
    contentView.captureButton.addGestureRecognizer(longPress)

    view = contentView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let skView = contentView.skView
    let scene  = GameScene()
    scene.scaleMode = .aspectFill
    scene.updateSatellitesHandler = { [weak self] _ in self?.updateCountLabel() }

    gameScene = scene
    skView.presentScene(scene)

    let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    skView.addGestureRecognizer(pinch)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if shouldShowOnboarding() {
      showOnboarding()
    } else {
      gameScene?.random(direction: .random)
    }
  }

  private func shouldShowOnboarding() -> Bool {
    !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
  }

  private func showOnboarding() {
    let overlay = OnboardingOverlayView(frame: view.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.onDismiss = { [weak self] in
      self?.onboardingOverlay = nil
      UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
      self?.gameScene?.random(direction: .random)
    }
    view.addSubview(overlay)
    onboardingOverlay = overlay
    overlay.startAnimation()
  }

  override var shouldAutorotate: Bool { true }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
  }
  override var prefersStatusBarHidden: Bool { true }
}

// MARK: - Actions
extension GameViewController {

  @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
    guard let scene = gameScene else { return }
    switch recognizer.state {
    case .began:
      scene.isPinching = true
      pinchBaseScale = scene.camera?.xScale ?? 1.0
    case .changed:
      scene.applyPinchScale(pinchBaseScale / recognizer.scale)
    case .ended, .cancelled, .failed:
      scene.isPinching = false
    default:
      break
    }
  }

  @objc func fastForwardToggled(_ sender: UIButton) {
    guard let gameScene else { return }
    isFastForward.toggle()
    gameScene.physicsWorld.speed = isFastForward ? 3 : 1
    for satellite in gameScene.children.compactMap({ $0 as? Satellite }) {
      for case let emitter as SKEmitterNode in satellite.children {
        emitter.particleBirthRate = isFastForward
          ? emitter.particleBirthRate * 3
          : emitter.particleBirthRate / 3
      }
    }
    contentView.speedButton.setActive(isFastForward)
  }

  @objc func infoTapped(_ sender: UIButton) {
    let infoVC = InfoSheetViewController()
    infoVC.modalPresentationStyle = .pageSheet
    if let sheet = infoVC.sheetPresentationController {
      sheet.detents = [.large()]
      sheet.prefersGrabberVisible = true
      sheet.preferredCornerRadius = 24
    }
    present(infoVC, animated: true)
  }

  @objc func sun1Tapped(_ sender: UIButton) { setSunCount(1) }
  @objc func sun2Tapped(_ sender: UIButton) { setSunCount(2) }
  @objc func sun3Tapped(_ sender: UIButton) { setSunCount(3) }

  private func setSunCount(_ count: Int) {
    guard let scene = gameScene else { return }
    contentView.sunPickerView.selectedIndex = count - 1
    scene.model.setNumberOfBlackHoles(to: count, in: scene)
  }

  @objc func clear(_ sender: UIButton) {
    guard let scene = gameScene else { return }
    for (index, satellite) in scene.model.satelliteNodes.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03 * Double(index)) {
        scene.model.remove(satellite, explosionIn: scene)
      }
    }
  }

  func updateCountLabel() {
    guard let gameScene else { return }
    let count = gameScene.model.satelliteNodes.count
    contentView.satellitesCountLabel.text = gameScene.model.mode == .spirograph
      ? "\(count)/10"
      : "\(count)"
  }

  func getScreenshot(scene: SKScene) -> UIImage? {
    guard let view = scene.view else { return nil }
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    return renderer.image { _ in
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
  }
}

// MARK: - Capture
extension GameViewController: RPPreviewViewControllerDelegate {

  @objc func cameraTapped(_ sender: UIButton) {
    isRecording ? stopVideoRecording() : takeScreenshot()
  }

  @objc func cameraLongPressed(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began, !isRecording else { return }
    startVideoRecording()
  }

  private func takeScreenshot() {
    guard let scene = gameScene, let image = getScreenshot(scene: scene) else { return }
    flashScreen()
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else { return }
      PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }
    }
  }

  private func startVideoRecording() {
    guard RPScreenRecorder.shared().isAvailable else { return }
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    RPScreenRecorder.shared().startRecording { [weak self] error in
      DispatchQueue.main.async {
        guard error == nil else { return }
        self?.isRecording = true
        self?.updateCaptureButton(recording: true)
        self?.showRecordingIndicator()
      }
    }
  }

  private func stopVideoRecording() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    RPScreenRecorder.shared().stopRecording { [weak self] previewVC, _ in
      DispatchQueue.main.async {
        self?.isRecording = false
        self?.updateCaptureButton(recording: false)
        self?.hideRecordingIndicator()
        if let previewVC = previewVC {
          previewVC.previewControllerDelegate = self
          self?.present(previewVC, animated: true)
        }
      }
    }
  }

  private func updateCaptureButton(recording: Bool) {
    var config = contentView.captureButton.configuration ?? .plain()
    config.image = UIImage(systemName: recording ? "stop.circle.fill" : "camera")?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    )
    config.baseForegroundColor = recording ? .systemRed : UIColor.white.withAlphaComponent(0.55)
    contentView.captureButton.configuration = config
  }

  private func flashScreen() {
    let flash = UIView(frame: view.bounds)
    flash.backgroundColor = .white
    flash.alpha = 0
    flash.isUserInteractionEnabled = false
    view.addSubview(flash)
    UIView.animate(withDuration: 0.08) { flash.alpha = 1 } completion: { _ in
      UIView.animate(withDuration: 0.28) { flash.alpha = 0 } completion: { _ in
        flash.removeFromSuperview()
      }
    }
  }

  private func showRecordingIndicator() {
    let dot = UIView()
    dot.backgroundColor = .systemRed
    dot.layer.cornerRadius = 6
    dot.translatesAutoresizingMaskIntoConstraints = false
    dot.isUserInteractionEnabled = false
    view.addSubview(dot)
    NSLayoutConstraint.activate([
      dot.centerYAnchor.constraint(equalTo: contentView.captureButton.centerYAnchor),
      dot.trailingAnchor.constraint(equalTo: contentView.captureButton.leadingAnchor, constant: -8),
      dot.widthAnchor.constraint(equalToConstant: 12),
      dot.heightAnchor.constraint(equalToConstant: 44),
    ])
    UIView.animate(withDuration: 0.7, delay: 0,
                   options: [.repeat, .autoreverse, .curveEaseInOut]) { dot.alpha = 0.2 }
    recordingIndicator = dot
  }

  private func hideRecordingIndicator() {
    recordingIndicator?.removeFromSuperview()
    recordingIndicator = nil
  }

  func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
    previewController.dismiss(animated: true)
  }
}
