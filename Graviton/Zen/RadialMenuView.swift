import UIKit

// MARK: - RadialMenuView

/// Floating Action Button mit Radialmenü.
/// Der FAB sitzt unten rechts; Tippen öffnet 4 Menü-Items als animierten
/// Halbkreis nach oben-links.
class RadialMenuView: UIView {

  // MARK: - Public State

  var selectedSunCount: Int = 1 {
    didSet { updateSunButton(); updateFABIcon() }
  }

  var isFastForwardOn: Bool = false {
    didSet { updateSpeedButton() }
  }

  // MARK: - Callbacks

  var onFastForwardToggled: (() -> Void)?
  var onClearTapped: (() -> Void)?
  var onSunCountChanged: ((Int) -> Void)?
  var onInfoTapped: (() -> Void)?

  // MARK: - Private

  private var isMenuOpen = false

  private let fabButton: UIButton
  private let dimmingView = UIView()

  // Reihenfolge: sun, speed, clear, info
  private let sunButton:   UIButton
  private let speedButton: UIButton
  private let clearButton: UIButton
  private let infoButton:  UIButton
  private var menuItemButtons: [UIButton] = []

  // Glass-Hintergrund für den FAB
  private let fabClipView: UIView
  private let fabContainerView: UIVisualEffectView
  private let fabGlass: UIVisualEffectView

  private let fabSize: CGFloat = 56
  private let itemSize: CGFloat = 48
  private let menuRadius: CGFloat = 90
  // Winkel in Grad, gegen Uhrzeigersinn: 0° = rechts, 90° = oben
  // Fächer von 120° bis 210° (links-oben)
  private let menuAngles: [CGFloat] = [210, 160, 110, 60]

  // MARK: - Init

