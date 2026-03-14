//  Created by Dominik Hauser on 01.01.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import SpriteKit
import CoreGraphics
import UIKit

enum NodeFactory {
  static func center() -> SKShapeNode {
    let radius: CGFloat = 28

    // --- Invisible physics anchor ---
    let node = SKShapeNode(circleOfRadius: radius)
    node.lineWidth = 0
    node.fillColor = .clear
    node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = PhysicsCategory.center
    node.physicsBody?.contactTestBitMask = PhysicsCategory.satellite

    // --- 1. Outer diffuse glow (large soft bloom) ---
    let glowEffect = SKEffectNode()
    glowEffect.shouldRasterize = true
    glowEffect.blendMode = .add
    if let blur = CIFilter(name: "CIGaussianBlur") {
      blur.setValue(18.0, forKey: kCIInputRadiusKey)
      glowEffect.filter = blur
    }
    let glowLayers: [(mult: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [
      (4.0, 1.0, 0.35, 0.00, 0.18),
      (3.0, 1.0, 0.50, 0.00, 0.30),
      (2.1, 1.0, 0.65, 0.05, 0.50),
      (1.5, 1.0, 0.80, 0.15, 0.75),
    ]
    for l in glowLayers {
      let c = SKShapeNode(circleOfRadius: radius * l.mult)
      c.lineWidth = 0
      c.fillColor = UIColor(red: l.r, green: l.g, blue: l.b, alpha: l.a)
      glowEffect.addChild(c)
    }
    glowEffect.run(SKAction.repeatForever(SKAction.sequence([
      SKAction.fadeAlpha(to: 0.80, duration: 1.6),
      SKAction.fadeAlpha(to: 1.00, duration: 1.6)
    ])))
    node.addChild(glowEffect)

    // --- 2. Sun disk with procedural texture (gradient + granulation) ---
    let texSize = CGSize(width: radius * 2 + 4, height: radius * 2 + 4)
    let sunTexture = NodeFactory.makeSunTexture(radius: radius, size: texSize)
    let sunSprite = SKSpriteNode(texture: sunTexture)
    sunSprite.blendMode = .alpha
    node.addChild(sunSprite)

    // Slow rotation of the disk (solar rotation ~25 days, speed up for fun)
    sunSprite.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi * 2, duration: 22)))

    // --- 3. Bright limb ring (edge brightening like real solar limb) ---
    let limb = SKShapeNode(circleOfRadius: radius)
    limb.lineWidth = 2.5
    limb.strokeColor = UIColor(red: 1.0, green: 0.90, blue: 0.55, alpha: 0.9)
    limb.fillColor = .clear
    limb.glowWidth = 6
    node.addChild(limb)

    // --- 4. Corona ray emitter ---
    let corona = NodeFactory.makeSunEmitter(
      birthRate: 55,
      speed: 50,
      speedRange: 30,
      lifetime: 1.2,
      lifetimeRange: 0.6,
      scale: 0.22,
      positionRange: CGVector(dx: radius * 1.85, dy: radius * 1.85),
      colors: [
        (UIColor(red: 1.0, green: 1.0, blue: 0.80, alpha: 0.9), 0.0),
        (UIColor(red: 1.0, green: 0.65, blue: 0.10, alpha: 0.6), 0.45),
        (UIColor(red: 1.0, green: 0.30, blue: 0.00, alpha: 0.0), 1.0)
      ]
    )
    node.addChild(corona)

