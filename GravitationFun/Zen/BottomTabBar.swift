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

  // Outer container using UIGlassContainerEffect so pill + selection can morph together
  private let containerView: UIVisualEffectView

  // The main glass pill background
  private let pillView: UIVisualEffectView

  // Sliding glass pill that highlights the active sun button
  private let selectionView: UIVisualEffectView

  private let stackView: UIStackView

  override init(frame: CGRect) {
    fastForwardButton = BottomTabBar.makeTabButton(icon: "forward")
    trashButton       = BottomTabBar.makeTabButton(icon: "trash")
    sun1Button        = BottomTabBar.makeTabButton(icon: "sun.max")
    sun2Button        = BottomTabBar.makeTabButton(icon: "sun.max")
    sun3Button        = BottomTabBar.makeTabButton(icon: "sun.max")
    starsButton       = BottomTabBar.makeTabButton(icon: "star")
    allButtons        = [fastForwardButton, trashButton, sun1Button, sun2Button, sun3Button, starsButton]
    sunButtons        = [sun1Button, sun2Button, sun3Button]

    // Glass container — lets pill and selection morph into each other
    let containerEffect = UIGlassContainerEffect()
    containerView = UIVisualEffectView(effect: containerEffect)
    containerView.translatesAutoresizingMaskIntoConstraints = false

    // Main pill with Liquid Glass
    let pillGlass = UIGlassEffect()
    pillGlass.isInteractive = false
    pillView = UIVisualEffectView(effect: pillGlass)
    pillView.translatesAutoresizingMaskIntoConstraints = false
    pillView.layer.cornerRadius = 28
    pillView.clipsToBounds = true

    // Selection indicator: a separate Liquid Glass pill behind the active sun button
    let selectionGlass = UIGlassEffect()
    selectionGlass.isInteractive = false
    selectionView = UIVisualEffectView(effect: selectionGlass)
    selectionView.layer.cornerRadius = 22
    selectionView.clipsToBounds = true
    selectionView.alpha = 0

    stackView = UIStackView(arrangedSubviews: allButtons)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    backgroundColor = .clear

    // Build hierarchy: containerView holds pillView; pillView holds selectionView + stackView
    addSubview(containerView)
    containerView.contentView.addSubview(pillView)
    pillView.contentView.addSubview(selectionView)
    pillView.contentView.addSubview(stackView)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

      pillView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
      pillView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
      pillView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
      pillView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),

      stackView.topAnchor.constraint(equalTo: pillView.contentView.topAnchor, constant: 4),
      stackView.leadingAnchor.constraint(equalTo: pillView.contentView.leadingAnchor, constant: 8),
      stackView.bottomAnchor.constraint(equalTo: pillView.contentView.bottomAnchor, constant: -4),
      stackView.trailingAnchor.constraint(equalTo: pillView.contentView.trailingAnchor, constant: -8),
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

  private static func makeTabButton(icon: String) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: icon)?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
    )
    config.baseForegroundColor = .white
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

    let button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

  // MARK: - Highlight helpers

  private func updateHighlights(animated: Bool) {
    // sun indices shifted by 2 (fastForward=0, trash=1, sun1=2, sun2=3, sun3=4, stars=5)
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
    guard let sunIdx = selectedSunIndex else {
      let hide = { self.selectionView.alpha = 0 }
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
      self.selectionView.frame = targetFrame
      self.selectionView.alpha = 1
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
    config.baseForegroundColor = dimmed ? UIColor.white.withAlphaComponent(0.40) : .white
    button.configuration = config
  }
}
