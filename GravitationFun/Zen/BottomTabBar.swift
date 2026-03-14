//  BottomTabBar.swift

import UIKit

// MARK: - BottomTabBar

class BottomTabBar: UIView {

  // Publicly accessible buttons
  let fastForwardButton: UIButton
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

  // UIGlassContainerEffect wraps the whole bar so child glass elements merge
  private let containerView: UIVisualEffectView

  // Full-bar glass background (gives the pill its frosted look)
  private let pillGlass: UIVisualEffectView

  // Selection indicator: a UIGlassEffect pill that slides behind the active sun button
  private let selectionView: UIVisualEffectView

  // Leading constraint of selectionView — animated on tab change
  private var selectionLeadingConstraint: NSLayoutConstraint?
  private var selectionWidthConstraint: NSLayoutConstraint?

  private let stackView: UIStackView

  override init(frame: CGRect) {
    fastForwardButton = BottomTabBar.makeTabButton(icon: "forward",  title: "Speed")
    trashButton       = BottomTabBar.makeTabButton(icon: "trash",    title: "Clear")
    sun1Button        = BottomTabBar.makeTabButton(icon: "sun.max",  title: "1 Sun")
    sun2Button        = BottomTabBar.makeTabButton(icon: "sun.max",  title: "2 Suns")
    sun3Button        = BottomTabBar.makeTabButton(icon: "sun.max",  title: "3 Suns")
    starsButton       = BottomTabBar.makeTabButton(icon: "star",     title: "Stars")
    allButtons  = [fastForwardButton, trashButton, sun1Button, sun2Button, sun3Button, starsButton]
    sunButtons  = [sun1Button, sun2Button, sun3Button]

    // Container merges all child UIGlassEffect views into one combined render pass
    containerView = UIVisualEffectView(effect: UIGlassContainerEffect())
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.layer.cornerRadius = 28
    containerView.clipsToBounds = true

    // Full-bar frosted glass background — lives as direct child of containerView.contentView
    pillGlass = UIVisualEffectView(effect: UIGlassEffect())
    pillGlass.translatesAutoresizingMaskIntoConstraints = false
    pillGlass.isUserInteractionEnabled = false

    // Selection pill — also a direct child of containerView.contentView so it merges
    let selectionEffect = UIGlassEffect()
    selectionEffect.isInteractive = false
    selectionView = UIVisualEffectView(effect: selectionEffect)
    selectionView.translatesAutoresizingMaskIntoConstraints = false
    selectionView.layer.cornerRadius = 20
    selectionView.clipsToBounds = true
    selectionView.alpha = 0

    stackView = UIStackView(arrangedSubviews: allButtons)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    backgroundColor = .clear

    // Layer order: pillGlass (back) → selectionView → stackView (front)
    containerView.contentView.addSubview(pillGlass)
    containerView.contentView.addSubview(selectionView)
    containerView.contentView.addSubview(stackView)
    addSubview(containerView)

    let selectionLeading = selectionView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor, constant: 8)
    let selectionWidth = selectionView.widthAnchor.constraint(equalToConstant: 60)
    selectionLeadingConstraint = selectionLeading
    selectionWidthConstraint = selectionWidth

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

      pillGlass.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
      pillGlass.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
      pillGlass.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
      pillGlass.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),

      selectionView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 4),
      selectionView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor, constant: -4),
      selectionLeading,
      selectionWidth,

      stackView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 6),
      stackView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor, constant: 8),
      stackView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor, constant: -6),
      stackView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor, constant: -8),
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
    // fastForward=0, trash=1, sun1=2, sun2=3, sun3=4, stars=5
    var activeIndices: Set<Int> = []
    if let sunIdx = selectedSunIndex {
      activeIndices.insert(2 + sunIdx)
    }
    if isStarsOn {
      activeIndices.insert(5)
    }

    for (i, button) in allButtons.enumerated() {
      setDim(button, dimmed: !activeIndices.contains(i))
    }

    positionSelection(animated: animated)
  }

  private func positionSelection(animated: Bool) {
    guard let sunIdx = selectedSunIndex,
          stackView.frame.width > 0 else {
      let hide = { self.selectionView.alpha = 0 }
      animated ? UIView.animate(withDuration: 0.25, animations: hide) : hide()
      return
    }

    let targetButton = sunButtons[sunIdx]
    // Button frame is in stackView coordinates; stackView starts at x=8 in contentView
    let stackInset: CGFloat = 8
    let buttonWidth = targetButton.frame.width
    let newLeading = stackInset + targetButton.frame.origin.x + 2
    let newWidth = buttonWidth - 4

    let update = {
      self.selectionLeadingConstraint?.constant = newLeading
      self.selectionWidthConstraint?.constant = newWidth
      self.selectionView.alpha = 1
      self.containerView.contentView.layoutIfNeeded()
    }

    if animated {
      UIView.animate(withDuration: 0.35, delay: 0,
                     usingSpringWithDamping: 0.75, initialSpringVelocity: 0,
                     animations: update)
    } else {
      update()
    }
  }

  private func setDim(_ button: UIButton, dimmed: Bool) {
    var config = button.configuration ?? .plain()
    config.baseForegroundColor = dimmed ? UIColor.white.withAlphaComponent(0.45) : .white
    button.configuration = config
  }
}
