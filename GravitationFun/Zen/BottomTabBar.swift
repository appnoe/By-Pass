//  BottomTabBar.swift

import UIKit

// MARK: - BottomTabBar

class BottomTabBar: UIView {

  // Publicly accessible buttons in order: trash, sun1, sun2, sun3, stars
  let trashButton: UIButton
  let sun1Button: UIButton
  let sun2Button: UIButton
  let sun3Button: UIButton
  let starsButton: UIButton

  // Tracks whether stars is toggled on
  var isStarsOn: Bool = true {
    didSet { updateHighlights(animated: true) }
  }

  // Tracks selected sun index (0 = 1 sun, 1 = 2 suns, 2 = 3 suns), nil = none selected
  var selectedSunIndex: Int? = 0 {
    didSet { updateHighlights(animated: true) }
  }

  private let allButtons: [UIButton]
  private let sunButtons: [UIButton]

  // Dark blurred pill background — matches Music app
  private let pillBackground: UIVisualEffectView

  // Rounded rect that slides behind the active sun button
  private let selectionBackground: UIView

  private let stackView: UIStackView

  override init(frame: CGRect) {
    trashButton = BottomTabBar.makeTabButton(icon: "trash",   title: "Clear")
    sun1Button  = BottomTabBar.makeTabButton(icon: "sun.max", title: "1 Sun")
    sun2Button  = BottomTabBar.makeTabButton(icon: "sun.max", title: "2 Suns")
    sun3Button  = BottomTabBar.makeTabButton(icon: "sun.max", title: "3 Suns")
    starsButton = BottomTabBar.makeTabButton(icon: "star",    title: "Stars")
    allButtons  = [trashButton, sun1Button, sun2Button, sun3Button, starsButton]
    sunButtons  = [sun1Button, sun2Button, sun3Button]

    // Dark translucent pill — same dark frosted look as Music app tab bar
    pillBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    pillBackground.translatesAutoresizingMaskIntoConstraints = false
    pillBackground.layer.cornerRadius = 28
    pillBackground.clipsToBounds = true

    // Selection indicator: slightly lighter dark rounded rect
    selectionBackground = UIView()
    selectionBackground.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    selectionBackground.layer.cornerRadius = 20
    selectionBackground.alpha = 0

    stackView = UIStackView(arrangedSubviews: allButtons)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    backgroundColor = .clear

    pillBackground.contentView.addSubview(selectionBackground)
    pillBackground.contentView.addSubview(stackView)
    addSubview(pillBackground)

    NSLayoutConstraint.activate([
      pillBackground.topAnchor.constraint(equalTo: topAnchor),
      pillBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
      pillBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
      pillBackground.trailingAnchor.constraint(equalTo: trailingAnchor),

      stackView.topAnchor.constraint(equalTo: pillBackground.contentView.topAnchor, constant: 6),
      stackView.leadingAnchor.constraint(equalTo: pillBackground.contentView.leadingAnchor, constant: 8),
      stackView.bottomAnchor.constraint(equalTo: pillBackground.contentView.bottomAnchor, constant: -6),
      stackView.trailingAnchor.constraint(equalTo: pillBackground.contentView.trailingAnchor, constant: -8),
    ])

    for button in allButtons {
      setDim(button, dimmed: true)
    }
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()
    updateHighlights(animated: false)
  }

  // MARK: - Factory

  private static func makeTabButton(icon: String, title: String) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: icon)?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
    )
    config.title = title
    config.imagePlacement = .top
    config.imagePadding = 4
    config.baseForegroundColor = .white
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = UIFont.systemFont(ofSize: 10, weight: .medium)
      return outgoing
    }

    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

  // MARK: - Highlight helpers

  private func updateHighlights(animated: Bool) {
    var activeIndices: Set<Int> = []
    if let sunIdx = selectedSunIndex {
      activeIndices.insert(1 + sunIdx) // sun1=1, sun2=2, sun3=3
    }
    if isStarsOn {
      activeIndices.insert(4)
    }

    for (i, button) in allButtons.enumerated() {
      setDim(button, dimmed: !activeIndices.contains(i))
    }

    positionSelection(animated: animated)
  }

  private func positionSelection(animated: Bool) {
    guard let sunIdx = selectedSunIndex else {
      let hide = { self.selectionBackground.alpha = 0 }
      animated ? UIView.animate(withDuration: 0.25, animations: hide) : hide()
      return
    }

    let targetButton = sunButtons[sunIdx]
    let buttonFrame = targetButton.frame
    let stackOrigin = stackView.frame.origin
    let targetFrame = CGRect(
      x: stackOrigin.x + buttonFrame.origin.x + 2,
      y: stackOrigin.y + buttonFrame.origin.y + 2,
      width: buttonFrame.width - 4,
      height: buttonFrame.height - 4
    )

    let show = {
      self.selectionBackground.frame = targetFrame
      self.selectionBackground.alpha = 1
    }

    if animated {
      UIView.animate(withDuration: 0.3, delay: 0,
                     usingSpringWithDamping: 0.8, initialSpringVelocity: 0,
                     animations: show)
    } else {
      show()
    }
  }

  private func setDim(_ button: UIButton, dimmed: Bool) {
    var config = button.configuration ?? .plain()
    config.baseForegroundColor = dimmed ? UIColor.white.withAlphaComponent(0.45) : .white
    button.configuration = config
  }
}
