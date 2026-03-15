//  SplashViewController.swift
//  Graviton – Fancy splash screen with animated solar system

import UIKit
import SpriteKit

class SplashViewController: UIViewController {

    private var skView: SKView!
    private var splashScene: SplashScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSpriteKitView()
        setupTitleLabel()
        setupTaglineLabel()
        scheduleDismissal()
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup

    private func setupSpriteKitView() {
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.backgroundColor = .black
        skView.allowsTransparency = false
        view.addSubview(skView)

        splashScene = SplashScene(size: view.bounds.size)
        splashScene.scaleMode = .aspectFill
        skView.presentScene(splashScene)
    }

    private func setupTitleLabel() {
        let label = UILabel()
        label.text = "Graviton"
        label.textAlignment = .center
        label.textColor = .white
        // Use a large, rounded system font for a cosmic feel
        if let rounded = UIFont(name: "SF Pro Rounded", size: 72) {
            label.font = rounded
        } else {
            label.font = UIFont.systemFont(ofSize: 72, weight: .thin)
        }
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30)
        ])

        UIView.animate(withDuration: 1.2, delay: 0.4, options: .curveEaseOut) {
            label.alpha = 1.0
        }
    }

    private func setupTaglineLabel() {
        // Outer badge container
        let badge = UIView()
        badge.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        badge.layer.cornerRadius = 12
        badge.layer.borderWidth = 0.8
        badge.layer.borderColor = UIColor(white: 1.0, alpha: 0.30).cgColor
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.alpha = 0
        view.addSubview(badge)

        let label = UILabel()
        label.text = "Based on \"Gravity Zen\" by Dasdom"
        label.textAlignment = .center
        label.textColor = UIColor(white: 0.85, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)

        NSLayoutConstraint.activate([
            // Badge position: below center
            badge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 24),

            // Label padding inside badge
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -16)
        ])

        UIView.animate(withDuration: 1.0, delay: 0.8, options: .curveEaseOut) {
            badge.alpha = 1.0
        }
    }

    // MARK: - Dismissal

    private func scheduleDismissal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.transitionToGame()
        }
    }

    private func transitionToGame() {
        guard let windowScene = view.window?.windowScene else { return }
        let gameVC = GameViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = gameVC

        UIView.transition(
            with: window,
            duration: 0.6,
            options: .transitionCrossDissolve
        ) {
            window.makeKeyAndVisible()
        }

        // Hand over window ownership to SceneDelegate
        if let delegate = windowScene.delegate as? SceneDelegate {
            delegate.window = window
        }
    }
}

// MARK: - SplashScene

/// A compact SpriteKit scene that shows an animated solar system centered on screen.
class SplashScene: SKScene {

    private let sunRadius: CGFloat = 22
    // Orbit definition: (orbitRadius, planetRadius, color, period)
    private let orbits: [(r: CGFloat, pr: CGFloat, color: UIColor, period: TimeInterval)] = [
        (70,  5,  UIColor(red: 0.75, green: 0.60, blue: 0.45, alpha: 1), 2.8),
        (105, 7,  UIColor(red: 0.20, green: 0.50, blue: 0.85, alpha: 1), 4.8),
        (145, 6,  UIColor(red: 0.30, green: 0.65, blue: 0.30, alpha: 1), 7.8),
        (185, 9,  UIColor(red: 0.85, green: 0.55, blue: 0.25, alpha: 1), 13.0),
        (230, 5,  UIColor(red: 0.70, green: 0.55, blue: 0.40, alpha: 1), 21.0),
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .black
        scaleMode = .aspectFill
        addStarField()
        addSun()
        addOrbits()
    }

    // MARK: Star field

    private func addStarField() {
        guard let emitter = SKEmitterNode(fileNamed: "background") else { return }
        emitter.particlePositionRange = CGVector(dx: size.width * 2, dy: size.height * 2)
        emitter.particleBirthRate = 12
        emitter.particleLifetime = 60
        emitter.particleLifetimeRange = 30
        emitter.numParticlesToEmit = 0
        emitter.zPosition = -100
        emitter.particleZPosition = -100
        emitter.advanceSimulationTime(60)
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(emitter)
    }

    // MARK: Sun

    private func addSun() {
        let sun = makeSun(radius: sunRadius)
        sun.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sun.zPosition = 10
        addChild(sun)
    }

