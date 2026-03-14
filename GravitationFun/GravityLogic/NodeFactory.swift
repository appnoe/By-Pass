//  Created by Dominik Hauser on 01.01.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

// MARK: - Planet Types

enum PlanetType: CaseIterable {
  case rocky       // grau-braun, Krater
  case lava        // dunkelrot, Lava-Risse
  case gas         // orange-beige, horizontale Streifen (Jupiter-artig)
  case ocean       // blau-grün, Wolkenflecken
  case icy         // hellblau-weiß, Eisstruktur

  static func random() -> PlanetType {
    return PlanetType.allCases.randomElement()!
  }
}

enum NodeFactory {
  static func center() -> SKShapeNode {
    let radius: CGFloat = 14

    // --- Core sun body (physics anchor) ---
    let node = SKShapeNode(circleOfRadius: radius)
    node.lineWidth = 0
    node.fillColor = .clear   // visual comes from effect node below
    node.zPosition = 1        // in front of stars (z=-10), behind planets (z=2)

    node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    node.physicsBody?.isDynamic = false
    node.physicsBody?.categoryBitMask = PhysicsCategory.center
    node.physicsBody?.contactTestBitMask = PhysicsCategory.satellite

    // --- Bloom effect wrapper ---
    // SKEffectNode with a Gaussian blur renders the sun body blurred,
    // giving a real HDR-style glow when blended additively.
    let glowEffect = SKEffectNode()
    glowEffect.shouldRasterize = false
    glowEffect.blendMode = .add
    if let blur = CIFilter(name: "CIGaussianBlur") {
      blur.setValue(10.0, forKey: kCIInputRadiusKey)
      glowEffect.filter = blur
    }

    // Layers inside the effect node: biggest first (darkest), smallest last (brightest)
    let glowLayers: [(multiplier: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [
      (3.6, 1.0, 0.30, 0.00, 0.30),
      (2.6, 1.0, 0.45, 0.00, 0.45),
      (1.9, 1.0, 0.60, 0.05, 0.60),
      (1.4, 1.0, 0.78, 0.10, 0.80),
      (1.0, 1.0, 0.97, 0.70, 1.00),
    ]
    for layer in glowLayers {
      let circle = SKShapeNode(circleOfRadius: radius * layer.multiplier)
      circle.lineWidth = 0
      circle.fillColor = UIColor(red: layer.r, green: layer.g, blue: layer.b, alpha: layer.a)
      glowEffect.addChild(circle)
    }

    // Subtle pulse on the whole glow
    glowEffect.run(SKAction.repeatForever(SKAction.sequence([
      SKAction.fadeAlpha(to: 0.85, duration: 1.3),
      SKAction.fadeAlpha(to: 1.00, duration: 1.3)
    ])))

    node.addChild(glowEffect)

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
    flames.xAcceleration = 0
    flames.yAcceleration = 8
    node.addChild(flames)

    // --- Protuberances: sporadic tall jets ---
    let protuberanceAngles: [CGFloat] = [CGFloat.pi/4, CGFloat.pi*3/4, CGFloat.pi*5/4, CGFloat.pi*7/4]
    let protContainer = SKNode()
    for angle in protuberanceAngles {
      let prot = NodeFactory.makeProtuberance(radius: radius, angle: angle)
      protContainer.addChild(prot)
    }
    protContainer.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 18)))
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

