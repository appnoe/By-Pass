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
        setupVersionLabel()
        setupImprintLabel()
        setupTaglineLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        glowOverlay.frame = view.bounds
        updateGlowPath()
    }

    private func updateGlowPath() {
        let r = view.layer.cornerRadius > 0 ? view.layer.cornerRadius : 24
        glowOverlay.layer.cornerRadius = r
        glowOverlay.layer.shadowPath = UIBezierPath(
            roundedRect: view.bounds, cornerRadius: r
        ).cgPath

        // Gradient mask: opaque at top and bottom edges, transparent in the
        // centre — so the border "frays" and fades out towards the middle.
        let grad = glowOverlay.layer.mask as? CAGradientLayer ?? CAGradientLayer()
        grad.frame = view.bounds
        grad.colors = [
            UIColor.white.cgColor,          // top   – fully visible
            UIColor.clear.cgColor,          // centre – invisible
            UIColor.clear.cgColor,          // centre – invisible
            UIColor.white.cgColor,          // bottom – fully visible
        ]
        grad.locations = [0, 0.35, 0.65, 1.0]
        grad.startPoint = CGPoint(x: 0.5, y: 0)
        grad.endPoint   = CGPoint(x: 0.5, y: 1)
        glowOverlay.layer.mask = grad
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup

    private func setupGlowBorder() {
        // Transparent overlay on top of the SKView so the glow is never occluded.
        // clipsToBounds = false lets the shadow spread outside the bounds.
        // Subtle warm tint in the ring strip; transparent centre = planets show through
        glowOverlay.backgroundColor = UIColor(red: 1.0, green: 0.45, blue: 0.02, alpha: 0.08)
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
        let skView = GravitySKView(frame: view.bounds)
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
        label.text = "By-Pass"
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
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48)
        ])
    }

    private func setupVersionLabel() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

        let label = UILabel()
        label.text = "\(version) (\(build))"
        label.textAlignment = .center
        label.textColor = UIColor(white: 1.0, alpha: 0.45)
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 124)
        ])
    }

    private func setupImprintLabel() {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = imprintText()
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160)
        ])
    }

    private func imprintText() -> NSAttributedString {
        let heading = { (text: String) -> NSAttributedString in
            NSAttributedString(string: text + "\n", attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor(white: 1.0, alpha: 0.95)
            ])
        }
        let body = { (text: String) -> NSAttributedString in
            NSAttributedString(string: text + "\n", attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor(white: 0.75, alpha: 1.0)
            ])
        }
        let spacer = NSAttributedString(string: "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 6)
        ])

        let result = NSMutableAttributedString()
        result.append(body("by"))
        result.append(spacer)
        result.append(NSAttributedString(string: "Appnö GmbH\n", attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor(white: 0.75, alpha: 1.0)
        ]))
        result.append(body("Erkrather Str. 401\n40231 Düsseldorf"))
        result.append(spacer)
        result.append(heading("Geschäftsführer:"))
        result.append(body("Klaus Rodewig"))
        result.append(spacer)
        result.append(heading("Kontakt:"))
        result.append(body("info@appnoe.de"))
        result.append(spacer)
        result.append(heading("Handelsregister:"))
        result.append(body("Amtsgericht Düsseldorf\nHRB 74943"))
        result.append(spacer)
        result.append(heading("Steuerinformationen:"))
        result.append(body("Finanzamt Düsseldorf-Süd\nSteuer-Nr. 122/5703/5885\nUSt-IdNr: DE308226646"))
        result.append(spacer)
        result.append(spacer)
        result.append(NSAttributedString(string: "Datenschutzerklärung:\nDiese App erfasst keine Daten.", attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor(white: 0.95, alpha: 1.0)
        ]))

        // Centre-align the whole paragraph
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 2
        result.addAttribute(.paragraphStyle, value: style,
                            range: NSRange(location: 0, length: result.length))
        return result
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
