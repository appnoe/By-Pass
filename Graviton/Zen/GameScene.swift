//  Created by Dominik Hauser on 22.12.21.
//  
//

import SpriteKit
import GameplayKit
import OSLog

class GameScene: SKScene {

  let model = GravityModel()
  var zoomValue: CGFloat = 1.0
  var isPinching: Bool = false
  var numberOfSatellites = 0
  var updateSatellitesHandler: ((Int) -> Void)?
  override class var supportsSecureCoding: Bool {
    return true
  }

  override init() {
    super.init(size: CGSize(width: 750, height: 1334))

    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    physicsWorld.gravity = .zero
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func didMove(to view: SKView) {
    physicsWorld.contactDelegate = self

    model.setup(scene: self)

    let cameraNode = SKCameraNode()
    addChild(cameraNode)
    camera = cameraNode

    if nil == model.musicAudioNode {
      let musicAudioNode = SKAudioNode(fileNamed: "gravity.m4a")
      model.addSound(node: musicAudioNode)
    }

    backgroundColor = .black
  }

  class func loadScene(from data: Data) -> GameScene? {
    let scene: GameScene?

    do {
      if let savedScene = try NSKeyedUnarchiver.unarchivedObject(ofClass: GameScene.self, from: data) {
        scene = savedScene
      } else {
        scene = nil
      }
    } catch {
      scene = nil
    }

    return scene
  }

  // https://stackoverflow.com/a/31502698/498796
  override func update(_ currentTime: TimeInterval) {
    if model.satelliteNodes.count != numberOfSatellites {
      updateSatellitesHandler?(model.satelliteNodes.count)
      numberOfSatellites = model.satelliteNodes.count
    }

    if model.mode == .gravity {
      let strength: CGFloat = 10
      let dt: CGFloat = 1.0/60.0

      // Binary star orbit: apply mutual gravity between the two suns
      if model.binaryOrbitActive,
         let body1 = model.center.physicsBody,
         let body2 = model.secondCenter.physicsBody {
        let disp = CGVector(
          dx: model.secondCenter.position.x - model.center.position.x,
          dy: model.secondCenter.position.y - model.center.position.y
        )
        let dist = sqrt(disp.dx*disp.dx + disp.dy*disp.dy)
        if dist > 1 {
          let m1 = body1.mass * strength
          let m2 = body2.mass * strength
          let force = (m1 * m2) / (dist * dist)
          let normal = CGVector(dx: disp.dx/dist, dy: disp.dy/dist)
          let impulse = CGVector(dx: normal.dx*force*dt, dy: normal.dy*force*dt)
          body1.velocity = CGVector(dx: body1.velocity.dx + impulse.dx, dy: body1.velocity.dy + impulse.dy)
          body2.velocity = CGVector(dx: body2.velocity.dx - impulse.dx, dy: body2.velocity.dy - impulse.dy)
        }

        // Keep gravity field nodes synced to moving suns so satellites are attracted correctly
        model.gravityNode.position = model.center.position
        model.secondGravityNode.position = model.secondCenter.position
      }

      // Satellite–satellite gravity
      for node1 in model.satelliteNodes {
        let distance = sqrt(node1.position.x*node1.position.x+node1.position.y*node1.position.y)
        if distance > 3000 {
          print("distance: \(distance), removing")
          model.clear(nodes: [node1])
          continue
        }
        for node2 in model.satelliteNodes {
          guard let body1 = node1.physicsBody, let body2 = node2.physicsBody else {
            continue
          }
          let m1 = body1.mass * strength
          let m2 = body2.mass * strength
          let disp = CGVector(dx: node2.position.x-node1.position.x, dy: node2.position.y-node1.position.y)
          let radius = sqrt(disp.dx*disp.dx+disp.dy*disp.dy)
          if radius < node1.radius*1.3 { //Radius lower-bound.
            continue
          }
          let force = (m1*m2)/(radius*radius)
          let normal = CGVector(dx: disp.dx/radius, dy: disp.dy/radius)
          let impulse = CGVector(dx: normal.dx*force*dt, dy: normal.dy*force*dt)

          body1.velocity = CGVector(dx: body1.velocity.dx + impulse.dx, dy: body1.velocity.dy + impulse.dy)
        }
      }
    }
  }

  func touchDown(_ touch: UITouch) {
    guard !isPinching else { return }
    let logger = Logger(subsystem: "GravityFun", category: "GameScene")
    logger.info("\(touch)")
    if model.mode == .spirograph,
       model.satelliteNodes.count > 9 {
      return
    }
    let position = touch.location(in: self)
    let node = model.satellite(with: position, id: touch.hash)
    addChild(node)
  }

  func touchMoved(_ touch: UITouch) {

    let movePosition = touch.location(in: self)

    if let velocityNode = model.updateVelocity(id: touch.hash, input: movePosition) {
      insertChild(velocityNode, at: 0)
    }
  }

  func touchUp(_ touch: UITouch) {

    let endPosition = touch.location(in: self)

    model.addVelocityToSatellite(id: touch.hash, input: endPosition)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let totalTouches = event?.allTouches?.count ?? touches.count
    if totalTouches >= 2 {
      // Two or more fingers — this is a pinch. Remove any nodes that were
      // created by the first finger before the gesture recognizer fired.
      cancelAllPendingSatellites()
      isPinching = true
      return
    }
    for touch in touches {
      touchDown(touch)
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isPinching else { return }
    for touch in touches {
      touchMoved(touch)
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard !isPinching else { return }
    for touch in touches {
      touchUp(touch)
    }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    isPinching = false
    for touch in touches {
      touchUp(touch)
    }
  }

  private func cancelAllPendingSatellites() {
    // Remove satellite nodes that have no velocity yet (still being placed)
    let pending = model.satelliteNodes.filter {
      $0.physicsBody?.velocity == .zero
    }
    model.clear(nodes: pending)
  }

  func setTrailLength(to length: TrailLength) {
    model.trailLength = length
  }

  func zoom(to zoomValue: CGFloat) {
    self.zoomValue = zoomValue
    let zoomInAction = SKAction.scale(to: 1-(zoomValue-1), duration: 0.3)
    camera?.run(zoomInAction)
  }

  /// Called continuously during a pinch gesture with the cumulative scale.
  func applyPinchScale(_ scale: CGFloat) {
    let clamped = max(0.25, min(scale, 4.0))
    camera?.setScale(clamped)
  }

  func setSound(enabled: Bool) {
    if enabled {
      model.enableSound()
      if let sound = model.sound() {
        addChild(sound)
      }
    } else {
      model.disableSound()
    }
  }

  func setSatelliteType(_ type: SatelliteType) {
    model.currentSatelliteType = type
  }

  func setColorSetting(_ setting: ColorSetting) {
    model.colorSetting = setting
  }

  func random(direction: Direction) {
    let (nodes, _) = model.random(size: size, direction: direction)
    for node in nodes {
      addChild(node)
    }
  }

  func clear() {
    model.clear()
  }

  func fire() {
    let projectile = model.projectile(size: size)
    addChild(projectile)
  }
}

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {

    if contact.bodyA.categoryBitMask == PhysicsCategory.satellite {
      if let node = contact.bodyA.node {
        model.remove(node, explosionIn: self)
      }
    } else if contact.bodyB.categoryBitMask == PhysicsCategory.satellite {
      if let node = contact.bodyB.node {
        model.remove(node, explosionIn: self)
      }
    }
    if contact.bodyA.categoryBitMask == PhysicsCategory.projectile {
      if let node = contact.bodyA.node {
        node.removeFromParent()
      }
    } else if contact.bodyB.categoryBitMask == PhysicsCategory.projectile {
      if let node = contact.bodyB.node {
        node.removeFromParent()
      }
    }
  }
}