  static func backgroundEmitter(size: CGSize) -> SKNode? {
    guard let emitter = SKEmitterNode(fileNamed: "background") else { return nil }
    emitter.particlePositionRange = CGVector(dx: size.width * 2, dy: size.height * 2)
    // ~1500 stars at equilibrium: birthRate * lifetime = 25 * 60 = ~1500 visible at any time
    emitter.particleBirthRate = 25
    emitter.particleLifetime = 60
    emitter.particleLifetimeRange = 30
    emitter.numParticlesToEmit = 0
    emitter.advanceSimulationTime(60)

    // Wrap the emitter in a SKCropNode with a ring-shaped mask so that stars
    // are clipped away over the sun area at the scene centre.
    // The mask is white everywhere EXCEPT a black circle over the sun,
    // because SKCropNode renders children only where the mask is non-transparent.
    let cropNode = SKCropNode()
    cropNode.zPosition = -10   // always behind sun, planets and trails

    let maskSize = CGSize(width: size.width * 2, height: size.height * 2)
    let sunClearRadius: CGFloat = 60  // points to keep star-free around origin

    // Draw the mask: full white rectangle with a black (transparent) circle cut out
    let maskRenderer = UIGraphicsImageRenderer(size: maskSize)
    let maskImage = maskRenderer.image { ctx in
      // White fill = visible
      UIColor.white.setFill()
      ctx.fill(CGRect(origin: .zero, size: maskSize))
      // Black (clear) circle in the centre = hidden
      UIColor.black.setFill()
      let cx = maskSize.width / 2
      let cy = maskSize.height / 2
      ctx.cgContext.fillEllipse(in: CGRect(
        x: cx - sunClearRadius, y: cy - sunClearRadius,
        width: sunClearRadius * 2, height: sunClearRadius * 2
      ))
    }
    let maskNode = SKSpriteNode(texture: SKTexture(image: maskImage),
                                size: maskSize)
    cropNode.maskNode = maskNode
    cropNode.addChild(emitter)
    return cropNode
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

  // MARK: - Planet Texture

  static func planetTexture(type: PlanetType, radius: CGFloat, baseColor: UIColor) -> SKTexture {
    let size = CGSize(width: radius * 2, height: radius * 2)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
      let cgCtx = ctx.cgContext
      let center = CGPoint(x: radius, y: radius)

      // Clip all drawing to circle
      let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
      circlePath.addClip()

      switch type {

      case .rocky:
        // Base gradient: mid-grey to dark at limb
        NodeFactory.drawSphereGradient(
          in: cgCtx, center: center, radius: radius,
          inner: UIColor(red: 0.60, green: 0.55, blue: 0.48, alpha: 1),
          outer: UIColor(red: 0.20, green: 0.17, blue: 0.14, alpha: 1)
        )
        // Craters
        var rng = RNG(seed: 0xABCD_1234)
        for _ in 0..<12 {
          let r = rng.next() * radius * 0.80
          let a = rng.next() * .pi * 2
          let cr = rng.next() * radius * 0.18 + radius * 0.06
          let x = center.x + cos(a) * r
          let y = center.y + sin(a) * r
          // Shadow half
          cgCtx.setFillColor(UIColor(white: 0.12, alpha: 0.45).cgColor)
          cgCtx.fillEllipse(in: CGRect(x: x - cr, y: y - cr + cr * 0.15, width: cr * 2, height: cr * 2))
          // Highlight rim
          cgCtx.setFillColor(UIColor(white: 0.80, alpha: 0.30).cgColor)
          cgCtx.fillEllipse(in: CGRect(x: x - cr, y: y - cr - cr * 0.10, width: cr * 2, height: cr * 1.6))
          // Dark floor
          cgCtx.setFillColor(UIColor(white: 0.08, alpha: 0.55).cgColor)
          cgCtx.fillEllipse(in: CGRect(x: x - cr * 0.6, y: y - cr * 0.6, width: cr * 1.2, height: cr * 1.2))
        }

      case .lava:
        // Dark red base
        NodeFactory.drawSphereGradient(
          in: cgCtx, center: center, radius: radius,
          inner: UIColor(red: 0.55, green: 0.10, blue: 0.02, alpha: 1),
          outer: UIColor(red: 0.12, green: 0.02, blue: 0.00, alpha: 1)
        )
        // Glowing lava cracks
        var rng = RNG(seed: 0xDEAD_BEEF)
        for _ in 0..<18 {
          let x0 = rng.next() * radius * 1.6 - radius * 0.8 + center.x
          let y0 = rng.next() * radius * 1.6 - radius * 0.8 + center.y
          let x1 = x0 + (rng.next() - 0.5) * radius * 0.6
          let y1 = y0 + (rng.next() - 0.5) * radius * 0.6
          let alpha = rng.next() * 0.55 + 0.25
          cgCtx.setStrokeColor(UIColor(red: 1.0, green: 0.45, blue: 0.0, alpha: alpha).cgColor)
          cgCtx.setLineWidth(rng.next() * 1.2 + 0.4)
          cgCtx.move(to: CGPoint(x: x0, y: y0))
          cgCtx.addLine(to: CGPoint(x: x1, y: y1))
          cgCtx.strokePath()
        }
        // Hot spots
        for _ in 0..<6 {
          let r = rng.next() * radius * 0.75
          let a = rng.next() * .pi * 2
          let sr = rng.next() * radius * 0.10 + radius * 0.04
          let x = center.x + cos(a) * r
          let y = center.y + sin(a) * r
          let colors = [UIColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 0.9).cgColor,
                        UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.0).cgColor] as CFArray
          if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: colors, locations: [0, 1.0]) {
            cgCtx.drawRadialGradient(grad,
              startCenter: CGPoint(x: x, y: y), startRadius: 0,
              endCenter: CGPoint(x: x, y: y), endRadius: sr * 2,
              options: [])
          }
        }