  override init(frame: CGRect) {
    fabClipView = UIView()
    fabClipView.layer.cornerRadius = fabSize / 2
    fabClipView.layer.cornerCurve = .continuous
    fabClipView.clipsToBounds = true
    fabClipView.backgroundColor = .clear

    fabContainerView = UIVisualEffectView(effect: UIGlassContainerEffect())

    let fabEffect = UIGlassEffect()
    fabEffect.tintColor = UIColor.black.withAlphaComponent(0.6)
    fabEffect.isInteractive = true
    fabGlass = UIVisualEffectView(effect: fabEffect)
    fabGlass.isUserInteractionEnabled = false

    var fabConfig = UIButton.Configuration.plain()
    fabConfig.baseForegroundColor = .white
    fabButton = UIButton(configuration: fabConfig)

    sunButton   = RadialMenuView.makeMenuItem(icon: "sun.max.fill")
    speedButton = RadialMenuView.makeMenuItem(icon: "forward.fill")
    clearButton = RadialMenuView.makeMenuItem(icon: "trash.fill")
    infoButton  = RadialMenuView.makeMenuItem(icon: "info.circle.fill")

    super.init(frame: frame)

    backgroundColor = .clear
    menuItemButtons = [sunButton, speedButton, clearButton, infoButton]

    // Dimming
    dimmingView.backgroundColor = .clear
    dimmingView.isUserInteractionEnabled = false
    addSubview(dimmingView)
    let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingTapped))
    dimmingView.addGestureRecognizer(tap)

    // Menu items — kein Auto Layout, Frames werden in layoutSubviews gesetzt
    for button in menuItemButtons {
      button.alpha = 0
      button.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
      addSubview(button)
    }

    // FAB Glass
    fabContainerView.contentView.addSubview(fabGlass)
    fabClipView.addSubview(fabContainerView)
    addSubview(fabClipView)
    addSubview(fabButton)
    fabButton.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)

    sunButton.addTarget(self,   action: #selector(sunTapped),   for: .touchUpInside)
    speedButton.addTarget(self, action: #selector(speedTapped), for: .touchUpInside)
    clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
    infoButton.addTarget(self,  action: #selector(infoTapped_), for: .touchUpInside)

    updateSunButton()
    updateSpeedButton()
    updateFABIcon()
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    dimmingView.frame = bounds

    let fabOrigin = CGPoint(x: bounds.width - fabSize, y: bounds.height - fabSize)
    fabClipView.frame = CGRect(origin: fabOrigin, size: CGSize(width: fabSize, height: fabSize))
    fabContainerView.frame = fabClipView.bounds
    fabGlass.frame = fabContainerView.contentView.bounds
    fabButton.frame = fabClipView.frame

    // Menu-Items: Startposition = FAB-Center
    let fabCenter = CGPoint(x: bounds.width - fabSize / 2, y: bounds.height - fabSize / 2)
    for button in menuItemButtons {
      button.frame = CGRect(
        x: fabCenter.x - itemSize / 2,
        y: fabCenter.y - itemSize / 2,
        width: itemSize,
        height: itemSize
      )
    }
  }

  // MARK: - FAB Icon

  private func updateFABIcon() {
    var config = fabButton.configuration ?? .plain()
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
    if isMenuOpen {
      config.image = UIImage(systemName: "xmark", withConfiguration: symbolConfig)
      config.title = nil
      config.imagePlacement = .leading
    } else {
      config.image = UIImage(systemName: "sun.max.fill", withConfiguration: symbolConfig)
      config.title = "\(selectedSunCount)"
      config.imagePlacement = .top
      config.imagePadding = 2
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { i in
        var o = i; o.font = UIFont.systemFont(ofSize: 10, weight: .bold); return o
      }
    }
    config.baseForegroundColor = .white
    fabButton.configuration = config
  }

  private func updateSunButton() {
    var config = sunButton.configuration ?? .plain()
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    config.image = UIImage(systemName: "sun.max.fill", withConfiguration: symbolConfig)
    config.title = "\(selectedSunCount)"
    config.imagePlacement = .top
    config.imagePadding = 2
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { i in
      var o = i; o.font = UIFont.systemFont(ofSize: 10, weight: .bold); return o
    }
    sunButton.configuration = config
  }

  private func updateSpeedButton() {
    var config = speedButton.configuration ?? .plain()
    config.baseForegroundColor = isFastForwardOn ? UIColor.systemYellow : .white
    speedButton.configuration = config
  }

  // MARK: - Menu Open/Close

  @objc private func fabTapped() {
    isMenuOpen ? closeMenu() : openMenu()
  }

  @objc private func dimmingTapped() {
    closeMenu()
  }

  func openMenu() {
    guard !isMenuOpen else { return }
    isMenuOpen = true
    updateFABIcon()
    dimmingView.isUserInteractionEnabled = true

    UIView.animate(withDuration: 0.2) {
      self.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.25)
    }

    let fabCenter = CGPoint(x: bounds.width - fabSize / 2, y: bounds.height - fabSize / 2)

    for (index, button) in menuItemButtons.enumerated() {
      // Zielposition auf dem Kreisbogen
      let angleDeg = menuAngles[index]
      let angleRad = angleDeg * .pi / 180
      let targetCenter = CGPoint(
        x: fabCenter.x + menuRadius * cos(angleRad),
        y: fabCenter.y - menuRadius * sin(angleRad) // Y invertiert (UIKit: nach unten = positiv)
      )
      let targetFrame = CGRect(
        x: targetCenter.x - itemSize / 2,
        y: targetCenter.y - itemSize / 2,
        width: itemSize,
        height: itemSize
      )

      let delay = Double(index) * 0.05
      UIView.animate(
        withDuration: 0.5,
        delay: delay,
        usingSpringWithDamping: 0.65,
        initialSpringVelocity: 0.5,
        options: [],
        animations: {
          button.alpha = 1
          button.transform = .identity
          button.frame = targetFrame
        }
      )
    }
  }

  func closeMenu() {
    guard isMenuOpen else { return }
    isMenuOpen = false
    updateFABIcon()
    dimmingView.isUserInteractionEnabled = false

    UIView.animate(withDuration: 0.15) {
      self.dimmingView.backgroundColor = .clear
    }

    let fabCenter = CGPoint(x: bounds.width - fabSize / 2, y: bounds.height - fabSize / 2)
    let homeFrame = CGRect(
      x: fabCenter.x - itemSize / 2,
      y: fabCenter.y - itemSize / 2,
      width: itemSize,
      height: itemSize
    )

    for (index, button) in menuItemButtons.enumerated().reversed() {
      let delay = Double(menuItemButtons.count - 1 - index) * 0.03
      UIView.animate(
        withDuration: 0.25,
        delay: delay,
        usingSpringWithDamping: 0.8,
        initialSpringVelocity: 0,
        options: [],
        animations: {
          button.alpha = 0
          button.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
          button.frame = homeFrame
        }
      )
    }
  }

  // MARK: - Actions

  @objc private func sunTapped() {
    selectedSunCount = selectedSunCount % 3 + 1
    onSunCountChanged?(selectedSunCount)
    closeMenu()
  }

  @objc private func speedTapped() {
    onFastForwardToggled?()
    closeMenu()
  }

  @objc private func clearTapped() {
    onClearTapped?()
    closeMenu()
  }

  @objc private func infoTapped_() {
    onInfoTapped?()
    closeMenu()
  }

  // MARK: - Factory

  private static func makeMenuItem(icon: String) -> UIButton {
    var config = UIButton.Configuration.plain()
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
    config.image = UIImage(systemName: icon, withConfiguration: symbolConfig)
    config.baseForegroundColor = .white
    config.background.backgroundColor = UIColor.white.withAlphaComponent(0.18)
    config.background.cornerRadius = 24
    config.background.strokeColor = UIColor.white.withAlphaComponent(0.3)
    config.background.strokeWidth = 0.5
    let button = UIButton(configuration: config)
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOpacity = 0.4
    button.layer.shadowRadius = 6
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    return button
  }
}
