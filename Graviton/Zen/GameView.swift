//  Created by Dominik Hauser on 28.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import UIKit
import SpriteKit

/// SKView subclass that opts out of UIKit focus navigation.
/// Overriding focusItemsInRect: to return [] prevents the
/// "caching for linear focus movement is limited" runtime log.
class GravitySKView: SKView {
  override func focusItems(in rect: CGRect) -> [any UIFocusItem] { [] }
}

class GameView: UIView {

  let skView: GravitySKView
  let satellitesCountLabel: UILabel
  let bottomTabBar: BottomTabBar
  let captureButton: UIButton

  private let captureClipView: UIView
  private let captureContainerView: UIVisualEffectView

  override init(frame: CGRect) {

    skView = GravitySKView(frame: frame)
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.isMultipleTouchEnabled = true

    satellitesCountLabel = UILabel()
    satellitesCountLabel.translatesAutoresizingMaskIntoConstraints = false
    satellitesCountLabel.text = "0"
    satellitesCountLabel.textColor = .secondaryLabel

    bottomTabBar = BottomTabBar()
    bottomTabBar.translatesAutoresizingMaskIntoConstraints = false

    // --- Capture button with Liquid Glass background ---
    captureClipView = UIView()
    captureClipView.translatesAutoresizingMaskIntoConstraints = false
    captureClipView.layer.cornerRadius = 22
    captureClipView.layer.cornerCurve = .continuous
    captureClipView.clipsToBounds = true
    captureClipView.backgroundColor = .clear

    captureContainerView = UIVisualEffectView(effect: UIGlassContainerEffect())
    captureContainerView.translatesAutoresizingMaskIntoConstraints = false

    let captureGlassEffect = UIGlassEffect()
    captureGlassEffect.tintColor = UIColor.black.withAlphaComponent(0.55)
    captureGlassEffect.isInteractive = true
    let captureGlassView = UIVisualEffectView(effect: captureGlassEffect)
    captureGlassView.translatesAutoresizingMaskIntoConstraints = false
    captureGlassView.isUserInteractionEnabled = false

    var captureConfig = UIButton.Configuration.plain()
    captureConfig.image = UIImage(systemName: "camera")?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    )
    captureConfig.baseForegroundColor = UIColor.white.withAlphaComponent(0.75)
    captureButton = UIButton(configuration: captureConfig)
    captureButton.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = 120

    captureContainerView.contentView.addSubview(captureGlassView)
    captureContainerView.contentView.addSubview(captureButton)
    captureClipView.addSubview(captureContainerView)

    addSubview(skView)
    addSubview(satellitesCountLabel)
    addSubview(bottomTabBar)
    addSubview(captureClipView)

    NSLayoutConstraint.activate([
      satellitesCountLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
      satellitesCountLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),

      bottomTabBar.centerXAnchor.constraint(equalTo: centerXAnchor),
      bottomTabBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
      bottomTabBar.heightAnchor.constraint(equalToConstant: 60),
      bottomTabBar.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
      bottomTabBar.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
      bottomTabBar.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),

      // Capture button: top-right, 44x44
      captureClipView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
      captureClipView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
      captureClipView.widthAnchor.constraint(equalToConstant: 44),
      captureClipView.heightAnchor.constraint(equalToConstant: 44),

      captureContainerView.topAnchor.constraint(equalTo: captureClipView.topAnchor),
      captureContainerView.leadingAnchor.constraint(equalTo: captureClipView.leadingAnchor),
      captureContainerView.bottomAnchor.constraint(equalTo: captureClipView.bottomAnchor),
      captureContainerView.trailingAnchor.constraint(equalTo: captureClipView.trailingAnchor),

      captureGlassView.topAnchor.constraint(equalTo: captureContainerView.contentView.topAnchor),
      captureGlassView.leadingAnchor.constraint(equalTo: captureContainerView.contentView.leadingAnchor),
      captureGlassView.bottomAnchor.constraint(equalTo: captureContainerView.contentView.bottomAnchor),
      captureGlassView.trailingAnchor.constraint(equalTo: captureContainerView.contentView.trailingAnchor),

      captureButton.topAnchor.constraint(equalTo: captureContainerView.contentView.topAnchor),
      captureButton.leadingAnchor.constraint(equalTo: captureContainerView.contentView.leadingAnchor),
      captureButton.bottomAnchor.constraint(equalTo: captureContainerView.contentView.bottomAnchor),
      captureButton.trailingAnchor.constraint(equalTo: captureContainerView.contentView.trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
