//  BottomTabBar.swift
//

import UIKit

// MARK: - Tab item definition

struct BottomTabItem {
  let icon: UIImage?
  let title: String
}

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
    didSet { updateStarsHighlight() }
  }

  // Tracks selected sun index (0 = 1 sun, 1 = 2 suns, 2 = 3 suns), nil = none selected
  var selectedSunIndex: Int? = 0 {
    didSet { updateSunHighlights() }
  }

  private let sunButtons: [UIButton]
  private let glassContainerView: UIVisualEffectView

  override init(frame: CGRect) {
    // Build each tab button with icon + label below
    trashButton   = BottomTabBar.makeTabButton(icon: "trash",        title: "Clear")
    sun1Button    = BottomTabBar.makeTabButton(icon: "sun.max",      title: "1 Sun")
    sun2Button    = BottomTabBar.makeTabButton(icon: "sun.max",      title: "2 Suns")
    sun3Button    = BottomTabBar.makeTabButton(icon: "sun.max",      title: "3 Suns")
    starsButton   = BottomTabBar.makeTabButton(icon: "star",         title: "Stars")
    sunButtons    = [sun1Button, sun2Button, sun3Button]

    // Outer container with Liquid Glass pill background
    let containerEffect = UIGlassContainerEffect()
    glassContainerView = UIVisualEffectView(effect: containerEffect)
    glassContainerView.translatesAutoresizingMaskIntoConstraints = false
    glassContainerView.layer.cornerRadius = 28
    glassContainerView.clipsToBounds = true

    super.init(frame: frame)

    backgroundColor = .clear

    // Each button gets its own UIGlassEffect inside the container
    let items: [UIButton] = [trashButton, sun1Button, sun2Button, sun3Button, starsButton]
    for button in items {
      let glassItem = UIVisualEffectView(effect: UIGlassEffect())
      glassItem.translatesAutoresizingMaskIntoConstraints = false
      glassItem.layer.cornerRadius = 22
      glassItem.clipsToBounds = true
      glassItem.isUserInteractionEnabled = false
      glassItem.tag = 99  // mark as background layer
      button.insertSubview(glassItem, at: 0)
      NSLayoutConstraint.activate([
        glassItem.topAnchor.constraint(equalTo: button.topAnchor),
        glassItem.leadingAnchor.constraint(equalTo: button.leadingAnchor),
        glassItem.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        glassItem.trailingAnchor.constraint(equalTo: button.trailingAnchor),
      ])
    }

    // Stack buttons horizontally inside the container's contentView
    let stackView = UIStackView(arrangedSubviews: items)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 4
    stackView.translatesAutoresizingMaskIntoConstraints = false

    glassContainerView.contentView.addSubview(stackView)

    addSubview(glassContainerView)

    NSLayoutConstraint.activate([
      glassContainerView.topAnchor.constraint(equalTo: topAnchor),
      glassContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      glassContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      glassContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),

      stackView.topAnchor.constraint(equalTo: glassContainerView.contentView.topAnchor, constant: 8),
      stackView.leadingAnchor.constraint(equalTo: glassContainerView.contentView.leadingAnchor, constant: 8),
      stackView.bottomAnchor.constraint(equalTo: glassContainerView.contentView.bottomAnchor, constant: -8),
      stackView.trailingAnchor.constraint(equalTo: glassContainerView.contentView.trailingAnchor, constant: -8),
    ])

    updateSunHighlights()
    updateStarsHighlight()
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - Factory

  private static func makeTabButton(icon: String, title: String) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: icon)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
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

  private func updateSunHighlights() {
    for (index, button) in sunButtons.enumerated() {
      let isSelected = selectedSunIndex == index
      setHighlight(button, active: isSelected)
    }
  }

  private func updateStarsHighlight() {
    setHighlight(starsButton, active: isStarsOn)
  }

  private func setHighlight(_ button: UIButton, active: Bool) {
    // Find the glass background layer (tagged 99) and swap effect
    if let glassView = button.subviews.first(where: { $0.tag == 99 }) as? UIVisualEffectView {
      glassView.effect = active ? UIGlassEffect() : nil
      glassView.alpha = active ? 1.0 : 0.0
    }
    var config = button.configuration ?? .plain()
    config.baseForegroundColor = active ? .white : UIColor.white.withAlphaComponent(0.5)
    button.configuration = config
  }
}
