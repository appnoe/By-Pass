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

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = 120  // set to max; SKView caps to actual display rate

    addSubview(skView)
    addSubview(satellitesCountLabel)
    addSubview(bottomTabBar)

    NSLayoutConstraint.activate([
      satellitesCountLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
      satellitesCountLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),

      bottomTabBar.centerXAnchor.constraint(equalTo: centerXAnchor),
      bottomTabBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