    // --- 5. Prominences: looping arcs at random angles ---
    let promAngles: [CGFloat] = [
      CGFloat.pi * 0.10,
      CGFloat.pi * 0.55,
      CGFloat.pi * 0.95,
      CGFloat.pi * 1.40,
      CGFloat.pi * 1.75,
    ]
    let promContainer = SKNode()
    for (i, angle) in promAngles.enumerated() {
      let delay = Double(i) * 1.8
      let prom = NodeFactory.makeProminence(radius: radius, angle: angle, delay: delay)
      promContainer.addChild(prom)
    }
    // Slow drift so prominences feel organic
    promContainer.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 60)))
    node.addChild(promContainer)

    return node
  }

  // MARK: - Procedural sun texture

  private static func makeSunTexture(radius: CGFloat, size: CGSize) -> SKTexture {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
      let context = ctx.cgContext
      let center = CGPoint(x: size.width / 2, y: size.height / 2)

      // Radial gradient: white-yellow core → deep orange edge (limb darkening)
      let colors: [CGColor] = [
        UIColor(red: 1.00, green: 0.98, blue: 0.82, alpha: 1.0).cgColor,
        UIColor(red: 1.00, green: 0.88, blue: 0.30, alpha: 1.0).cgColor,
        UIColor(red: 0.95, green: 0.60, blue: 0.05, alpha: 1.0).cgColor,
        UIColor(red: 0.75, green: 0.35, blue: 0.00, alpha: 1.0).cgColor,
      ]
      let locations: [CGFloat] = [0.0, 0.45, 0.78, 1.0]
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
        context.drawRadialGradient(
          gradient,
          startCenter: CGPoint(x: center.x - radius * 0.1, y: center.y + radius * 0.08),
          startRadius: 0,
          endCenter: center,
          endRadius: radius,
          options: .drawsBeforeStartLocation
        )
      }

      // Clip to circle
      context.saveGState()

      // Granulation: small dark blotches simulating convection cells
      var rng: UInt64 = 0xDEADBEEF
      func nextRand() -> CGFloat {
        rng = rng &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(rng >> 33) / CGFloat(UInt32.max)
      }

      for _ in 0..<55 {
        let r = nextRand() * radius * 0.85
        let a = nextRand() * CGFloat.pi * 2
        let x = center.x + cos(a) * r
        let y = center.y + sin(a) * r
        let spotR = nextRand() * radius * 0.09 + radius * 0.03
        let alpha = nextRand() * 0.18 + 0.06
        context.setFillColor(UIColor(red: 0.45, green: 0.20, blue: 0.0, alpha: alpha).cgColor)
        context.fillEllipse(in: CGRect(x: x - spotR, y: y - spotR, width: spotR * 2, height: spotR * 2))
      }

      // 2–3 actual sunspots (darker)
      let spots: [(CGFloat, CGFloat, CGFloat)] = [
        (0.30, 0.18, 0.10),
        (-0.20, -0.35, 0.08),
        (0.45, -0.20, 0.06),
      ]
      for spot in spots {
        let x = center.x + spot.0 * radius
        let y = center.y + spot.1 * radius
        let sr = spot.2 * radius
        // Penumbra
        context.setFillColor(UIColor(red: 0.5, green: 0.25, blue: 0.0, alpha: 0.45).cgColor)
        context.fillEllipse(in: CGRect(x: x - sr * 1.8, y: y - sr * 1.8, width: sr * 3.6, height: sr * 3.6))
        // Umbra
        context.setFillColor(UIColor(red: 0.15, green: 0.05, blue: 0.0, alpha: 0.70).cgColor)
        context.fillEllipse(in: CGRect(x: x - sr, y: y - sr, width: sr * 2, height: sr * 2))
      }

      context.restoreGState()
    }
    return SKTexture(image: image)
  }

  // MARK: - Prominence loop

  private static func makeProminence(radius: CGFloat, angle: CGFloat, delay: Double) -> SKNode {
    let container = SKNode()
    container.name = "prom"

    // Build a looping arc path: rises outward and curves back
    let loopHeight = radius * (0.55 + CGFloat.random(in: 0...0.35))
    let loopWidth  = radius * (0.40 + CGFloat.random(in: 0...0.25))

    // Path in local space (along +Y axis), rotated by angle
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 0, y: radius))
    path.addCurve(
      to: CGPoint(x: 0, y: radius),
      controlPoint1: CGPoint(x: -loopWidth, y: radius + loopHeight),
      controlPoint2: CGPoint(x:  loopWidth, y: radius + loopHeight)
    )

    // Visible arc drawn as a glowing shape
    let arcNode = SKShapeNode(path: path.cgPath)
    arcNode.strokeColor = UIColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 0.0)
    arcNode.lineWidth = 2.5
    arcNode.glowWidth = 5
    arcNode.fillColor = .clear
    arcNode.zRotation = angle - CGFloat.pi / 2
    container.addChild(arcNode)

    // Animate: fade in → hold → fade out, repeat with delay offset
    let totalDuration = 3.5 + Double.random(in: 0...2.0)
    let fadeIn  = SKAction.fadeAlpha(to: 0.9, duration: totalDuration * 0.35)
    let hold    = SKAction.wait(forDuration: totalDuration * 0.30)
    let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: totalDuration * 0.35)
    let wait    = SKAction.wait(forDuration: totalDuration * 0.5 + delay)
    arcNode.alpha = 0
    arcNode.run(SKAction.repeatForever(SKAction.sequence([wait, fadeIn, hold, fadeOut])))

    // Particle emitter that follows the arc for a glowing plasma effect
    let emitter = SKEmitterNode()
    emitter.particleBirthRate = 18
    emitter.particleLifetime = 0.7
    emitter.particleLifetimeRange = 0.3
    emitter.particleSpeed = 3
    emitter.particleSpeedRange = 2
    emitter.emissionAngleRange = .pi * 2
    emitter.particleScale = 0.12
    emitter.particleScaleSpeed = -0.10
    emitter.particleAlpha = 0.0
    emitter.particleBlendMode = .add
    emitter.particleColorBlendFactor = 1.0
    emitter.particleColorSequence = SKKeyframeSequence(
      keyframeValues: [
        UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0),
        UIColor(red: 1.0, green: 0.50, blue: 0.1, alpha: 0.8),
        UIColor(red: 0.9, green: 0.20, blue: 0.0, alpha: 0.0),
      ],
      times: [0, 0.5, 1.0]
    )
    emitter.zRotation = angle - CGFloat.pi / 2

    // Move emitter along the bezier path repeatedly
    let followPath = SKAction.follow(path.cgPath, asOffset: false, orientToPath: false, duration: totalDuration * 0.65)
    let emitterWait = SKAction.wait(forDuration: delay)
    let showEmitter = SKAction.run { emitter.particleAlpha = 0.85 }
    let hideEmitter = SKAction.run { emitter.particleAlpha = 0.0 }
    emitter.run(SKAction.repeatForever(SKAction.sequence([
      emitterWait, showEmitter, followPath, hideEmitter,
      SKAction.wait(forDuration: totalDuration * 0.85)
    ])))

    container.addChild(emitter)
    return container
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
