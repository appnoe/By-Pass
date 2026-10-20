//  Created by Dominik Hauser on 02.01.22.
//
//

import SpriteKit

@MainActor
public class GravityModel {
  public var satelliteNodes: [Satellite] = []
  var temporaryNodes: [Int:Satellite] = [:]
  var velocityNodes: [Int:SKShapeNode] = [:]
  let emitterForBox: SKEmitterNode
  public var backgroundEmitter: SKNode?
  let explosionEmitter: SKEmitterNode
  public private(set) var gravityNode: SKFieldNode
  public private(set) var secondGravityNode: SKFieldNode
  public private(set) var thirdGravityNode: SKFieldNode

  public private(set) var center: SKShapeNode
  public private(set) var secondCenter: SKShapeNode
  public private(set) var thirdCenter: SKShapeNode

  public var musicAudioNode: SKAudioNode?

  /// Upper bound for planets: their mutual attraction costs O(n²) per frame.
  static let maxSatellites = 50

  // Sun orbit (two-body / Lagrange equilateral-triangle solution).
  // The suns rotate rigidly around the origin with the angular velocity of
  // the analytic circular-orbit solution. Integrating them numerically would
  // let the (inherently unstable) triangle drift apart over time.
  private let sunOrbitStrength: CGFloat = 73_000
  private var sunStartPositions: [CGPoint] = []
  private var sunPositions: [CGPoint] = []
  private var sunAngularVelocity: CGFloat = 0
  private var sunAngle: CGFloat = 0
  var soundEnabled = true

  /// Fast-forward factor; trail emitters scale their birth rate along with it
  /// so that trails keep their density. New emitters are copies of
  /// `emitterForBox` and therefore inherit the current rate.
  public var simulationSpeed: CGFloat = 1 {
    didSet {
      emitterForBox.particleBirthRate = baseParticleBirthRate * simulationSpeed
      for node in satelliteNodes {
        for case let emitter as SKEmitterNode in node.children {
          emitter.particleBirthRate = emitterForBox.particleBirthRate
        }
      }
    }
  }
  private let baseParticleBirthRate: CGFloat

  // MARK: - Setup
  public init() {
    let boxEmitter = BoxEmitter()
    emitterForBox = boxEmitter
    baseParticleBirthRate = boxEmitter.particleBirthRate
    explosionEmitter = ExplosionEmitter()
    gravityNode = SKFieldNode.radialGravityField()

    secondGravityNode = SKFieldNode.radialGravityField()
    secondGravityNode.isEnabled = false

    thirdGravityNode = SKFieldNode.radialGravityField()
    thirdGravityNode.isEnabled = false

    center = NodeFactory.center()

    secondCenter = NodeFactory.center()
    secondCenter.isHidden = true

    thirdCenter = NodeFactory.center()
    thirdCenter.isHidden = true
  }

  public func setup(scene: SKScene) {
    emitterForBox.targetNode = scene

    backgroundEmitter = NodeFactory.backgroundEmitter(size: scene.size)
    if let backgroundEmitter = backgroundEmitter {
      scene.addChild(backgroundEmitter)
    }
    center.position = .init(x: 4, y: 4)
    scene.addChild(center)
    gravityNode.falloff = 2.0
    scene.addChild(gravityNode)

    secondGravityNode.falloff = 2.0
    secondGravityNode.isEnabled = false
    scene.addChild(secondGravityNode)

    thirdGravityNode.falloff = 2.0
    thirdGravityNode.isEnabled = false
    scene.addChild(thirdGravityNode)
  }

  public func addSound(node: SKAudioNode) {
    musicAudioNode = node
  }