    private func makeSun(radius: CGFloat) -> SKNode {
        let container = SKNode()

        // Black disc to keep star field from showing through
        let blocker = SKShapeNode(circleOfRadius: radius * 4.0)
        blocker.fillColor = .black
        blocker.lineWidth = 0
        blocker.zPosition = -90
        container.addChild(blocker)

        // Glow layers (additive blend gives HDR look)
        let glowEffect = SKEffectNode()
        glowEffect.shouldRasterize = false
        glowEffect.blendMode = .add
        if let blur = CIFilter(name: "CIGaussianBlur") {
            blur.setValue(12.0, forKey: kCIInputRadiusKey)
            glowEffect.filter = blur
        }
        let glowLayers: [(mul: CGFloat, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [
            (3.6, 1.0, 0.30, 0.00, 0.30),
            (2.6, 1.0, 0.45, 0.00, 0.45),
            (1.9, 1.0, 0.60, 0.05, 0.60),
            (1.4, 1.0, 0.78, 0.10, 0.80),
            (1.0, 1.0, 0.97, 0.70, 1.00),
        ]
        for l in glowLayers {
            let c = SKShapeNode(circleOfRadius: radius * l.mul)
            c.lineWidth = 0
            c.fillColor = UIColor(red: l.r, green: l.g, blue: l.b, alpha: l.a)
            glowEffect.addChild(c)
        }
        glowEffect.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.85, duration: 1.3),
            SKAction.fadeAlpha(to: 1.00, duration: 1.3)
        ])))
        container.addChild(glowEffect)

        // Surface particle emitter
        let shimmer = makeSunEmitter(radius: radius)
        container.addChild(shimmer)

        return container
    }

    private func makeSunEmitter(radius: CGFloat) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleBirthRate = 60
        e.particleLifetime = 0.5
        e.particleLifetimeRange = 0.3
        e.particleSpeed = 6
        e.particleSpeedRange = 4
        e.emissionAngleRange = .pi * 2
        e.particleScale = 0.12
        e.particleScaleRange = 0.05
        e.particleScaleSpeed = -0.08
        e.particleAlpha = 1.0
        e.particleAlphaSpeed = -2.0
        e.particleBlendMode = .add
        e.particleColorBlendFactor = 1.0
        e.particlePositionRange = CGVector(dx: radius * 1.8, dy: radius * 1.8)
        e.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(red: 1.0, green: 1.0, blue: 0.85, alpha: 1.0),
                UIColor(red: 1.0, green: 0.8,  blue: 0.2,  alpha: 0.8),
                UIColor(red: 1.0, green: 0.4,  blue: 0.0,  alpha: 0.0)
            ],
            times: [0, 0.5, 1.0]
        )
        return e
    }

    // MARK: Orbit rings + planets

    private func addOrbits() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        for orbit in orbits {
            // Faint orbit ring
            let ring = SKShapeNode(circleOfRadius: orbit.r)
            ring.strokeColor = UIColor(white: 1.0, alpha: 0.08)
            ring.lineWidth = 0.8
            ring.fillColor = .clear
            ring.zPosition = 1
            ring.position = center
            addChild(ring)

            // Invisible pivot node that rotates
            let pivot = SKNode()
            pivot.position = center
            pivot.zPosition = 2
            addChild(pivot)

            // Planet on the pivot arm
            let planet = makePlanet(radius: orbit.pr, color: orbit.color)
            planet.position = CGPoint(x: orbit.r, y: 0)
            pivot.addChild(planet)

            // Rotate the pivot continuously
            let rotation = SKAction.repeatForever(
                SKAction.rotate(byAngle: -.pi * 2, duration: orbit.period)
            )
            // Random starting angle for visual variety
            let startAngle = CGFloat.random(in: 0 ..< .pi * 2)
            pivot.zRotation = startAngle
            pivot.run(rotation)
        }
    }

    private func makePlanet(radius: CGFloat, color: UIColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color
        node.lineWidth = 0

        // Tiny glow via additive emitter
        let glow = SKEmitterNode()
        glow.particleBirthRate = 10
        glow.particleLifetime = 0.4
        glow.particleLifetimeRange = 0.2
        glow.particleSpeed = 0
        glow.particleSpeedRange = 1
        glow.emissionAngleRange = .pi * 2
        glow.particleScale = 0.08
        glow.particleScaleRange = 0.03
        glow.particleScaleSpeed = -0.1
        glow.particleAlpha = 0.5
        glow.particleAlphaSpeed = -1.2
        glow.particleBlendMode = .add
        glow.particleColorBlendFactor = 1.0
        glow.particleColor = color
        glow.particlePositionRange = CGVector(dx: radius, dy: radius)
        node.addChild(glow)

        return node
    }
}
