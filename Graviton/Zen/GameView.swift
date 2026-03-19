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
  let radialMenu: RadialMenuView

  override init(frame: CGRect) {

    skView = GravitySKView(frame: frame)
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.isMultipleTouchEnabled = true

    satellitesCountLabel = UILabel()
    satellitesCountLabel.translatesAutoresizingMaskIntoConstraints = false
    satellitesCountLabel.text = "0"
    satellitesCountLabel.textColor = .secondaryLabel

    radialMenu = RadialMenuView()
    radialMenu.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = 120  // set to max; SKView caps to actual display rate

    addSubview(skView)
    addSubview(satellitesCountLabel)
    addSubview(radialMenu)

    NSLayoutConstraint.activate([
      satellitesCountLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
      satellitesCountLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),

      // RadialMenu: füllt den gesamten Bereich (für Dimming + Menü-Item-Positionen)
      radialMenu.topAnchor.constraint(equalTo: topAnchor),
      radialMenu.leadingAnchor.constraint(equalTo: leadingAnchor),
      radialMenu.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
      radialMenu.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
