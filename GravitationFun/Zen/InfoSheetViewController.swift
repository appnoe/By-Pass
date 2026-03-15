//  InfoSheetViewController.swift
//  Graviton – Info-Sheet mit animiertem Sonnensystem (von unten schiebbar)

import UIKit
import SpriteKit

class InfoSheetViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSpriteKitView()
        setupGlowBorder()
        setupTitleLabel()
        setupTaglineLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update glow path after corner radius is applied by the sheet
        if let glowLayer = view.layer.sublayers?.first(where: { $0.name == "glowBorder" }) as? CAShapeLayer {
            glowLayer.path = UIBezierPath(
                roundedRect: view.bounds,
                cornerRadius: view.layer.cornerRadius
            ).cgPath
        }
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup

    private func setupGlowBorder() {
        // A CAShapeLayer stroked with the sun's warm orange, with a matching
        // shadow-blur (shadowRadius) to create an inner-glow effect.
        // Placed as the bottommost sublayer so it stays behind everything.
        let glow = CAShapeLayer()
        glow.name = "glowBorder"
        glow.fillColor = UIColor.clear.cgColor
        glow.strokeColor = UIColor(red: 1.0, green: 0.65, blue: 0.10, alpha: 0.55).cgColor
        glow.lineWidth = 2.0
        // Shadow = soft halo around the stroke line
        glow.shadowColor  = UIColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 1.0).cgColor
        glow.shadowOffset = .zero
        glow.shadowRadius = 12
        glow.shadowOpacity = 0.9
        // path set in viewDidLayoutSubviews once corner radius is known
        glow.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: 24).cgPath
        view.layer.insertSublayer(glow, at: 0)

        // Gentle pulse: the glow breathes like the sun
        let pulse = CABasicAnimation(keyPath: "shadowOpacity")
        pulse.fromValue = 0.55
        pulse.toValue   = 0.95
        pulse.duration  = 1.8
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.add(pulse, forKey: "glowPulse")
    }

    private func setupSpriteKitView() {
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.backgroundColor = .black
        skView.allowsTransparency = false
        view.addSubview(skView)

        let scene = SplashScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }

    private func setupTitleLabel() {
        let label = UILabel()
        label.text = "Graviton"
        label.textAlignment = .center
        label.textColor = .white
        if let rounded = UIFont(name: "SF Pro Rounded", size: 72) {
            label.font = rounded
        } else {
            label.font = UIFont.systemFont(ofSize: 72, weight: .thin)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30)
        ])
    }

    private func setupTaglineLabel() {
        let badge = UIView()
        badge.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        badge.layer.cornerRadius = 12
        badge.layer.borderWidth = 0.8
        badge.layer.borderColor = UIColor(white: 1.0, alpha: 0.30).cgColor
        badge.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(badge)

        let label = UILabel()
        label.text = "Based on \"Gravity Zen\" by Dasdom"
        label.textAlignment = .center
        label.textColor = UIColor(white: 0.85, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(label)

        NSLayoutConstraint.activate([
            badge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badge.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -16)
        ])
    }
}
