//  Created by Dominik Hauser on 03.01.22.
//  
//

import SpriteKit

class RectangleEmitter: SKEmitterNode {
  override init() {
    super.init()

    particleSize = .init(width: 1.5, height: 1.5)
    particleBirthRate = 30
    particleLifetime = 30
    particleAlpha = 0.7
    particleScale = 1
    particleColorBlendFactor = 1
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
