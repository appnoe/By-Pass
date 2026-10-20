//  Created by Dominik Hauser on 22.12.21.
//
//

import SpriteKit

class GameScene: SKScene {

  let model = GravityModel()
  var isPinching: Bool = false
  var numberOfSatellites = 0
  var updateSatellitesHandler: ((Int) -> Void)?
  private var trajectoryNodes: [Int: SKShapeNode] = [:]
  private var lastUpdateTime: TimeInterval?

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

  // https://stackoverflow.com/a/31502698/498796
  override func update(_ currentTime: TimeInterval) {
    // Real frame time (60 or 120 Hz), clamped after pauses, scaled like the
    // SpriteKit physics so fast-forward affects all simulated motion equally.
    let frameTime = lastUpdateTime.map { currentTime - $0 } ?? 1.0/60.0
    lastUpdateTime = currentTime
    let dt = CGFloat(min(max(frameTime, 0), 1.0/30.0)) * physicsWorld.speed

    model.updateSunOrbit(dt: dt)

    if model.satelliteNodes.count != numberOfSatellites {
      updateSatellitesHandler?(model.satelliteNodes.count)
      numberOfSatellites = model.satelliteNodes.count
    }

    let strength: CGFloat = 10
    for node1 in model.satelliteNodes {
      let distance = sqrt(node1.position.x*node1.position.x+node1.position.y*node1.position.y)
      if distance > 3000 {
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

  func touchDown(_ touch: UITouch) {
    guard !isPinching else { return }
    let position = touch.location(in: self)
    let node = model.satellite(with: position, id: touch.hash)
    addChild(node)
  }

  func touchMoved(_ touch: UITouch) {
    let movePosition = touch.location(in: self)

    if let velocityNode = model.updateVelocity(id: touch.hash, input: movePosition) {
      insertChild(velocityNode, at: 0)
    }

    updateTrajectoryPreview(for: touch)
  }

  func touchUp(_ touch: UITouch) {
    let endPosition = touch.location(in: self)

    removeTrajectoryPreview(for: touch)
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
    for (_, node) in trajectoryNodes {
      node.removeFromParent()
    }
    trajectoryNodes.removeAll()
    model.cancelPendingSatellites()
  }

  // MARK: - Trajectory Preview

  private func updateTrajectoryPreview(for touch: UITouch) {
    trajectoryNodes[touch.hash]?.removeFromParent()

    guard !model.secondGravityNode.isEnabled else { return }
    guard let satellite = model.temporaryNodes[touch.hash] else { return }

    let input = touch.location(in: self)
    let velocityScale: CGFloat = 0.6
    let predictedVelocity = CGVector(
      dx: (satellite.position.x - input.x) * velocityScale,
      dy: (satellite.position.y - input.y) * velocityScale
    )

    let points = model.trajectoryPoints(from: satellite.position, velocity: predictedVelocity)
    guard points.count > 1 else { return }

    let path = CGMutablePath()
    path.move(to: points[0])
    for pt in points.dropFirst() {
      path.addLine(to: pt)
    }

    let node = SKShapeNode(path: path)
    node.strokeColor = .white
    node.alpha = 0.35
    node.lineWidth = 1.5
    node.lineCap = .round
    node.zPosition = 5
    insertChild(node, at: 0)
    trajectoryNodes[touch.hash] = node
  }

  private func removeTrajectoryPreview(for touch: UITouch) {
    trajectoryNodes[touch.hash]?.removeFromParent()
    trajectoryNodes.removeValue(forKey: touch.hash)
  }

  func setSimulationSpeed(_ speed: CGFloat) {
    physicsWorld.speed = speed
    model.simulationSpeed = speed
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

  func random(direction: Direction) {
    for node in model.random(size: size, direction: direction) {
      addChild(node)
    }
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
  }
}
