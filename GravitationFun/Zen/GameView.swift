//  Created by Dominik Hauser on 28.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import UIKit
import SpriteKit

class GameView: UIView {

  let skView: SKView
  let settingsView: SettingsView
  var leadingSettingsConstraint: NSLayoutConstraint?
  let zoomStepper: UIStepper
  let zoomLabel: UILabel
  let zoomStackView: UIStackView
  let fastForwardButton: UIButton
  let satellitesCountLabel: UILabel

  override init(frame: CGRect) {

    skView = SKView(frame: frame)
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.isMultipleTouchEnabled = true

    settingsView = SettingsView()
    settingsView.translatesAutoresizingMaskIntoConstraints = false

    zoomStepper = UIStepper()
    zoomStepper.minimumValue = 0.05
    zoomStepper.maximumValue = 1.25
    zoomStepper.stepValue = 0.25
    zoomStepper.value = 1.0
    zoomStepper.setDecrementImage(UIImage(systemName: "minus.magnifyingglass"), for: .normal)
    zoomStepper.setIncrementImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)

    zoomLabel = UILabel()
    zoomLabel.font = .systemFont(ofSize: 13)
    zoomLabel.textColor = .label
    zoomLabel.textAlignment = .center

    zoomStackView = UIStackView(arrangedSubviews: [zoomLabel, zoomStepper])
    zoomStackView.translatesAutoresizingMaskIntoConstraints = false
    zoomStackView.spacing = 10
    zoomStackView.axis = .vertical
    zoomStackView.isHidden = true

    fastForwardButton = UIButton(configuration: .glass())
    fastForwardButton.translatesAutoresizingMaskIntoConstraints = false
    fastForwardButton.setImage(UIImage(systemName: "forward"), for: .normal)

    satellitesCountLabel = UILabel()
    satellitesCountLabel.translatesAutoresizingMaskIntoConstraints = false
    satellitesCountLabel.text = "0"
    satellitesCountLabel.textColor = .secondaryLabel

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = 120

//    #if DEBUG
//    skView.showsFPS = true
//    skView.showsNodeCount = true
//    #endif
    
    addSubview(skView)
    addSubview(settingsView)
    addSubview(zoomStackView)
    addSubview(fastForwardButton)
    addSubview(satellitesCountLabel)

    // Initially hide the settings content (panel starts collapsed)
    settingsView.settingsContentView.isHidden = true

    let leadingSettingsConstraint = settingsView.showHideButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)

    NSLayoutConstraint.activate([
      settingsView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      leadingSettingsConstraint,

      zoomStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
      zoomStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),

      fastForwardButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
      fastForwardButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
      fastForwardButton.widthAnchor.constraint(equalToConstant: 44),
      fastForwardButton.heightAnchor.constraint(equalTo: fastForwardButton.widthAnchor),

      satellitesCountLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
      satellitesCountLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20)
    ])

    self.leadingSettingsConstraint = leadingSettingsConstraint
  }

  required init?(coder: NSCoder) { fatalError() }

  func toggleSettings() {
    guard let leadingSettingsConstraint = leadingSettingsConstraint else { return }

    let button = settingsView.showHideButton
    let isExpanded = leadingSettingsConstraint.constant > 21

    if isExpanded {
      // Collapse: hide panel content, move button back to left edge
      UIView.animate(withDuration: 0.25) {
        self.settingsView.settingsContentView.alpha = 0
      } completion: { _ in
        self.settingsView.settingsContentView.isHidden = true
        leadingSettingsConstraint.constant = 12
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        UIView.animate(withDuration: 0.3) {
          self.layoutIfNeeded()
        }
      }
    } else {
      // Expand: show panel content
      settingsView.settingsContentView.alpha = 0
      settingsView.settingsContentView.isHidden = false
      if let convertedOrigin = button.superview?.convert(button.frame.origin, to: settingsView) {
        leadingSettingsConstraint.constant = convertedOrigin.x + 10
      }
      button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
      UIView.animate(withDuration: 0.3) {
        self.layoutIfNeeded()
      } completion: { _ in
        UIView.animate(withDuration: 0.25) {
          self.settingsView.settingsContentView.alpha = 1
        }
      }
    }
  }

  func hideSettingsIfNeeded() {
    guard let leadingSettingsConstraint = leadingSettingsConstraint else {
      return
    }

    if leadingSettingsConstraint.constant > 21 {
      toggleSettings()
    }
  }
}


