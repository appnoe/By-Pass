//  Created by Dominik Hauser on 03.01.22.
//  
//

import SpriteKit

/// Emits the trail particles behind each satellite.
class BoxEmitter: SKEmitterNode {
  override class var supportsSecureCoding: Bool {
    return true
  }
  override init() {
    super.init()

    particleSize = .init(width: 1.5, height: 1.5)
    particleBirthRate = 60
    particleLifetime = TrailLength.long.lifetime()
    particleAlpha = 0.7
    particleScale = 1
    particleColorBlendFactor = 1
    particlePositionRange = CGVector(dx: 0.8, dy: 0.8)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