      case .gas:
        // Base warm orange
        NodeFactory.drawSphereGradient(
          in: cgCtx, center: center, radius: radius,
          inner: UIColor(red: 0.92, green: 0.72, blue: 0.42, alpha: 1),
          outer: UIColor(red: 0.40, green: 0.22, blue: 0.08, alpha: 1)
        )
        // Horizontal bands
        var rng = RNG(seed: 0x1234_5678)
        let bandColors: [UIColor] = [
          UIColor(red: 0.75, green: 0.45, blue: 0.22, alpha: 0.55),
          UIColor(red: 0.95, green: 0.82, blue: 0.60, alpha: 0.45),
          UIColor(red: 0.55, green: 0.30, blue: 0.12, alpha: 0.60),
          UIColor(red: 0.88, green: 0.65, blue: 0.35, alpha: 0.40),
          UIColor(red: 0.65, green: 0.38, blue: 0.18, alpha: 0.55),
        ]
        var y = radius * 0.15
        while y < radius * 1.85 {
          let bh = rng.next() * radius * 0.22 + radius * 0.08
          let col = bandColors[Int(rng.next() * CGFloat(bandColors.count))]
          cgCtx.setFillColor(col.cgColor)
          // Slightly wavy band
          let wave = rng.next() * radius * 0.06 - radius * 0.03
          cgCtx.fill(CGRect(x: 0, y: y + wave, width: radius * 2, height: bh))
          y += bh + rng.next() * radius * 0.05
        }
        // Great spot
        let spotX = center.x + radius * 0.20
        let spotY = center.y + radius * 0.15
        cgCtx.setFillColor(UIColor(red: 0.65, green: 0.22, blue: 0.10, alpha: 0.70).cgColor)
        cgCtx.fillEllipse(in: CGRect(x: spotX - radius * 0.18, y: spotY - radius * 0.10,
                                     width: radius * 0.36, height: radius * 0.20))

      case .ocean:
        // Blue-green base
        NodeFactory.drawSphereGradient(
          in: cgCtx, center: center, radius: radius,
          inner: UIColor(red: 0.10, green: 0.45, blue: 0.75, alpha: 1),
          outer: UIColor(red: 0.02, green: 0.10, blue: 0.30, alpha: 1)
        )
        // Land masses
        var rng = RNG(seed: 0xFEED_FACE)
        for _ in 0..<5 {
          let r = rng.next() * radius * 0.65
          let a = rng.next() * .pi * 2
          let lw = rng.next() * radius * 0.35 + radius * 0.15
          let lh = rng.next() * radius * 0.22 + radius * 0.10
          let x = center.x + cos(a) * r
          let y = center.y + sin(a) * r
          cgCtx.setFillColor(UIColor(red: 0.25, green: 0.50, blue: 0.20, alpha: 0.80).cgColor)
          cgCtx.fillEllipse(in: CGRect(x: x - lw/2, y: y - lh/2, width: lw, height: lh))
        }
        // Cloud wisps
        for _ in 0..<8 {
          let r = rng.next() * radius * 0.80
          let a = rng.next() * .pi * 2
          let cw = rng.next() * radius * 0.40 + radius * 0.15
          let x = center.x + cos(a) * r
          let y = center.y + sin(a) * r
          cgCtx.setFillColor(UIColor(white: 1.0, alpha: rng.next() * 0.35 + 0.15).cgColor)
          cgCtx.fillEllipse(in: CGRect(x: x - cw/2, y: y - cw * 0.2, width: cw, height: cw * 0.35))
        }

