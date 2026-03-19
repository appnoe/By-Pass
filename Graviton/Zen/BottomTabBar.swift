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
  let infoButton: UIButton

  // Tracks selected sun index (0 = 1 sun, 1 = 2 suns, 2 = 3 suns), nil = none selected
  var selectedSunIndex: Int? = 0 {
    didSet { updateHighlights(animated: true) }
  }

  // Tracks whether fast-forward is active
  var isFastForwardOn: Bool = false {
    didSet { updateHighlights(animated: true) }
  }

  private let allButtons: [UIButton]
  private let sunButtons: [UIButton]

  // UIGlassContainerEffect: renders all child UIGlassEffect views in one combined pass
  private let containerView: UIVisualEffectView

  // Full-bar glass background
  private let pillGlass: UIVisualEffectView

  // Selection indicator: slides behind the active sun button
  private let selectionView: UIVisualEffectView

  private var selectionLeadingConstraint: NSLayoutConstraint?
  private var selectionWidthConstraint: NSLayoutConstraint?

  private let stackView: UIStackView

  override init(frame: CGRect) {
    fastForwardButton = BottomTabBar.makeTabButton(icon: "forward",  title: "Speed")
    trashButton       = BottomTabBar.makeTabButton(icon: "trash",    title: "Clear")
    sun1Button        = BottomTabBar.makeTabButton(icon: "sun.max",  title: "1 Sun")
    sun2Button        = BottomTabBar.makeTabButton(icon: "sun.max",  title: "2 Suns")
    sun3Button        = BottomTabBar.makeTabButton(icon: "sun.max",  title: "3 Suns")
    infoButton        = BottomTabBar.makeTabButton(icon: "info.circle", title: "Info")
    allButtons  = [fastForwardButton, trashButton, sun1Button, sun2Button, sun3Button, infoButton]
    sunButtons  = [sun1Button, sun2Button, sun3Button]

    containerView = UIVisualEffectView(effect: UIGlassContainerEffect())
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.layer.cornerRadius = 28
    containerView.layer.cornerCurve = .continuous
    containerView.clipsToBounds = true

    // Main pill glass — dark tint so it's visible on the black SpriteKit background.
    // isInteractive = true gives buttons the native scale+bounce response on tap.
    let pillEffect = UIGlassEffect()
    pillEffect.tintColor = UIColor.black.withAlphaComponent(0.55)
    pillEffect.isInteractive = true
    pillGlass = UIVisualEffectView(effect: pillEffect)
    pillGlass.translatesAutoresizingMaskIntoConstraints = false
    pillGlass.isUserInteractionEnabled = false

    // Selection pill — slightly lighter tint to stand out from the main pill
    let selectionEffect = UIGlassEffect()
    selectionEffect.tintColor = UIColor.white.withAlphaComponent(0.15)
    selectionView = UIVisualEffectView(effect: selectionEffect)
    selectionView.translatesAutoresizingMaskIntoConstraints = false
    selectionView.layer.cornerRadius = 20
    selectionView.layer.cornerCurve = .continuous
    selectionView.clipsToBounds = true
    selectionView.alpha = 0

    stackView = UIStackView(arrangedSubviews: allButtons)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    backgroundColor = .clear

    // Hierarchy: pillGlass (back) → selectionView → stackView (front),
    // all direct children of containerView.contentView so UIGlassContainerEffect merges them
    containerView.contentView.addSubview(pillGlass)
    containerView.contentView.addSubview(selectionView)
    containerView.contentView.addSubview(stackView)
    addSubview(containerView)

    let selectionLeading = selectionView.leadingAnchor.constraint(
      equalTo: containerView.contentView.leadingAnchor, constant: 8)
    let selectionWidth = selectionView.widthAnchor.constraint(equalToConstant: 60)
    selectionLeadingConstraint = selectionLeading
    selectionWidthConstraint   = selectionWidth

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
    var activeIndices: Set<Int> = []
    if isFastForwardOn { activeIndices.insert(0) }
    if let sunIdx = selectedSunIndex {
      activeIndices.insert(2 + sunIdx)
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
    let stackInset: CGFloat = 8
    let newLeading = stackInset + targetButton.frame.origin.x + 2
    let newWidth   = targetButton.frame.width - 4

    let update = {
      self.selectionLeadingConstraint?.constant = newLeading
      self.selectionWidthConstraint?.constant   = newWidth
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