  func setNumberOfBlackHoles(to number: Int, in scene: SKScene) {
    let distance: CGFloat = 224
    switch number {
      case 2:
        // Two-body circular orbit (CW): both suns on the x-axis, equal speed
        // v = √(G / 2d) on radius d/2
        let v2 = sqrt(sunOrbitStrength / (2 * distance))
        startSunOrbit(at: [
          CGPoint(x: -distance/2, y: 0),
          CGPoint(x:  distance/2, y: 0)
        ], angularVelocity: -v2 / (distance / 2))

        center.position      = sunPositions[0]
        gravityNode.position = sunPositions[0]

        secondGravityNode.isEnabled = true
        secondGravityNode.position  = sunPositions[1]
        if nil == secondCenter.parent { scene.addChild(secondCenter) }
        secondCenter.isHidden = false
        secondCenter.position = sunPositions[1]

        thirdGravityNode.isEnabled = false
        thirdCenter.isHidden = true
        thirdCenter.removeFromParent()
      case 3:
        // Lagrange equilateral-triangle solution: three suns orbit their common
        // centre of mass. Side length = distance, circumradius R = distance/√3.
        let R = distance / sqrt(3.0)
        let v = sqrt(sunOrbitStrength / distance)   // orbital speed (px/s)

        // Equilateral triangle centred at (0,0), CW rotation
        startSunOrbit(at: [
          CGPoint(x: 0,          y:  R),
          CGPoint(x: -distance/2, y: -R/2),
          CGPoint(x:  distance/2, y: -R/2)
        ], angularVelocity: -v / R)

        center.position         = sunPositions[0]
        gravityNode.position    = sunPositions[0]

        secondGravityNode.isEnabled = true
        secondGravityNode.position  = sunPositions[1]
        if nil == secondCenter.parent { scene.addChild(secondCenter) }
        secondCenter.isHidden  = false
        secondCenter.position  = sunPositions[1]

        thirdGravityNode.isEnabled = true
        thirdGravityNode.position  = sunPositions[2]
        if nil == thirdCenter.parent { scene.addChild(thirdCenter) }
        thirdCenter.isHidden  = false
        thirdCenter.position  = sunPositions[2]
      default:
        startSunOrbit(at: [], angularVelocity: 0)
        secondGravityNode.isEnabled = false
        secondCenter.isHidden = true
        secondCenter.removeFromParent()

        thirdGravityNode.isEnabled = false
        thirdCenter.isHidden = true
        thirdCenter.removeFromParent()

        gravityNode.position = .init(x: 4, y: 4)
        center.position = .init(x: 4, y: 4)
    }
  }

  // MARK: - Satellites
  public func satellite(with position: CGPoint, id: Int) -> SKNode {
    let node = Satellite(position: position)
    satelliteNodes.append(node)
    temporaryNodes[id] = node
    return node
  }

  /// Removes all satellites that are still being placed (no velocity yet),
  /// e.g. when a second finger turns the touch into a pinch.
  public func cancelPendingSatellites() {
    clear(nodes: Array(temporaryNodes.values))
  }

  /// Drops placement state (touch mapping, velocity indicator) of a satellite
  /// that leaves the scene.
  private func forgetPlacement(of satellite: Satellite) {
    for (id, node) in temporaryNodes where node == satellite {
      temporaryNodes.removeValue(forKey: id)
      velocityNodes.removeValue(forKey: id)?.removeFromParent()
    }
  }

  public func remove(_ node: SKNode, explosionIn target: SKScene) {
    guard let satellite = node as? Satellite else {
      return
    }
    satelliteNodes.removeAll(where: { $0 == satellite })
    forgetPlacement(of: satellite)

    if satelliteNodes.count < 1 {
      musicAudioNode?.removeFromParent()
    }

    explosion(at: satellite.position, inNode: target)
    satellite.removeFromParent()
  }

  // MARK: - Sound

  public func sound() -> SKAudioNode? {
    guard let musicAudioNode = musicAudioNode,
          musicAudioNode.parent == nil,
          soundEnabled,
          satelliteNodes.count > 0
    else {
      return nil
    }
    musicAudioNode.autoplayLooped = true
    musicAudioNode.isPositional = false
    musicAudioNode.run(SKAction.changeVolume(to: 0.5, duration: 0))
    return musicAudioNode
  }

  public func enableSound() {
    soundEnabled = true
  }

  public func disableSound() {
    musicAudioNode?.removeFromParent()
    soundEnabled = false
  }

  // MARK: - Velocity

  public func updateVelocity(id: Int, input: CGPoint) -> SKNode? {
    if let velocityNode = velocityNodes[id] {
      velocityNode.removeFromParent()
    }

    guard let satellite = temporaryNodes[id] else {
      return nil
    }

    satellite.addColor(forInput: input)

    let correctedPosition = CGPoint(x: satellite.position.x + satellite.radius, y: satellite.position.y + satellite.radius)
    let velocityNode = NodeFactory.velocity(from: correctedPosition, to: input)
    velocityNodes[id] = velocityNode
    return velocityNode
  }

  public func addVelocityToSatellite(id: Int, input: CGPoint) {
    if let velocityNode = velocityNodes[id] {
      velocityNode.removeFromParent()
    }

    velocityNodes.removeValue(forKey: id)

    guard let satellite = temporaryNodes.removeValue(forKey: id) else {
      return
    }

    let position = satellite.position
    let velocityScale: CGFloat = 0.6
    let velocity = CGVector(dx: (position.x - input.x) * velocityScale, dy: (position.y - input.y) * velocityScale)
    satellite.addPhysicsBody(with: velocity)
    satellite.addEmitter(emitterBox: emitterForBox)
  }

