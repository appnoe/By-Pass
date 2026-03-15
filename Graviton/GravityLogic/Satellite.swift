//  Created by Dominik Hauser on 27.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import SpriteKit

public enum SatelliteType: Int {
  case box
  case rectangle
}

public enum Direction {
  case random
  case clockWise
  case counterClockWise
}

public class Satellite: SKShapeNode {

  public let radius: CGFloat = 8
  var colorRatio: CGFloat = 0
  private var planetType: PlanetType = .rocky
  private var spriteNode: SKSpriteNode?

  public override class var supportsSecureCoding: Bool {
    return true
  }

  class func random(amount: Int = 5, sceneSize: CGSize, type: SatelliteType, colorSetting: ColorSetting, direction: Direction) -> [Satellite] {
    var satellites: [Satellite] = []
    let clockWise: Bool
    switch direction {
      case .random:
        clockWise = Bool.random()
      case .clockWise:
        clockWise = true
      case .counterClockWise:
        clockWise = false
    }
    for _ in 0..<amount {
      let maxValue = sceneSize.width/2 - 10
      var randomX = CGFloat.random(in: 50..<maxValue)
      let randomYVelocity = CGFloat.random(in: 50..<180)
      if clockWise {
        randomX *= -1
      }
      let position = CGPoint(x: randomX, y: 0)

      let satellite = Satellite(position: position)
      let randomXVelocity = CGFloat.random(in: -40...40)
      let length = sqrt(pow(randomXVelocity, 2) + pow(randomYVelocity, 2))
      satellite.colorRatio = min(length/150, 0.9)
      satellite.updateColor(for: colorSetting)
      let velocity = CGVector(dx: randomXVelocity, dy: randomYVelocity)
      satellite.addPhysicsBody(with: velocity)

      satellites.append(satellite)
    }
    return satellites
  }

  init(position: CGPoint) {
    super.init()

    // Invisible shape for physics (transparent, no stroke)
    path = CGPath(ellipseIn: .init(x: 0, y: 0, width: radius * 2, height: radius * 2), transform: nil)
    lineWidth = 0
    fillColor = .clear

    self.position = position
    zPosition = 20

    // Pick a random planet type and build the textured sprite
    planetType = PlanetType.random()
    applyPlanetTexture()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  private func applyPlanetTexture() {
    spriteNode?.removeFromParent()
    let baseColor: UIColor
    switch planetType {
    case .rocky: baseColor = UIColor(red: 0.55, green: 0.50, blue: 0.42, alpha: 1)
    case .lava:  baseColor = UIColor(red: 0.55, green: 0.10, blue: 0.02, alpha: 1)
    case .gas:   baseColor = UIColor(red: 0.90, green: 0.68, blue: 0.38, alpha: 1)
    case .ocean: baseColor = UIColor(red: 0.10, green: 0.42, blue: 0.72, alpha: 1)
    case .icy:   baseColor = UIColor(white: 0.88, alpha: 1)
    }
    let texture = NodeFactory.planetTexture(type: planetType, radius: radius, baseColor: baseColor)
    let sprite = SKSpriteNode(texture: texture, size: CGSize(width: radius * 2, height: radius * 2))
    sprite.position = CGPoint(x: radius, y: radius)
    sprite.zPosition = 1
    addChild(sprite)
    spriteNode = sprite

    // Slow self-rotation for all planet types
    sprite.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi * 2, duration: Double.random(in: 12...28))))
  }

  func addColor(forInput input: CGPoint, colorSetting: ColorSetting) {
    let length = sqrt(pow(input.x - position.x, 2) + pow(input.y - position.y, 2))
    colorRatio = min(length/150, 0.9)
    updateColor(for: colorSetting)
  }

  func updateColor(for colorSetting: ColorSetting) {
    // In multiColor mode: tint the planet sprite; in B&W: desaturate
    switch colorSetting {
    case .multiColor:
      spriteNode?.color = UIColor(hue: colorRatio, saturation: 0.55, brightness: 1.0, alpha: 1)
      spriteNode?.colorBlendFactor = 0.25
    case .blackAndWhite:
      spriteNode?.color = UIColor(white: colorRatio, alpha: 1)
      spriteNode?.colorBlendFactor = 0.6
    }
    let trailColor = UIColor(hue: colorRatio, saturation: 0.8, brightness: 1.0, alpha: 1)
    let emitters = children.compactMap({ $0 as? SKEmitterNode })
    for emitter in emitters {
      emitter.particleColor = trailColor
    }
  }

  func addPhysicsBody(with velocity: CGVector) {
    self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    physicsBody?.friction = 0
    physicsBody?.linearDamping = 0
    physicsBody?.angularDamping = 0
    physicsBody?.categoryBitMask = PhysicsCategory.satellite
    physicsBody?.contactTestBitMask = PhysicsCategory.center
    physicsBody?.velocity = velocity
    physicsBody?.mass = 10
  }

  func addEmitter(emitterBox: SKEmitterNode?) {

        guard let emitterCopy = emitterBox?.copy() as? SKEmitterNode else {
          return
        }

    // Center the emitter on the planet sprite
    emitterCopy.position = CGPoint(x: radius, y: radius)

    // Use the current tint color from the sprite, falling back to a visible default
    let trailColor: UIColor
    if let sprite = spriteNode, sprite.colorBlendFactor > 0 {
      trailColor = sprite.color
    } else {
      trailColor = UIColor(hue: colorRatio, saturation: 0.8, brightness: 1.0, alpha: 1)
    }
    emitterCopy.particleColor = trailColor
        addChild(emitterCopy)
  }
}
