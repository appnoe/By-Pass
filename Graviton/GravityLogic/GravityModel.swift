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

  /// True while the 2-sun binary orbit mode is active.
  public private(set) var binaryOrbitActive: Bool = false

  /// The currently active sun nodes (1, 2, or 3 depending on mode).
  public var activeSunNodes: [SKShapeNode] {
    if thirdCenter.parent != nil && !thirdCenter.isHidden {
      return [center, secondCenter, thirdCenter]
    } else if secondCenter.parent != nil && !secondCenter.isHidden {
      return [center, secondCenter]
    } else {
      return [center]
    }
  }

  public var currentSatelliteType: SatelliteType = .box
  public var musicAudioNode: SKAudioNode?
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
        secondGravityNode.isEnabled = true
        secondGravityNode.position = .init(x: distance/2, y: 4)
        if nil == secondCenter.parent {
          scene.addChild(secondCenter)
        }
        secondCenter.isHidden = false
        secondCenter.position = .init(x: distance/2, y: 4)

        gravityNode.position = .init(x: -distance/2, y: 4)
        center.position = .init(x: -distance/2, y: 4)

        thirdGravityNode.isEnabled = false
        thirdCenter.isHidden = true
        thirdCenter.removeFromParent()

        // Enable binary orbit: make suns dynamic and set tangential velocities
        binaryOrbitActive = true
        let sunMass: CGFloat = 50.0
        center.physicsBody?.isDynamic = true
        center.physicsBody?.mass = sunMass
        center.physicsBody?.linearDamping = 0
        center.physicsBody?.angularDamping = 0
        center.physicsBody?.affectedByGravity = false
        center.physicsBody?.collisionBitMask = 0  // no physical bounce-back from satellites
        secondCenter.physicsBody?.isDynamic = true
        secondCenter.physicsBody?.mass = sunMass
        secondCenter.physicsBody?.linearDamping = 0
        secondCenter.physicsBody?.angularDamping = 0
        secondCenter.physicsBody?.affectedByGravity = false
        secondCenter.physicsBody?.collisionBitMask = 0

        // Circular orbit velocity: v = sqrt(F * r) where F = (m*str)^2 / d^2
        // With m=50, str=10, d=224, r=112 → v ≈ 23.6 pts/s
        let str: CGFloat = 10.0
        let m = sunMass * str
        let force = (m * m) / (distance * distance)
        let orbitalV = sqrt(force * (distance / 2))

        // Left sun (negative x) moves downward; right sun moves upward → CCW orbit
        center.physicsBody?.velocity = CGVector(dx: 0, dy: -orbitalV)
        secondCenter.physicsBody?.velocity = CGVector(dx: 0, dy: orbitalV)

      case 3:
        binaryOrbitActive = false
        // Restore suns to static for 3-body mode
        center.physicsBody?.isDynamic = false
        center.physicsBody?.velocity = .zero
        center.physicsBody?.collisionBitMask = PhysicsCategory.satellite
        secondCenter.physicsBody?.isDynamic = false
        secondCenter.physicsBody?.velocity = .zero
        secondCenter.physicsBody?.collisionBitMask = PhysicsCategory.satellite
        thirdCenter.physicsBody?.isDynamic = false
        thirdCenter.physicsBody?.velocity = .zero
        thirdCenter.physicsBody?.collisionBitMask = PhysicsCategory.satellite

        let xPos = sqrt((distance * distance) - (distance * distance/4))/2
        secondGravityNode.isEnabled = true
        secondGravityNode.position = .init(x: xPos, y: distance/2)

        if nil == secondCenter.parent {
          scene.addChild(secondCenter)
        }
        secondCenter.isHidden = false
        secondCenter.position = .init(x: xPos, y: distance/2)

        gravityNode.position = .init(x: -xPos, y: 4)
        center.position = .init(x: -xPos, y: 4)

        thirdGravityNode.isEnabled = true
        thirdGravityNode.position = .init(x: xPos, y: -distance/2)

        if nil == thirdCenter.parent {
          scene.addChild(thirdCenter)
        }
        thirdCenter.isHidden = false
        thirdCenter.position = .init(x: xPos, y: -distance/2)
      default:
        binaryOrbitActive = false
        // Restore sun to static for single-sun mode
        center.physicsBody?.isDynamic = false
        center.physicsBody?.velocity = .zero
        center.physicsBody?.mass = 1.0
        center.physicsBody?.collisionBitMask = PhysicsCategory.satellite

        secondGravityNode.isEnabled = false
        secondCenter.isHidden = true
        secondCenter.removeFromParent()
        secondCenter.physicsBody?.isDynamic = false
        secondCenter.physicsBody?.velocity = .zero
        secondCenter.physicsBody?.collisionBitMask = PhysicsCategory.satellite

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

    guard let satellite = temporaryNodes[id] else {
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        emitter.removeFromParent()
      }
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

  public func clear(nodes: [Satellite]? = nil) {
    let satellitesToRemove = nodes ?? satelliteNodes
    for node in satellitesToRemove {
      node.removeFromParent()
      satelliteNodes.removeAll(where: { node == $0 })
    }
    if satelliteNodes.count < 1 {
      musicAudioNode?.removeFromParent()
    }
  }
}
