//  Created by Dominik Hauser on 22.12.21.
//  

import UIKit
import SpriteKit
import GameplayKit
import StoreKit

class GameViewController: UIViewController {

  var gameScene: GameScene?
  private var pinchBaseScale: CGFloat = 1.0
  private var isFastForward = false
  var contentView: GameView {
    return view as! GameView
  }

  override func loadView() {
    let contentView = GameView(frame: .zero)

    let tabBar = contentView.bottomTabBar
    tabBar.fastForwardButton.addTarget(self, action: #selector(fastForwardToggled), for: .touchUpInside)
    tabBar.trashButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
    tabBar.sun1Button.addTarget(self, action: #selector(sun1Tapped), for: .touchUpInside)
    tabBar.sun2Button.addTarget(self, action: #selector(sun2Tapped), for: .touchUpInside)
    tabBar.sun3Button.addTarget(self, action: #selector(sun3Tapped), for: .touchUpInside)
    tabBar.infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

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

    // Start with a random configuration
    gameScene?.random(direction: .random)
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

  @objc func fastForwardToggled(_ sender: UIButton) {
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
    contentView.bottomTabBar.isFastForwardOn = isFastForward
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
    contentView.bottomTabBar.selectedSunIndex = count - 1
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
    let text: String
    switch gameScene.model.mode {
      case .gravity:    text = "\(count)"
      case .spirograph: text = "\(count)/10"
    }
    contentView.satellitesCountLabel.text = text
    disableRandomButtonsIfNeeded()
  }

  func disableRandomButtonsIfNeeded() {
    // No random buttons in tab bar yet — placeholder for future use
  }

  func getScreenshot(scene: SKScene) -> UIImage? {
    guard let view = scene.view else { return nil }
    let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
    return renderer.image { _ in
      view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    }
  }
}