      case .icy:
        // White-blue base
        NodeFactory.drawSphereGradient(
          in: cgCtx, center: center, radius: radius,
          inner: UIColor(red: 0.88, green: 0.94, blue: 1.00, alpha: 1),
          outer: UIColor(red: 0.30, green: 0.50, blue: 0.75, alpha: 1)
        )
        // Ice crack network
        var rng = RNG(seed: 0xC0DE_CAFE)
        for _ in 0..<22 {
          let x0 = rng.next() * radius * 2
          let y0 = rng.next() * radius * 2
          let x1 = x0 + (rng.next() - 0.5) * radius * 0.7
          let y1 = y0 + (rng.next() - 0.5) * radius * 0.7
          let alpha = rng.next() * 0.30 + 0.12
          cgCtx.setStrokeColor(UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: alpha).cgColor)
          cgCtx.setLineWidth(0.5)
          cgCtx.move(to: CGPoint(x: x0, y: y0))
          cgCtx.addLine(to: CGPoint(x: x1, y: y1))
          cgCtx.strokePath()
        }
        // Frozen patches
        for _ in 0..<6 {
          let r = rng.next() * radius * 0.70
          let a = rng.next() * .pi * 2
          let pr = rng.next() * radius * 0.18 + radius * 0.06
          let x = center.x + cos(a) * r
          let y = center.y + sin(a) * r
          cgCtx.setFillColor(UIColor(white: 1.0, alpha: 0.35).cgColor)
          cgCtx.fillEllipse(in: CGRect(x: x - pr, y: y - pr, width: pr * 2, height: pr * 2))
        }
      }

      // --- Shared: specular highlight (top-left bright spot) ---
      let hlX = center.x - radius * 0.30
      let hlY = center.y + radius * 0.28
      let hlColors = [UIColor(white: 1.0, alpha: 0.65).cgColor,
                      UIColor(white: 1.0, alpha: 0.00).cgColor] as CFArray
      if let hlGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: hlColors, locations: [0, 1.0]) {
        cgCtx.drawRadialGradient(hlGrad,
          startCenter: CGPoint(x: hlX, y: hlY), startRadius: 0,
          endCenter: CGPoint(x: hlX, y: hlY), endRadius: radius * 0.55,
          options: [])
      }

      // --- Shared: dark limb (atmospheric edge darkening) ---
      let limbColors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.00).cgColor,
                        UIColor(red: 0, green: 0, blue: 0, alpha: 0.55).cgColor] as CFArray
      if let limbGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: limbColors, locations: [0.65, 1.0]) {
        cgCtx.drawRadialGradient(limbGrad,
          startCenter: center, startRadius: radius * 0.55,
          endCenter: center, endRadius: radius,
          options: [])
      }
    }
    return SKTexture(image: image)
  }

  // Sphere shading: off-center radial gradient for 3D look
  private static func drawSphereGradient(
    in ctx: CGContext, center: CGPoint, radius: CGFloat,
    inner: UIColor, outer: UIColor
  ) {
    let colors = [inner.cgColor, outer.cgColor] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]
    guard let gradient = CGGradient(
      colorsSpace: CGColorSpaceCreateDeviceRGB(),
      colors: colors,
      locations: locations
    ) else { return }
    // Offset light source top-left for 3D feel
    let lightCenter = CGPoint(x: center.x - radius * 0.25, y: center.y + radius * 0.20)
    ctx.drawRadialGradient(
      gradient,
      startCenter: lightCenter, startRadius: 0,
      endCenter: center, endRadius: radius,
      options: .drawsAfterEndLocation
    )
  }
}

// MARK: - Simple deterministic RNG (LCG) for texture generation

private struct RNG {
  var state: UInt64
  init(seed: UInt64) { state = seed }
  mutating func next() -> CGFloat {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    return CGFloat(state >> 33) / CGFloat(UInt32.max)
  }
}
