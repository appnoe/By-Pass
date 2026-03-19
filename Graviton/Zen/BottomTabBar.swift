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
  private let stackView: UIStackView

  override init(frame: CGRect) {
    fastForwardButton = BottomTabBar.makeTabButton(icon: "forward",     title: "Speed")
    trashButton       = BottomTabBar.makeTabButton(icon: "trash",       title: "Clear")
    sun1Button        = BottomTabBar.makeTabButton(icon: "sun.max",     title: "1 Sun")
    sun2Button        = BottomTabBar.makeTabButton(icon: "sun.max",     title: "2 Suns")
    sun3Button        = BottomTabBar.makeTabButton(icon: "sun.max",     title: "3 Suns")
    infoButton        = BottomTabBar.makeTabButton(icon: "info.circle", title: "Info")
    allButtons = [fastForwardButton, trashButton, sun1Button, sun2Button, sun3Button, infoButton]

    stackView = UIStackView(arrangedSubviews: allButtons)
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    backgroundColor = .clear
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
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
    var config = UIButton.Configuration.clearGlass()
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

    let update = {
      for (i, button) in self.allButtons.enumerated() {
        self.setDim(button, dimmed: !activeIndices.contains(i))
      }
    }

    if animated {
      UIView.animate(withDuration: 0.25, animations: update)
    } else {
      update()
    }
  }

  private func setDim(_ button: UIButton, dimmed: Bool) {
    button.alpha = dimmed ? 0.45 : 1.0
  }
}
