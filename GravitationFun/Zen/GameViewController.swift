//  Created by Dominik Hauser on 22.12.21.
//  
//

import UIKit
import SpriteKit
import GameplayKit
import Combine
import StoreKit

let closeSettingsNotificationName = Notification.Name(rawValue: "closeSettingsNotification")

class GameViewController: UIViewController {

  var gameScene: GameScene?
  var token: AnyCancellable?
  var contentView: GameView {
    return view as! GameView
  }

  override func loadView() {
    let contentView = GameView(frame: UIScreen.main.bounds)

    let settingsView = contentView.settingsView
    settingsView.showHideButton.addTarget(self, action: #selector(toggleSettings), for: .touchUpInside)
    settingsView.starsSwitch.addTarget(self, action: #selector(toggleStars), for: .valueChanged)
    settingsView.blackHolesControl.addTarget(self, action: #selector(blackHoles), for: .valueChanged)
    settingsView.shareImageButton.addTarget(self, action: #selector(shareImage), for: .touchUpInside)
    settingsView.clockWiseButton.addTarget(self, action: #selector(clockWiseRandom), for: .touchUpInside)
    settingsView.randomButton.addTarget(self, action: #selector(random), for: .touchUpInside)
    settingsView.counterClockWiseButton.addTarget(self, action: #selector(counterClockWiseRandom), for: .touchUpInside)
    settingsView.clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
    settingsView.colorControl.addTarget(self, action: #selector(changeColor), for: .valueChanged)
//    settingsView.trailLengthControl.addTarget(self, action: #selector(changeTrailLength), for: .valueChanged)
//    settingsView.trailThicknessControl.addTarget(self, action: #selector(changeTrailThickness), for: .valueChanged)

    contentView.zoomStepper.addTarget(self, action: #selector(zoomChanged), for: .valueChanged)
    contentView.fastForwardButton.addTarget(self, action: #selector(fastForwardTouchDown), for: .touchDown)
    contentView.fastForwardButton.addTarget(self, action: #selector(fastForwardTouchUp), for: .touchUpInside)
    contentView.fastForwardButton.addTarget(self, action: #selector(fastForwardTouchUp), for: .touchUpOutside)

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

    token = NotificationCenter.default
      .publisher(for: closeSettingsNotificationName, object: nil)
      .sink { [weak self] _ in
        self?.contentView.hideSettingsIfNeeded()
      }
  }

  deinit {
    token?.cancel()
    token = nil
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    random(contentView.settingsView.randomButton)
  }

  override var shouldAutorotate: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return .allButUpsideDown
    } else {
      return .all
    }
  }

}

// MARK: - Actions
extension GameViewController {
  @objc func zoomChanged(_ sender: UIStepper) {
    if let zoomValue = gameScene?.zoomValue {
      if abs(sender.value - 0.25) < 0.01 {
        if zoomValue > 0.25 {
          sender.stepValue = 0.05
        } else {
          sender.stepValue = 0.25
        }
      }
    }
    contentView.zoomLabel.text = String(format: "%ld", Int(sender.value * 100)) + "%"
    gameScene?.zoom(to: sender.value)
  }

  @objc func fastForwardTouchDown(_ sender: UIButton) {
    guard let gameScene = gameScene else {
      return
    }
    gameScene.physicsWorld.speed = 3
//    gameScene?.setTrailLength(to: .none)
    for satellite in gameScene.children.filter({ $0 is Satellite }) {
      for emitter in satellite.children where emitter is SKEmitterNode {
        guard let emitter = emitter as? SKEmitterNode else {
          return
        }
        emitter.particleBirthRate *= 3
      }
    }
  }

  @objc func fastForwardTouchUp(_ sender: UIButton) {
    guard let gameScene = gameScene else {
      return
    }
    gameScene.physicsWorld.speed = 1
//    let selectedTrailLengthIndex = contentView.settingsView.trailLengthControl.selectedSegmentIndex
//    guard let length = TrailLength(rawValue: selectedTrailLengthIndex) else {
//      return
//    }
//    gameScene?.setTrailLength(to: length)
    for satellite in gameScene.children.filter({ $0 is Satellite }) {
      for emitter in satellite.children where emitter is SKEmitterNode {
        guard let emitter = emitter as? SKEmitterNode else {
          return
        }
        emitter.particleBirthRate /= 3
      }
    }
  }

  @objc func toggleSettings(_ sender: UIButton) {
    contentView.toggleSettings()
  }

  @objc func toggleStars(_ sender: UISwitch) {
    gameScene?.setStars(enabled: sender.isOn)
  }

  @objc func toggleGravityField(_ sender: UISwitch) {
    gameScene?.model.gravityNode.isEnabled.toggle()
  }

  @objc func changeTrailLength(_ sender: UISegmentedControl) {
    guard let length = TrailLength(rawValue: sender.selectedSegmentIndex) else {
      return
    }
    gameScene?.setTrailLength(to: length)
  }

  @objc func changeTrailThickness(_ sender: UISegmentedControl) {
    guard let particleScale = ParticleScale(rawValue: sender.selectedSegmentIndex) else {
      return
    }
    gameScene?.model.particleScale = particleScale
  }

  @objc func toggleSound(_ sender: UISwitch) {
    gameScene?.setSound(enabled: sender.isOn)

  }

  @objc func blackHoles(_ sender: UISegmentedControl) {
    guard let scene = gameScene else {
      return
    }

    scene.model.setNumberOfBlackHoles(to: sender.selectedSegmentIndex + 1, in: scene)
  }

  @objc func changeColor(_ sender: UISegmentedControl) {
    guard let colorSetting = ColorSetting(rawValue: sender.selectedSegmentIndex) else {
      return
    }
    gameScene?.setColorSetting(colorSetting)
  }

  @objc func random(_ sender: UIButton) {
    guard let gameScene = gameScene else {
      return
    }
    gameScene.random(direction: .random)
  }

  @objc func clockWiseRandom(_ sender: UIButton) {
    guard let gameScene = gameScene else {
      return
    }
    gameScene.random(direction: .clockWise)
  }

  @objc func counterClockWiseRandom(_ sender: UIButton) {
    guard let gameScene = gameScene else {
      return
    }
    gameScene.random(direction: .counterClockWise)
  }

  func disableRandomButtonsIfNeeded() {
    if let gameScene, 
        gameScene.model.satelliteNodes.count > 100 {
      contentView.settingsView.randomButton.isEnabled = false
      contentView.settingsView.clockWiseButton.isEnabled = false
      contentView.settingsView.counterClockWiseButton.isEnabled = false
    } else {
      contentView.settingsView.randomButton.isEnabled = true
      contentView.settingsView.clockWiseButton.isEnabled = true
      contentView.settingsView.counterClockWiseButton.isEnabled = true
    }
  }

  func updateCountLabel() {
    guard let gameScene = gameScene else {
      return
    }
    let text: String
    let count = gameScene.model.satelliteNodes.count
    switch gameScene.model.mode {
      case .gravity:
        text = "\(count)"
      case .spirograph:
        text = "\(count)/10"
    }
    contentView.satellitesCountLabel.text = text
    disableRandomButtonsIfNeeded()
  }

  @objc func shareImage(_ sender: UIButton) {
    guard let scene = gameScene else {
      return
    }
    guard let image = getScreenshot(scene: scene) else {
      return
    }
    let settingsView = contentView.settingsView
    let activity = UIActivityViewController(activityItems: [image, "#GravityZenApp"], applicationActivities: nil)
    activity.completionWithItemsHandler = { _, _, _, _ in
      if let scene = self.view.window?.windowScene {
        SKStoreReviewController.requestReview(in: scene)
      }
    }
    activity.popoverPresentationController?.sourceView = settingsView.shareImageButton
    self.present(activity, animated: true)
  }

  @objc func clear(_ sender: UIButton) {
    guard let scene = gameScene else {
      return
    }
    for (index, satellite) in scene.model.satelliteNodes.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.03 * Double(index)) {
        scene.model.remove(satellite, explosionIn: scene)
      }
    }
//    gameScene?.clear()
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  func getScreenshot(scene: SKScene) -> UIImage? {
    guard let view = scene.view else {
      return nil
    }

    let bounds = view.bounds

    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

    view.drawHierarchy(in: bounds, afterScreenUpdates: true)

    let screenshotImage = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()

    return screenshotImage
  }
}
