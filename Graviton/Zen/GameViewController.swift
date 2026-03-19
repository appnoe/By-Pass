//  Created by Dominik Hauser on 22.12.21.
//  

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

  var gameScene: GameScene?
  private var pinchBaseScale: CGFloat = 1.0
  private var isFastForward = false
  var contentView: GameView {
    return view as! GameView
  }
  private var onboardingOverlay: OnboardingOverlayView?

  override func loadView() {
    let contentView = GameView(frame: .zero)

    let menu = contentView.radialMenu

    menu.onFastForwardToggled = { [weak self] in
      self?.fastForwardToggled()
    }

    menu.onClearTapped = { [weak self] in
      self?.clear()
    }

    menu.onSunCountChanged = { [weak self] count in
      self?.setSunCount(count)
    }

    menu.onInfoTapped = { [weak self] in
      self?.infoTapped()
    }

    view = contentView
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let view = self.contentView.skView
    let scene = GameScene()
    scene.scaleMode = .aspectFill

    scene.updateSatellitesHandler = { [weak self] _ in
      self?.updateCountLabel()
    }

    gameScene = scene
    view.presentScene(scene)

    let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    view.addGestureRecognizer(pinch)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if shouldShowOnboarding() {
      showOnboarding()
    } else {
      // Start with a random configuration
      gameScene?.random(direction: .random)
    }
  }

  private func shouldShowOnboarding() -> Bool {
    return !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
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
    return UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
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
      // scale down as user spreads fingers (inverse: pinch out → zoom in → smaller camera scale)
      let newScale = pinchBaseScale / recognizer.scale
      scene.applyPinchScale(newScale)

    case .ended, .cancelled, .failed:
      scene.isPinching = false

    default:
      break
    }
  }

  func fastForwardToggled() {
    guard let gameScene else { return }
    isFastForward.toggle()
    let speed: CGFloat = isFastForward ? 3 : 1
    gameScene.physicsWorld.speed = speed
    for satellite in gameScene.children.compactMap({ $0 as? Satellite }) {
      for case let emitter as SKEmitterNode in satellite.children {
        emitter.particleBirthRate = isFastForward
          ? emitter.particleBirthRate * 3
          : emitter.particleBirthRate / 3
      }
    }
    contentView.radialMenu.isFastForwardOn = isFastForward
  }

  func infoTapped() {
    let infoVC = InfoSheetViewController()
    infoVC.modalPresentationStyle = .pageSheet
    if let sheet = infoVC.sheetPresentationController {
      sheet.detents = [.large()]
      sheet.prefersGrabberVisible = true
      sheet.preferredCornerRadius = 24
    }
    present(infoVC, animated: true)
  }

  private func setSunCount(_ count: Int) {
    guard let scene = gameScene else { return }
    contentView.radialMenu.selectedSunCount = count
    scene.model.setNumberOfBlackHoles(to: count, in: scene)
  }

  func clear() {
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
    let text: String
    switch gameScene.model.mode {
      case .gravity:    text = "\(count)"
      case .spirograph: text = "\(count)/10"
    }
    contentView.satellitesCountLabel.text = text
  }

  func getScreenshot(scene: SKScene) -> UIImage? {
    guard let view = scene.view else { return nil }
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    return renderer.image { _ in
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
  }
}
