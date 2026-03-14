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

  // Single glass container wrapping the whole bar
  private let containerView: UIVisualEffectView

  // A single highlight view that sits inside the container's contentView
  // and moves behind whichever button is active
  private let highlightView: UIVisualEffectView

  // Stack view holding the buttons — we need a reference to position the highlight
  private let stackView: UIStackView

  override init(frame: CGRect) {
    trashButton = BottomTabBar.makeTabButton(icon: "trash",   title: "Clear")
    sun1Button  = BottomTabBar.makeTabButton(icon: "sun.max", title: "1 Sun")
    sun2Button  = BottomTabBar.makeTabButton(icon: "sun.max", title: "2 Suns")
    sun3Button  = BottomTabBar.makeTabButton(icon: "sun.max", title: "3 Suns")
    starsButton = BottomTabBar.makeTabButton(icon: "star",    title: "Stars")
    allButtons  = [trashButton, sun1Button, sun2Button, sun3Button, starsButton]
    sunButtons  = [sun1Button, sun2Button, sun3Button]

    // Outer container: one unified Liquid Glass pill
    let containerEffect = UIGlassContainerEffect()
    containerView = UIVisualEffectView(effect: containerEffect)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.layer.cornerRadius = 28
    containerView.clipsToBounds = true

    // Highlight: a single UIGlassEffect view that goes behind the active button
    // It lives inside containerView.contentView so it merges with the container
    let highlightEffect = UIGlassEffect()
    highlightEffect.isInteractive = false
    highlightView = UIVisualEffectView(effect: highlightEffect)
    highlightView.translatesAutoresizingMaskIntoConstraints = false
    highlightView.layer.cornerRadius = 20
    highlightView.clipsToBounds = true
    highlightView.alpha = 0

    // Stack of buttons inside the container
    stackView = UIStackView(arrangedSubviews: allButtons)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    backgroundColor = .clear

    // Full-size glass background so the pill is visibly frosted
    let backgroundGlass = UIVisualEffectView(effect: UIGlassEffect())
    backgroundGlass.translatesAutoresizingMaskIntoConstraints = false
    backgroundGlass.isUserInteractionEnabled = false

    // Layer order inside containerView.contentView: background → highlight → stack
    containerView.contentView.addSubview(backgroundGlass)
    containerView.contentView.addSubview(highlightView)
    containerView.contentView.addSubview(stackView)
    addSubview(containerView)

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

      backgroundGlass.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
      backgroundGlass.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
      backgroundGlass.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
      backgroundGlass.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),

      stackView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 6),
      stackView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor, constant: 8),
      stackView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor, constant: -6),
      stackView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor, constant: -8),
    ])

    // Dim all buttons initially; highlights will be set after layout
    for button in allButtons {
      setDim(button, dimmed: true)
    }
  }

  required init?(coder: NSCoder) { fatalError() }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()
    // Position highlight without animation on first layout
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
    // Determine which buttons should be bright
    var activeIndices: Set<Int> = []
    if let sunIdx = selectedSunIndex {
      activeIndices.insert(1 + sunIdx) // sun1=index1, sun2=index2, sun3=index3
    }
    if isStarsOn {
      activeIndices.insert(4) // starsButton is index 4
    }

    for (i, button) in allButtons.enumerated() {
      setDim(button, dimmed: !activeIndices.contains(i))
    }

    // Move highlight to the active sun button (stars doesn't move the pill highlight,
    // it just brightens — the pill highlight follows the sun selection)
    positionHighlight(animated: animated)
  }

  private func positionHighlight(animated: Bool) {
    guard let sunIdx = selectedSunIndex else {
      // No sun selected — hide highlight
      let hide = { self.highlightView.alpha = 0 }
      animated ? UIView.animate(withDuration: 0.3, animations: hide) : hide()
      return
    }

    let targetButton = sunButtons[sunIdx]
    // Convert button frame into the containerView.contentView coordinate space
    let buttonFrameInStack = targetButton.frame
    let stackOriginInContent = stackView.frame.origin
    let targetFrame = CGRect(
      x: stackOriginInContent.x + buttonFrameInStack.origin.x + 2,
      y: stackOriginInContent.y + buttonFrameInStack.origin.y + 2,
      width: buttonFrameInStack.width - 4,
      height: buttonFrameInStack.height - 4
    )

    let show = {
      self.highlightView.frame = targetFrame
      self.highlightView.alpha = 1
    }

    if animated {
      UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, animations: show)
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
