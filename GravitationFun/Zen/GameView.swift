//  Created by Dominik Hauser on 28.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import UIKit
import SpriteKit

class GameView: UIView {

  let skView: SKView
  let fastForwardButton: UIButton
  let satellitesCountLabel: UILabel
  let bottomTabBar: BottomTabBar

  override init(frame: CGRect) {

    skView = SKView(frame: frame)
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.isMultipleTouchEnabled = true

    fastForwardButton = UIButton(configuration: .glass())
    fastForwardButton.translatesAutoresizingMaskIntoConstraints = false
    fastForwardButton.setImage(UIImage(systemName: "forward"), for: .normal)

    satellitesCountLabel = UILabel()
    satellitesCountLabel.translatesAutoresizingMaskIntoConstraints = false
    satellitesCountLabel.text = "0"
    satellitesCountLabel.textColor = .secondaryLabel

    bottomTabBar = BottomTabBar()
    bottomTabBar.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond

    addSubview(skView)
    addSubview(fastForwardButton)
    addSubview(satellitesCountLabel)
    addSubview(bottomTabBar)

    NSLayoutConstraint.activate([
      fastForwardButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
      fastForwardButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
      fastForwardButton.widthAnchor.constraint(equalToConstant: 44),
      fastForwardButton.heightAnchor.constraint(equalTo: fastForwardButton.widthAnchor),

      satellitesCountLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
      satellitesCountLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),

      bottomTabBar.centerXAnchor.constraint(equalTo: centerXAnchor),
      bottomTabBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
      bottomTabBar.heightAnchor.constraint(equalToConstant: 72),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
