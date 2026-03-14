//  Created by Dominik Hauser on 22.12.21.
//  

import UIKit
import SpriteKit
import GameplayKit
import StoreKit

class GameViewController: UIViewController {

  var gameScene: GameScene?
  var contentView: GameView {
    return view as! GameView
  }

  override func loadView() {
    let contentView = GameView(frame: UIScreen.main.bounds)

    let tabBar = contentView.bottomTabBar
    tabBar.fastForwardButton.addTarget(self, action: #selector(fastForwardTouchDown), for: .touchDown)
    tabBar.fastForwardButton.addTarget(self, action: #selector(fastForwardTouchUp), for: .touchUpInside)
    tabBar.fastForwardButton.addTarget(self, action: #selector(fastForwardTouchUp), for: .touchUpOutside)
    tabBar.trashButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
    tabBar.sun1Button.addTarget(self, action: #selector(sun1Tapped), for: .touchUpInside)
    tabBar.sun2Button.addTarget(self, action: #selector(sun2Tapped), for: .touchUpInside)
    tabBar.sun3Button.addTarget(self, action: #selector(sun3Tapped), for: .touchUpInside)
    tabBar.starsButton.addTarget(self, action: #selector(starsTapped), for: .touchUpInside)

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

  @objc func fastForwardTouchDown(_ sender: UIButton) {
    guard let gameScene else { return }
    gameScene.physicsWorld.speed = 3
    for satellite in gameScene.children.compactMap({ $0 as? Satellite }) {
      for case let emitter as SKEmitterNode in satellite.children {
        emitter.particleBirthRate *= 3
      }
    }
  }

  @objc func fastForwardTouchUp(_ sender: UIButton) {
    guard let gameScene else { return }
    gameScene.physicsWorld.speed = 1
    for satellite in gameScene.children.compactMap({ $0 as? Satellite }) {
      for case let emitter as SKEmitterNode in satellite.children {
        emitter.particleBirthRate /= 3
      }
    }
  }

  @objc func starsTapped(_ sender: UIButton) {
    let tabBar = contentView.bottomTabBar
    tabBar.isStarsOn.toggle()
    gameScene?.setStars(enabled: tabBar.isStarsOn)
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
    let bounds = view.bounds
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
    view.drawHierarchy(in: bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
