import UIKit

/// Halbtransparentes Onboarding-Overlay, das die Slingshot-Geste demonstriert.
/// Erscheint beim allerersten App-Start über der GameScene.
class OnboardingOverlayView: UIView {

    private let dimmingView = UIView()
    private let handImageView: UIImageView
    private let ghostPlanet = UIView()
    private let velocityLineLayer = CAShapeLayer()
    private let hintLabel = UILabel()
    private let skipLabel = UILabel()

    private var animationLoopCount = 0
    private let maxLoops = 2
    private var isAnimating = false

    /// Wird nach dem Dismiss aufgerufen
    var onDismiss: (() -> Void)?

    override init(frame: CGRect) {
        // Hand-Symbol
        let config = UIImage.SymbolConfiguration(pointSize: 52, weight: .regular)
        let handImage = UIImage(systemName: "hand.point.up.left.fill", withConfiguration: config)
        handImageView = UIImageView(image: handImage)
        handImageView.tintColor = .white
        handImageView.contentMode = .scaleAspectFit

        super.init(frame: frame)

        setupViews()
        setupGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Dimming-Hintergrund
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Velocity-Linie (Layer direkt auf dem Overlay)
        velocityLineLayer.strokeColor = UIColor.systemGray.cgColor
        velocityLineLayer.lineWidth = 1.5
        velocityLineLayer.fillColor = UIColor.clear.cgColor
        velocityLineLayer.opacity = 0
        layer.addSublayer(velocityLineLayer)

        // Ghost-Planet
        let planetSize: CGFloat = 20
        ghostPlanet.frame = CGRect(x: 0, y: 0, width: planetSize, height: planetSize)
        ghostPlanet.layer.cornerRadius = planetSize / 2
        ghostPlanet.backgroundColor = UIColor(red: 0.15, green: 0.50, blue: 0.85, alpha: 0.9)
        ghostPlanet.layer.shadowColor = UIColor(red: 0.15, green: 0.50, blue: 0.85, alpha: 1).cgColor
        ghostPlanet.layer.shadowRadius = 6
        ghostPlanet.layer.shadowOpacity = 0.8
        ghostPlanet.layer.shadowOffset = .zero
        ghostPlanet.alpha = 0
        addSubview(ghostPlanet)

        // Hand
        handImageView.alpha = 0
        addSubview(handImageView)

        // Hinweistext
        hintLabel.text = "Tap, drag & release"
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.90)
        hintLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        hintLabel.textAlignment = .center
        hintLabel.alpha = 0
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hintLabel)

        // "Tippen zum Überspringen"
        skipLabel.text = "Tap to skip"
        skipLabel.textColor = UIColor.white.withAlphaComponent(0.45)
        skipLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        skipLabel.textAlignment = .center
        skipLabel.alpha = 0
        skipLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skipLabel)

        NSLayoutConstraint.activate([
            hintLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: topAnchor, constant: bounds.height * 0.15 + 44),
            skipLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            skipLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -84)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        velocityLineLayer.frame = bounds
    }

    private func setupGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    // MARK: - Public

    func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        // Labels einblenden
        UIView.animate(withDuration: 0.5, delay: 0.2) {
            self.hintLabel.alpha = 1
            self.skipLabel.alpha = 1
        }

        runNextCycle()
    }

    // MARK: - Animation

    private func runNextCycle() {
        guard animationLoopCount < maxLoops else {
            dismissOverlay(animated: true)
            return
        }
        animationLoopCount += 1
        runOneCycle {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.runNextCycle()
            }
        }
    }

    /// Ein kompletter Animations-Zyklus: Erscheinen → Antippen → Ziehen → Loslassen → Planet fliegt weg
    private func runOneCycle(completion: @escaping () -> Void) {
        let tapPoint = CGPoint(x: bounds.width * 0.58, y: bounds.height * 0.52)
        // Drag-Richtung: Hand zieht nach unten-links → Planet fliegt nach oben-rechts
        let dragOffset = CGPoint(x: -110, y: 100)
        let dragPoint = CGPoint(x: tapPoint.x + dragOffset.x, y: tapPoint.y + dragOffset.y)
        let launchOffset = CGPoint(x: -dragOffset.x * 1.4, y: -dragOffset.y * 1.4)
        let landPoint = CGPoint(x: tapPoint.x + launchOffset.x, y: tapPoint.y + launchOffset.y)

        // Startposition der Hand (etwas versetzt, wandert zum Tipp-Punkt)
        let handStartPoint = CGPoint(x: tapPoint.x + 30, y: tapPoint.y + 30)
        positionHand(at: handStartPoint)
        ghostPlanet.center = tapPoint
        ghostPlanet.alpha = 0
        ghostPlanet.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        velocityLineLayer.opacity = 0

        // Phase 1: Hand erscheint und bewegt sich zum Tipp-Punkt (0.5s)
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            self.handImageView.alpha = 1
            self.positionHand(at: tapPoint)
        }) { _ in

            // Phase 2: Hand tippt (0.25s) + Planet erscheint
            UIView.animate(withDuration: 0.2, animations: {
                self.handImageView.transform = CGAffineTransform(scaleX: 0.80, y: 0.80)
            })
            UIView.animate(withDuration: 0.3, delay: 0.05, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.8, animations: {
                self.ghostPlanet.alpha = 1
                self.ghostPlanet.transform = .identity
            }) { _ in

                // Phase 3: Hand zieht (1.0s) + Velocity-Linie erscheint
                self.velocityLineLayer.opacity = 1
                self.animateDrag(from: tapPoint, handTo: dragPoint, duration: 1.0) {

                    // Phase 4: Hand loslassen (0.2s) + Linie verschwindet + Planet fliegt weg
                    UIView.animate(withDuration: 0.15, animations: {
                        self.handImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        self.handImageView.alpha = 0.3
                        self.velocityLineLayer.opacity = 0
                    })
                    UIView.animate(withDuration: 0.55, delay: 0.05, options: .curveEaseIn, animations: {
                        self.ghostPlanet.center = landPoint
                        self.ghostPlanet.alpha = 0
                        self.ghostPlanet.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                    }) { _ in

                        // Phase 5: Hand verschwindet
                        UIView.animate(withDuration: 0.3, animations: {
                            self.handImageView.alpha = 0
                        }) { _ in
                            self.handImageView.transform = .identity
                            completion()
                        }
                    }
                }
            }
        }
    }

    /// Animiert die Hand von ihrer aktuellen Position zu `handTo` und aktualisiert
    /// dabei kontinuierlich die Velocity-Linie.
    private func animateDrag(from planetPoint: CGPoint, handTo endPoint: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        let startPoint = handImageView.center
        let startTime = CACurrentMediaTime()

        let displayLink = CADisplayLink(target: DisplayLinkProxy(block: { [weak self] in
            guard let self else { return }
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(elapsed / duration, 1.0)
            let easedProgress = self.easeInOut(t: progress)

            let currentX = startPoint.x + (endPoint.x - startPoint.x) * easedProgress
            let currentY = startPoint.y + (endPoint.y - startPoint.y) * easedProgress
            let currentHandPos = CGPoint(x: currentX, y: currentY)

            self.positionHand(at: currentHandPos)
            self.updateVelocityLine(from: planetPoint, to: currentHandPos)

        }), selector: #selector(DisplayLinkProxy.fire))
        displayLink.add(to: .main, forMode: .common)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayLink.invalidate()
            self.positionHand(at: endPoint)
            self.updateVelocityLine(from: planetPoint, to: endPoint)
            completion()
        }
    }

    // MARK: - Helpers

    private func positionHand(at point: CGPoint) {
        handImageView.frame = CGRect(
            x: point.x - 26,
            y: point.y - 52,
            width: 52,
            height: 52
        )
    }

    private func updateVelocityLine(from start: CGPoint, to end: CGPoint) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        // Kein impliziertes CAAnimation beim Path-Update
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        velocityLineLayer.path = path.cgPath
        CATransaction.commit()
    }

    private func easeInOut(t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }

    // MARK: - Dismiss

    @objc private func handleTap() {
        dismissOverlay(animated: true)
    }

    private func dismissOverlay(animated: Bool) {
        // Alle laufenden Animationen stoppen
        layer.removeAllAnimations()
        handImageView.layer.removeAllAnimations()
        ghostPlanet.layer.removeAllAnimations()

        let cleanup = {
            self.removeFromSuperview()
            self.onDismiss?()
        }
        if animated {
            UIView.animate(withDuration: 0.35, animations: {
                self.alpha = 0
            }, completion: { _ in cleanup() })
        } else {
            cleanup()
        }
    }
}

// MARK: - DisplayLinkProxy

/// Hilfsobjekt, um Retain-Cycles mit CADisplayLink zu vermeiden.
private class DisplayLinkProxy {
    private let block: () -> Void
    init(block: @escaping () -> Void) { self.block = block }
    @objc func fire() { block() }
}
