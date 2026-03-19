import UIKit

// MARK: - RadialMenuView

/// Floating Action Button mit Radialmenü.
/// Ersetzt die bisherige BottomTabBar. Der FAB sitzt unten rechts;
/// Tippen öffnet 4 Menü-Items als animierten Halbkreis nach oben-links.
class RadialMenuView: UIView {

  // MARK: - Public State

  var selectedSunCount: Int = 1 {
    didSet { updateSunButton() }
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

  // FAB – der Haupt-Button
  private let fabButton: UIButton

  // Dimming-View fängt Touches außerhalb ab
  private let dimmingView = UIView()

  // 4 Menü-Items: Sonne, Speed, Clear, Info
  private let sunButton: UIButton
  private let speedButton: UIButton
  private let clearButton: UIButton
  private let infoButton: UIButton
  private var menuItemButtons: [UIButton] = []

  // Glass-Hintergründe (clipView + containerView Pattern)
  private let fabClipView: UIView
  private let fabContainerView: UIVisualEffectView
  private let fabGlass: UIVisualEffectView

  // Radius und Winkel des Halbkreises
  private let menuRadius: CGFloat = 95
  // Winkel in Grad: von 180° (links) über 270° (oben) bis 315° (oben-rechts)
  // 4 Items verteilt von 195° bis 300°
  private let menuAngles: [CGFloat] = [195, 245, 270, 300]

  // MARK: - Init

  override init(frame: CGRect) {
    // FAB Glass Setup
    fabClipView = UIView()
    fabClipView.translatesAutoresizingMaskIntoConstraints = false
    fabClipView.layer.cornerRadius = 28
    fabClipView.layer.cornerCurve = .continuous
    fabClipView.clipsToBounds = true
    fabClipView.backgroundColor = .clear

    fabContainerView = UIVisualEffectView(effect: UIGlassContainerEffect())
    fabContainerView.translatesAutoresizingMaskIntoConstraints = false

    let fabEffect = UIGlassEffect()
    fabEffect.tintColor = UIColor.black.withAlphaComponent(0.55)
    fabEffect.isInteractive = true
    fabGlass = UIVisualEffectView(effect: fabEffect)
    fabGlass.translatesAutoresizingMaskIntoConstraints = false
    fabGlass.isUserInteractionEnabled = false

    // FAB Button (transparent, liegt über dem Glass)
    var fabConfig = UIButton.Configuration.plain()
    fabConfig.baseForegroundColor = .white
    fabButton = UIButton(configuration: fabConfig)
    fabButton.translatesAutoresizingMaskIntoConstraints = false

    // Menu Items
    sunButton   = RadialMenuView.makeMenuItem(icon: "sun.max.fill")
    speedButton = RadialMenuView.makeMenuItem(icon: "forward.fill")
    clearButton = RadialMenuView.makeMenuItem(icon: "trash.fill")
    infoButton  = RadialMenuView.makeMenuItem(icon: "info.circle.fill")

    super.init(frame: frame)

    backgroundColor = .clear
    isUserInteractionEnabled = true

    menuItemButtons = [sunButton, speedButton, clearButton, infoButton]

    setupDimmingView()
    setupFAB()
    setupMenuItems()
    updateSunButton()
    updateSpeedButton()
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - Setup

  private func setupDimmingView() {
    dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    dimmingView.isUserInteractionEnabled = false
    addSubview(dimmingView)
    NSLayoutConstraint.activate([
      dimmingView.topAnchor.constraint(equalTo: topAnchor),
      dimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
      dimmingView.bottomAnchor.constraint(equalTo: bottomAnchor),
      dimmingView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
    let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingTapped))
    dimmingView.addGestureRecognizer(tap)
  }

  private func setupFAB() {
    // Glass-Hierarchie aufbauen
    fabContainerView.contentView.addSubview(fabGlass)
    fabClipView.addSubview(fabContainerView)
    addSubview(fabClipView)
    addSubview(fabButton) // liegt über dem ClipView

    NSLayoutConstraint.activate([
      fabClipView.trailingAnchor.constraint(equalTo: trailingAnchor),
      fabClipView.bottomAnchor.constraint(equalTo: bottomAnchor),
      fabClipView.widthAnchor.constraint(equalToConstant: 56),
      fabClipView.heightAnchor.constraint(equalToConstant: 56),

      fabContainerView.topAnchor.constraint(equalTo: fabClipView.topAnchor),
      fabContainerView.leadingAnchor.constraint(equalTo: fabClipView.leadingAnchor),
      fabContainerView.bottomAnchor.constraint(equalTo: fabClipView.bottomAnchor),
      fabContainerView.trailingAnchor.constraint(equalTo: fabClipView.trailingAnchor),

      fabGlass.topAnchor.constraint(equalTo: fabContainerView.contentView.topAnchor),
      fabGlass.leadingAnchor.constraint(equalTo: fabContainerView.contentView.leadingAnchor),
      fabGlass.bottomAnchor.constraint(equalTo: fabContainerView.contentView.bottomAnchor),
      fabGlass.trailingAnchor.constraint(equalTo: fabContainerView.contentView.trailingAnchor),

      fabButton.topAnchor.constraint(equalTo: fabClipView.topAnchor),
      fabButton.leadingAnchor.constraint(equalTo: fabClipView.leadingAnchor),
      fabButton.bottomAnchor.constraint(equalTo: fabClipView.bottomAnchor),
      fabButton.trailingAnchor.constraint(equalTo: fabClipView.trailingAnchor),
    ])

    fabButton.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
  }

  private func setupMenuItems() {
    for button in menuItemButtons {
      button.alpha = 0
      button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
      addSubview(button)

      // Alle Items starten am FAB-Center (unten rechts)
      NSLayoutConstraint.activate([
        button.widthAnchor.constraint(equalToConstant: 48),
        button.heightAnchor.constraint(equalToConstant: 48),
        button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
      ])
    }

    sunButton.addTarget(self, action: #selector(sunTapped), for: .touchUpInside)
    speedButton.addTarget(self, action: #selector(speedTapped), for: .touchUpInside)
    clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
    infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
  }

  // MARK: - FAB Icon Update

  private func updateSunButton() {
    var config = sunButton.configuration ?? .plain()
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
    config.image = UIImage(systemName: "sun.max.fill", withConfiguration: symbolConfig)
    config.title = "\(selectedSunCount)"
    config.imagePlacement = .top
    config.imagePadding = 2
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { i in
      var o = i; o.font = UIFont.systemFont(ofSize: 10, weight: .bold); return o
    }
    sunButton.configuration = config
    updateFABIcon()
  }

  private func updateSpeedButton() {
    var config = speedButton.configuration ?? .plain()
    config.baseForegroundColor = isFastForwardOn ? UIColor.systemYellow : .white
    speedButton.configuration = config
  }

  private func updateFABIcon() {
    var config = fabButton.configuration ?? .plain()
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
    let iconName = isMenuOpen ? "xmark" : "sun.max.fill"
    config.image = UIImage(systemName: iconName, withConfiguration: symbolConfig)
    if !isMenuOpen {
      config.title = "\(selectedSunCount)"
      config.imagePlacement = .top
      config.imagePadding = 2
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { i in
        var o = i; o.font = UIFont.systemFont(ofSize: 10, weight: .bold); return o
      }
    } else {
      config.title = nil
      config.imagePlacement = .leading
    }
    config.baseForegroundColor = .white
    fabButton.configuration = config
  }

  // MARK: - Menu Toggle

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

    // FAB-Center in eigenen Koordinaten: unten rechts
    let fabCenter = CGPoint(x: bounds.width - 28, y: bounds.height - 28)

    UIView.animate(withDuration: 0.2) {
      self.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }

    for (index, button) in menuItemButtons.enumerated() {
      let angle = menuAngles[index] * .pi / 180
      let targetX = fabCenter.x + menuRadius * cos(angle)
      let targetY = fabCenter.y + menuRadius * sin(angle)

      let delay = Double(index) * 0.04
      UIView.animate(
        withDuration: 0.45,
        delay: delay,
        usingSpringWithDamping: 0.65,
        initialSpringVelocity: 0.5,
        options: [],
        animations: {
          button.alpha = 1
          button.transform = .identity
          // Offset vom FAB-Center
          let offsetX = targetX - (self.bounds.width - 28)
          let offsetY = targetY - (self.bounds.height - 28)
          button.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
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
          button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
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

  @objc private func infoTapped() {
    onInfoTapped?()
    closeMenu()
  }

  // MARK: - Factory

  private static func makeMenuItem(icon: String) -> UIButton {
    // Kleines Glass-Hintergrundview als Wrapper
    var config = UIButton.Configuration.plain()
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
    config.image = UIImage(systemName: icon, withConfiguration: symbolConfig)
    config.baseForegroundColor = .white
    config.background.backgroundColor = UIColor.white.withAlphaComponent(0.18)
    config.background.cornerRadius = 24
    config.background.strokeColor = UIColor.white.withAlphaComponent(0.25)
    config.background.strokeWidth = 0.5
    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOpacity = 0.35
    button.layer.shadowRadius = 8
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    return button
  }
}
