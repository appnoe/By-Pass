//  Created by Dominik Hauser on 02.01.22.
//  
//

import SpriteKit

public class GravityModel {
  public var satelliteNodes: [Satellite] = []
  var temporaryNodes: [Int:Satellite] = [:]
  var velocityNodes: [Int:SKShapeNode] = [:]
  let emitterForBox: SKEmitterNode
  public var backgroundEmitter: SKNode?
  var explosionEmitter: SKEmitterNode?
  public private(set) var gravityNode: SKFieldNode
  public private(set) var secondGravityNode: SKFieldNode
  public private(set) var thirdGravityNode: SKFieldNode

  public private(set) var center: SKShapeNode
  public private(set) var secondCenter: SKShapeNode
  public private(set) var thirdCenter: SKShapeNode

  public var currentSatelliteType: SatelliteType = .box
  public var musicAudioNode: SKAudioNode?

  // Sun orbit: the 2-sun circle and the 3-sun Lagrange triangle are both
  // rigid rotations about the common centre of mass, so they are evaluated
  // analytically instead of being integrated (which drifts and, for the
  // Lagrange triangle, is unstable).
  private let sunOrbitStrength: CGFloat = 73_000
  private var sunBasePositions: [CGPoint] = []
  private var sunAngularVelocity: CGFloat = 0
  private var sunAngle: CGFloat = 0
  var sunPositions: [CGPoint] { sunBasePositions.map { rotated($0, by: sunAngle) } }

  // Trail particles are emitted in real time, so the birth rate has to follow
  // the simulation speed to keep the trails dense in fast-forward.
  private let baseTrailBirthRate: CGFloat
  public var speedMultiplier: CGFloat = 1 {
    didSet {
      emitterForBox.particleBirthRate = baseTrailBirthRate * speedMultiplier
      for node in satelliteNodes {
        for case let emitter as SKEmitterNode in node.children {
          emitter.particleBirthRate = emitterForBox.particleBirthRate
        }
      }
    }
  }
  var soundEnabled = true
  public var mode: GravityMode = .gravity {
    didSet {
      gravityNode.falloff = mode.falloff
      secondGravityNode.falloff = mode.falloff
      thirdGravityNode.falloff = mode.falloff
      trailLength = mode.trailLength
    }
  }
  public var trailLength: TrailLength = .long {
    didSet {
      setEmitter(enabled: false)

      emitterForBox.particleLifetime = trailLength.lifetime()

      switch trailLength {
        case .none:
          break
        case .short, .long, .spirograph:
          setEmitter(enabled: true)
      }
    }
  }
  public var particleScale: ParticleScale = .normal {
    didSet {
      setEmitter(enabled: false)
      emitterForBox.particleScale = particleScale.value
      setEmitter(enabled: true)
    }
  }
  public var colorSetting: ColorSetting = .multiColor {
    didSet {
      for node in satelliteNodes {
        node.updateColor(for: colorSetting)
      }
    }
  }

  // MARK: - Setup
  public init() {
    emitterForBox = BoxEmitter()
    baseTrailBirthRate = emitterForBox.particleBirthRate
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

    if scene.children.filter({ $0 is Satellite }).count < 1 {
      backgroundEmitter = NodeFactory.backgroundEmitter(size: scene.size)
      if let backgroundEmitter = backgroundEmitter {
        scene.addChild(backgroundEmitter)
      }
      center = NodeFactory.center()
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

    } else if let gravityNode = scene.children.first(where: { $0 is SKFieldNode }) as? SKFieldNode {
      self.gravityNode = gravityNode
    }

    for child in scene.children {
      if let satellite = child as? Satellite {
        satelliteNodes.append(satellite)
      } else if let emitter = child as? SKEmitterNode, emitter.name == "background" {
        backgroundEmitter = emitter  // legacy: plain emitter without crop mask
      } else if let audio = child as? SKAudioNode {
        musicAudioNode = audio
      }
    }
  }

  public func addSound(node: SKAudioNode) {
    musicAudioNode = node
  }