  // MARK: - Emitter

  func explosion(at position: CGPoint, inNode node: SKNode) {
    guard let emitter = explosionEmitter.copy() as? SKEmitterNode else { return }
    emitter.position = position
    node.addChild(emitter)
    emitter.run(.sequence([.wait(forDuration: 1), .removeFromParent()]))
  }

  // MARK: - Sun orbit

  private func startSunOrbit(at positions: [CGPoint], angularVelocity: CGFloat) {
    sunStartPositions = positions
    sunPositions = positions
    sunAngularVelocity = angularVelocity
    sunAngle = 0
  }

  /// Advances the orbiting suns by `dt` seconds of simulation time.
  /// Call once per frame; updates both visual nodes and gravity-field positions.
  public func updateSunOrbit(dt: CGFloat) {
    let n = sunStartPositions.count
    guard n >= 2 else { return }

    sunAngle = (sunAngle + sunAngularVelocity * dt).truncatingRemainder(dividingBy: 2 * .pi)
    let rotation = CGAffineTransform(rotationAngle: sunAngle)
    sunPositions = sunStartPositions.map { $0.applying(rotation) }

    // Sync visual and field nodes to the new positions
    center.position      = sunPositions[0]
    gravityNode.position = sunPositions[0]
    secondCenter.position      = sunPositions[1]
    secondGravityNode.position = sunPositions[1]
    if n >= 3 {
      thirdCenter.position      = sunPositions[2]
      thirdGravityNode.position = sunPositions[2]
    }
  }

  // MARK: - Trajectory Preview

  // SpriteKit default: 150 pts/meter; radialGravityField strength=1 → a = 1/r_m² m/s²
  // In pts/s²: a = 150³ / r_pts² = 3_375_000 / r_pts²
  private static let gravityStrength: CGFloat = 3_375_000

  func activeSunPositions() -> [CGPoint] {
    var positions = [gravityNode.position]
    if secondGravityNode.isEnabled { positions.append(secondGravityNode.position) }
    if thirdGravityNode.isEnabled  { positions.append(thirdGravityNode.position) }
    return positions
  }

  func trajectoryPoints(
    from startPosition: CGPoint,
    velocity startVelocity: CGVector,
    steps: Int = 360,
    dt: CGFloat = 1.0 / 60.0
  ) -> [CGPoint] {
    let suns = activeSunPositions()
    var pos = startPosition
    var vel = startVelocity
    var points = [CGPoint]()
    points.reserveCapacity(steps)

    for _ in 0..<steps {
      var ax: CGFloat = 0
      var ay: CGFloat = 0

      for sunPos in suns {
        let dx = sunPos.x - pos.x
        let dy = sunPos.y - pos.y
        let r2 = dx * dx + dy * dy
        guard r2 > 200 else { return points }
        let r = sqrt(r2)
        let a = GravityModel.gravityStrength / r2
        ax += (dx / r) * a
        ay += (dy / r) * a
      }

      vel.dx += ax * dt
      vel.dy += ay * dt
      pos.x  += vel.dx * dt
      pos.y  += vel.dy * dt

      guard pos.x * pos.x + pos.y * pos.y < 3000 * 3000 else { break }
      points.append(pos)
    }

    return points
  }

  // MARK: - Misc

  public var canAddSatellite: Bool {
    satelliteNodes.count < GravityModel.maxSatellites
  }

  public func random(size: CGSize, direction: Direction) -> [Satellite] {
    let free = GravityModel.maxSatellites - satelliteNodes.count
    guard free > 0 else { return [] }
    let satellites = Satellite.random(amount: min(5, free), sceneSize: size, direction: direction)
    for satellite in satellites {
      satellite.addEmitter(emitterBox: emitterForBox)
    }
    self.satelliteNodes.append(contentsOf: satellites)
    return satellites
  }

  public func clear(nodes: [Satellite]? = nil) {
    let satellitesToRemove = nodes ?? satelliteNodes
    for node in satellitesToRemove {
      node.removeFromParent()
      satelliteNodes.removeAll(where: { node == $0 })
      forgetPlacement(of: node)
    }
    if satelliteNodes.count < 1 {
      musicAudioNode?.removeFromParent()
    }
  }
}
