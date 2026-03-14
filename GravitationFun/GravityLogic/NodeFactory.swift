//  Created by Dominik Hauser on 01.01.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import SpriteKit

enum NodeFactory {
  static func center() -> SKShapeNode {
    let radius: CGFloat = 12

    // Outer glow ring
    let glowNode = SKShapeNode(circleOfRadius: radius * 2.2)
    glowNode.lineWidth = 0
    glowNode.fillColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.15)
    glowNode.zPosition = -1

    // Mid corona
    let coronaNode = SKShapeNode(circleOfRadius: radius * 1.5)
    coronaNode.lineWidth = 0
    coronaNode.fillColor = UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 0.35)

    // Core sun
    let node = SKShapeNode(circleOfRadius: radius)
    node.lineWidth = 0
    node.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)

    // Physics on the core
    node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = PhysicsCategory.center
    node.physicsBody?.contactTestBitMask = PhysicsCategory.satellite

    // Particle emitter for solar flares
    let emitter = SKEmitterNode()
    emitter.particleBirthRate = 60
    emitter.particleLifetime = 0.8
    emitter.particleLifetimeRange = 0.4
    emitter.particleSpeed = 18
    emitter.particleSpeedRange = 12
    emitter.emissionAngle = 0
    emitter.emissionAngleRange = .pi * 2
    emitter.particleScale = 0.06
    emitter.particleScaleRange = 0.04
    emitter.particleScaleSpeed = -0.05
    emitter.particleAlpha = 0.9
    emitter.particleAlphaRange = 0.1
    emitter.particleAlphaSpeed = -1.1
    emitter.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
    emitter.particleColorBlendFactor = 1.0
    emitter.particleBlendMode = .add
    emitter.particleColorSequence = SKKeyframeSequence(
      keyframeValues: [
        UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0),
        UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1.0),
        UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.0)
      ],
      times: [0, 0.4, 1.0]
    )

    // Pulsing animation on the glow
    let pulse = SKAction.sequence([
      SKAction.fadeAlpha(to: 0.25, duration: 0.9),
      SKAction.fadeAlpha(to: 0.08, duration: 0.9)
    ])
    glowNode.run(SKAction.repeatForever(pulse))

    node.addChild(glowNode)
    node.addChild(coronaNode)
    node.addChild(emitter)

    return node
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
