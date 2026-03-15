//  InfoSheetViewController.swift
//  Graviton – Info-Sheet mit animiertem Sonnensystem (von unten schiebbar)

import UIKit
import SpriteKit

class InfoSheetViewController: UIViewController {

    // The glow overlay sits on top of everything else and is pointer-transparent.
    private let glowOverlay = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSpriteKitView()
        setupGlowBorder()   // directly above SKView, behind title and badge
        setupTitleLabel()
        setupTaglineLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        glowOverlay.frame = view.bounds
        let r = view.layer.cornerRadius > 0 ? view.layer.cornerRadius : 24
        glowOverlay.layer.cornerRadius = r
        glowOverlay.layer.shadowPath = UIBezierPath(
            roundedRect: view.bounds, cornerRadius: r
        ).cgPath
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup

    private func setupGlowBorder() {
        // Transparent overlay on top of the SKView so the glow is never occluded.
        // clipsToBounds = false lets the shadow spread outside the bounds.
        glowOverlay.backgroundColor = .clear
        glowOverlay.isUserInteractionEnabled = false
        glowOverlay.clipsToBounds = false

        // Visible border line
        glowOverlay.layer.borderColor = UIColor(red: 1.0, green: 0.60, blue: 0.05, alpha: 0.55).cgColor
        glowOverlay.layer.borderWidth = 1.0

        // Inward glow via layer shadow (offset zero = even halo)
        glowOverlay.layer.shadowColor  = UIColor(red: 1.0, green: 0.50, blue: 0.02, alpha: 1.0).cgColor
        glowOverlay.layer.shadowOffset = .zero
        glowOverlay.layer.shadowRadius = 8
        glowOverlay.layer.shadowOpacity = 0.65

        view.addSubview(glowOverlay)

        // Gentle pulse on the shadow opacity
        let pulse = CABasicAnimation(keyPath: "shadowOpacity")
        pulse.fromValue  = 0.45
        pulse.toValue    = 0.95
        pulse.duration   = 1.8
        pulse.autoreverses   = true
        pulse.repeatCount    = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowOverlay.layer.add(pulse, forKey: "glowPulse")
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