  func setNumberOfBlackHoles(to number: Int, in scene: SKScene) {
    let distance: CGFloat = 224
    switch number {
      case 2:
        // Two-body circular orbit (CW): both suns on the x-axis, equal speed
        let v2 = sqrt(sunOrbitStrength / (2 * distance))
        sunBasePositions = [
          CGPoint(x: -distance/2, y: 0),
          CGPoint(x:  distance/2, y: 0)
        ]
        sunAngle = 0
        sunAngularVelocity = -v2 / (distance/2)
        let sunPositions = self.sunPositions

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
        sunBasePositions = [
          CGPoint(x: 0,          y:  R),
          CGPoint(x: -distance/2, y: -R/2),
          CGPoint(x:  distance/2, y: -R/2)
        ]
        sunAngle = 0
        sunAngularVelocity = -v / R
        let sunPositions = self.sunPositions

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
        sunBasePositions = []
        sunAngle = 0
        sunAngularVelocity = 0
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

  public func setColorOfSatelliteWith(id: Int, forInput input: CGPoint) {
    let node = temporaryNodes[id]
    node?.addColor(forInput: input, colorSetting: colorSetting)
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

    satellite.addColor(forInput: input, colorSetting: colorSetting)

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

    // Once launched, the satellite is no longer being placed.
    guard let satellite = temporaryNodes.removeValue(forKey: id) else {
      return
    }

    let position = satellite.position
    let velocityScale: CGFloat = 0.6
    let velocity = CGVector(dx: (position.x - input.x) * velocityScale, dy: (position.y - input.y) * velocityScale)
    satellite.addPhysicsBody(with: velocity)

    if trailLength != .none {
      satellite.addEmitter(emitterBox: emitterForBox)
    }
  }

  // MARK: - Emitter

  func setEmitter(enabled: Bool) {

    for node in satelliteNodes {
      if enabled {
        node.addEmitter(emitterBox: emitterForBox)
      } else {
        let allEmitter = node.children.filter { $0 is SKEmitterNode }
        for emitter in allEmitter {
          emitter.removeFromParent()
        }
      }
    }
  }

  func explosion(at position: CGPoint, inNode node: SKNode) {
    let emitter = explosionEmitter?.copy() as? SKEmitterNode
    emitter?.position = position
    if let emitter = emitter {
      node.addChild(emitter)
      emitter.run(SKAction.sequence([.wait(forDuration: 1), .removeFromParent()]))
    }
  }

  // MARK: - Projectile

  public func projectile(size: CGSize) -> SKNode {
    let projectile = SKSpriteNode(color: .white, size: CGSize(width: 5, height: 5))
    projectile.position = CGPoint(x: 0, y: -floor(size.height/2)+30)
    projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
    projectile.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
    projectile.physicsBody?.affectedByGravity = false
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.center | PhysicsCategory.satellite
    return projectile
  }

  // MARK: - Sun orbit

  /// Advances the orbiting suns by `dt` seconds of simulation time.
  /// Call once per frame; updates both visual nodes and gravity-field positions.
  public func updateSunOrbit(dt: CGFloat) {
    guard sunBasePositions.count >= 2 else { return }

    sunAngle = (sunAngle + sunAngularVelocity * dt).truncatingRemainder(dividingBy: 2 * .pi)
    let positions = sunPositions

    center.position      = positions[0]
    gravityNode.position = positions[0]
    secondCenter.position      = positions[1]
    secondGravityNode.position = positions[1]
    if positions.count >= 3 {
      thirdCenter.position      = positions[2]
      thirdGravityNode.position = positions[2]
    }
  }

  private func rotated(_ point: CGPoint, by angle: CGFloat) -> CGPoint {
    let c = cos(angle)
    let s = sin(angle)
    return CGPoint(x: point.x * c - point.y * s, y: point.x * s + point.y * c)
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

  public func random(size: CGSize, direction: Direction) -> (nodes: [SKNode], sound: SKAudioNode?) {
    let satellites = Satellite.random(sceneSize: size, type: currentSatelliteType, colorSetting: colorSetting, direction: direction)
    for satellite in satellites {
      if trailLength != .none {
        satellite.addEmitter(emitterBox: emitterForBox)
      }
      satellite.physicsBody?.linearDamping = 0.0
    }
    self.satelliteNodes.append(contentsOf: satellites)
    return (nodes: satellites, sound: sound())
  }

  /// Removes all satellites that are still being placed (touch down, not yet
  /// launched) together with their velocity indicators.
  public func cancelPendingSatellites() {
    let pending = Array(temporaryNodes.values)
    clear(nodes: pending)
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

  private func forgetPlacement(of satellite: Satellite) {
    for (id, node) in temporaryNodes where node == satellite {
      temporaryNodes.removeValue(forKey: id)
      velocityNodes.removeValue(forKey: id)?.removeFromParent()
    }
  }
}
