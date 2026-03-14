//  Created by Dominik Hauser on 01.01.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import SpriteKit

enum NodeFactory {
  static func center() -> SKShapeNode {
    let radius: CGFloat = 14

    // --- Core sun body ---
    let node = SKShapeNode(circleOfRadius: radius)
    node.lineWidth = 0
    node.fillColor = UIColor(red: 1.0, green: 0.97, blue: 0.75, alpha: 1.0)

    node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = PhysicsCategory.center
    node.physicsBody?.contactTestBitMask = PhysicsCategory.satellite

    // --- Inner hot corona (tight bright ring) ---
    let innerCorona = SKShapeNode(circleOfRadius: radius * 1.25)
    innerCorona.lineWidth = 0
    innerCorona.fillColor = UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 0.45)
    node.addChild(innerCorona)

    // --- Outer soft glow ---
    let outerGlow = SKShapeNode(circleOfRadius: radius * 2.4)
    outerGlow.lineWidth = 0
    outerGlow.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.12)
    node.addChild(outerGlow)

    // Pulse outer glow
    outerGlow.run(SKAction.repeatForever(SKAction.sequence([
      SKAction.fadeAlpha(to: 0.20, duration: 1.1),
      SKAction.fadeAlpha(to: 0.06, duration: 1.1)
    ])))

    // --- Surface shimmer: tight radial sparks hugging the sun ---
    let shimmer = NodeFactory.makeSunEmitter(
      birthRate: 80,
      speed: 6,
      speedRange: 4,
      lifetime: 0.5,
      lifetimeRange: 0.3,
      scale: 0.10,
      positionRange: CGVector(dx: radius * 1.8, dy: radius * 1.8),
      colors: [
        (UIColor(red: 1.0, green: 1.0, blue: 0.85, alpha: 1.0), 0.0),
        (UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.8), 0.5),
        (UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.0), 1.0)
      ]
    )
    node.addChild(shimmer)

    // --- Flames: medium arcs rising from the surface ---
    let flames = NodeFactory.makeSunEmitter(
      birthRate: 30,
      speed: 28,
      speedRange: 16,
      lifetime: 1.0,
      lifetimeRange: 0.5,
      scale: 0.18,
      positionRange: CGVector(dx: radius * 1.6, dy: radius * 1.6),
      colors: [
        (UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0), 0.0),
        (UIColor(red: 1.0, green: 0.5, blue: 0.05, alpha: 0.9), 0.4),
        (UIColor(red: 0.9, green: 0.15, blue: 0.0, alpha: 0.0), 1.0)
      ]
    )
    // Slight upward drift simulates buoyancy
    flames.xAcceleration = 0
    flames.yAcceleration = 8
    node.addChild(flames)

    // --- Protuberances: sporadic tall jets ---
    // Spawn 4 protuberance emitters at fixed angles around the rim
    let protuberanceAngles: [CGFloat] = [CGFloat.pi/4, CGFloat.pi*3/4, CGFloat.pi*5/4, CGFloat.pi*7/4]
    for angle in protuberanceAngles {
      let prot = NodeFactory.makeProtuberance(radius: radius, angle: angle)
      node.addChild(prot)
    }

    // Slowly rotate protuberance ring to make it feel alive
    let rotateAction = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 18))
    // We wrap all protuberances in a container node so rotation doesn't affect physics
    let protContainer = SKNode()
    for child in node.children.filter({ $0.name == "prot" }) {
      child.removeFromParent()
      protContainer.addChild(child)
    }
    protContainer.run(rotateAction)
    node.addChild(protContainer)

    return node
  }

  // MARK: - Sun helper emitters

  private static func makeSunEmitter(
    birthRate: CGFloat,
    speed: CGFloat,
    speedRange: CGFloat,
    lifetime: CGFloat,
    lifetimeRange: CGFloat,
    scale: CGFloat,
    positionRange: CGVector,
    colors: [(UIColor, CGFloat)]
  ) -> SKEmitterNode {
    let e = SKEmitterNode()
    e.particleBirthRate = birthRate
    e.particleLifetime = lifetime
    e.particleLifetimeRange = lifetimeRange
    e.particleSpeed = speed
    e.particleSpeedRange = speedRange
    e.emissionAngle = 0
    e.emissionAngleRange = .pi * 2
    e.particleScale = scale
    e.particleScaleRange = scale * 0.4
    e.particleScaleSpeed = -scale * 0.6
    e.particleAlpha = 1.0
    e.particleAlphaSpeed = -1.0 / lifetime
    e.particleBlendMode = .add
    e.particleColorBlendFactor = 1.0
    e.particlePositionRange = positionRange
    e.particleColorSequence = SKKeyframeSequence(
      keyframeValues: colors.map { $0.0 },
      times: colors.map { NSNumber(value: Double($0.1)) }
    )
    return e
  }

  private static func makeProtuberance(radius: CGFloat, angle: CGFloat) -> SKEmitterNode {
    let e = SKEmitterNode()
    e.name = "prot"
    e.particleBirthRate = 12
    e.particleLifetime = 1.4
    e.particleLifetimeRange = 0.6
    // Emit outward along the given angle
    e.emissionAngle = angle
    e.emissionAngleRange = .pi / 7     // narrow jet
    e.particleSpeed = 40
    e.particleSpeedRange = 20
    // Start position on the sun rim
    e.position = CGPoint(
      x: cos(angle) * radius,
      y: sin(angle) * radius
    )
    e.particleScale = 0.20
    e.particleScaleRange = 0.08
    e.particleScaleSpeed = -0.12
    e.particleAlpha = 1.0
    e.particleAlphaSpeed = -0.7
    e.particleBlendMode = .add
    e.particleColorBlendFactor = 1.0
    // Gravity bends the jet back inward like a real prominence
    e.xAcceleration = -cos(angle) * 25
    e.yAcceleration = -sin(angle) * 25
    e.particleColorSequence = SKKeyframeSequence(
      keyframeValues: [
        UIColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 1.0),
        UIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 0.9),
        UIColor(red: 0.8, green: 0.1, blue: 0.0, alpha: 0.0)
      ],
      times: [0, 0.45, 1.0]
    )
    return e
  }

  static func backgroundEmitter(size: CGSize) -> SKEmitterNode? {
    let node = SKEmitterNode(fileNamed: "background")
    node?.particlePositionRange = CGVector(dx: size.width*1.5, dy: size.height*1.5)
    node?.particleLifetime = CGFloat.greatestFiniteMagnitude
    return node
  }

  static func velocity(from: CGPoint, to: CGPoint) -> SKShapeNode {
    let bezierPath = UIBezierPath()
    bezierPath.move(to: from)
    bezierPath.addLine(to: to)
    let node = SKShapeNode(path: bezierPath.cgPath)
    node.strokeColor = .systemGray
    node.lineWidth = 1
    return node
  }
}
