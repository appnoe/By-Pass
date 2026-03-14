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
      for node1 in model.satelliteNodes {
        let distance = sqrt(node1.position.x*node1.position.x+node1.position.y*node1.position.y)
        if distance > 6000 {
          print("distance: \(distance), removing")
          model.clear(nodes: [node1])
          continue
        }
        for node2 in model.satelliteNodes {
          if nil == node1.physicsBody || nil == node2.physicsBody {
            continue
          }
          let m1 = node1.physicsBody!.mass*strength
          let m2 = node2.physicsBody!.mass*strength
          let disp = CGVector(dx: node2.position.x-node1.position.x, dy: node2.position.y-node1.position.y)
          let radius = sqrt(disp.dx*disp.dx+disp.dy*disp.dy)
          if radius < node1.radius*1.3 { //Radius lower-bound.
            continue
          }
          let force = (m1*m2)/(radius*radius);
          let normal = CGVector(dx: disp.dx/radius, dy: disp.dy/radius)
          let impulse = CGVector(dx: normal.dx*force*dt, dy: normal.dy*force*dt)

          // Don't move static bodies (e.g. the solar-system sun stand-in)
          guard node1.physicsBody!.isDynamic else { continue }
          node1.physicsBody!.velocity = CGVector(dx: node1.physicsBody!.velocity.dx + impulse.dx, dy: node1.physicsBody!.velocity.dy + impulse.dy)
        }
      }
    }
  }

  func touchDown(_ touch: UITouch) {
    guard !isPinching else { return }
    let logger = Logger(subsystem: "GravityFun", category: "GameScene")
    logger.info("\(touch)")
    NSLog("%@", touch)
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

  func setStars(enabled: Bool) {
    if enabled, let stars = model.stars() {
      insertChild(stars, at: 0)
    } else {
      model.disableStars()
    }
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

  /// Spawns the 8 planets of our solar system on stable circular orbits
  /// around the central gravity node (the Sun).
  func solarSystem() {
    // Physics in this engine (N-Body custom loop, update() method):
    //   Δv = (m1_eff * m2_eff / r²) * dt,  where m_eff = physicsBody.mass * strength (strength=10)
    //
    // For a stable circular orbit around a central mass M_sun:
    //   v = sqrt(m_planet_eff * M_sun_eff / r)
    //     = sqrt((10*10) * (M_sun*10) / r)
    //     = sqrt(1000 * M_sun / r)
    //
    // We want Earth's orbital period ≈ 20 s at r_earth = 150 pt:
    //   v_earth = 2π*150 / (20*60) ≈ 0.785 pt/frame
    //   0.785² = 1000 * M_sun / 150  →  M_sun ≈ 0.092
    //
    // We use M_sun = 0.1 for a clean round number:
    //   v_earth = sqrt(1000 * 0.1 / 150) ≈ 0.816 pt/frame  (period ≈ 19 s)
    //
    // Scale: 1 AU = 150 scene points (Earth at 150 pt from centre).

    let au: CGFloat = 150   // scene points per AU
    let mSun: CGFloat = 0.1 // physics mass of the static sun node

    // --- Add a hidden static sun satellite so the N-Body loop has a central mass ---
    // The visual sun (model.center) is already on screen. We add a physics satellite
    // at the origin with the desired mass. addPhysicsBody() must be called first to
    // create the SKPhysicsBody, then we override its properties.
    let sunSatellite = Satellite(position: .zero, type: .rocky)
    sunSatellite.name = "solarSun"
    sunSatellite.addPhysicsBody(with: .zero)       // creates SKPhysicsBody with mass=10
    sunSatellite.physicsBody?.mass = mSun          // override to desired sun mass
    sunSatellite.physicsBody?.isDynamic = false     // the sun doesn't move
    sunSatellite.physicsBody?.affectedByGravity = false
    sunSatellite.physicsBody?.fieldBitMask = 0
    sunSatellite.physicsBody?.categoryBitMask = 0  // no collision contacts
    sunSatellite.physicsBody?.contactTestBitMask = 0
    sunSatellite.isHidden = true                   // the visual sun is already there
    model.satelliteNodes.append(sunSatellite)
    addChild(sunSatellite)

    struct PlanetDef {
      let name: String
      let au: CGFloat        // semi-major axis in AU
      let type: PlanetType
      let colorRatio: CGFloat
      let radius: CGFloat    // visual & physics radius in scene points
    }

    let planets: [PlanetDef] = [
      PlanetDef(name: "Mercury", au:  0.387, type: .rocky,  colorRatio: 0.05, radius:  4),
      PlanetDef(name: "Venus",   au:  0.723, type: .lava,   colorRatio: 0.12, radius:  6),
      PlanetDef(name: "Earth",   au:  1.000, type: .ocean,  colorRatio: 0.55, radius:  6),
      PlanetDef(name: "Mars",    au:  1.524, type: .rocky,  colorRatio: 0.02, radius:  5),
      PlanetDef(name: "Jupiter", au:  5.203, type: .gas,    colorRatio: 0.10, radius: 14),
      PlanetDef(name: "Saturn",  au:  9.537, type: .icy,    colorRatio: 0.60, radius: 12),
      PlanetDef(name: "Uranus",  au: 19.19,  type: .ocean,  colorRatio: 0.48, radius: 10),
      PlanetDef(name: "Neptune", au: 30.07,  type: .ocean,  colorRatio: 0.62, radius: 10),
    ]

    // Scale up the visual sun so it looks proportional in the solar system view.
    model.center.setScale(3.0)

    // Zoom camera out to show inner solar system (Mercury–Jupiter) at launch.
    // Camera scale 0.35 → visible width = 750/0.35 ≈ 2140 pt, showing up to ~7 AU.
    camera?.setScale(0.35)

    for planet in planets {
      let r = planet.au * au
      // Orbital velocity: v = sqrt(m_planet_eff * m_sun_eff / r)
      //   m_planet_eff = planet.mass * strength = 10 * 10 = 100
      //   m_sun_eff    = mSun * strength = mSun * 10
      let speed = sqrt(100.0 * mSun * 10.0 / r)

      // Place planet at (r, 0) with upward velocity for CCW orbit.
      let position = CGPoint(x: r, y: 0)
      let satellite = Satellite(position: position, type: planet.type, radius: planet.radius)
      satellite.name = planet.name
      satellite.colorRatio = planet.colorRatio
      satellite.updateColor(for: model.colorSetting)
      satellite.addPhysicsBody(with: CGVector(dx: 0, dy: speed))
      // Disable SKFieldNode and world gravity; only the custom N-Body loop applies.
      satellite.physicsBody?.affectedByGravity = false
      satellite.physicsBody?.fieldBitMask = 0

      if model.trailLength != .none {
        satellite.addEmitter(emitterBox: model.emitterForBox)
      }
      model.satelliteNodes.append(satellite)
      addChild(satellite)
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
