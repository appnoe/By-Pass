//  Created by Dominik Hauser on 02.01.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import XCTest
@testable import By_Pass
import SpriteKit

class GameSceneTests: XCTestCase {

  var sut: GameScene!
  var skView: SKView!

  override func setUpWithError() throws {
    skView = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    sut = GameScene()
    skView.presentScene(sut)
  }

  override func tearDownWithError() throws {
    skView = nil
    sut = nil
  }

  func test_didMove_addsSunAndCamera() {
    XCTAssertTrue(sut.model.center.parent === sut)
    XCTAssertNotNil(sut.camera)
    XCTAssertNotNil(sut.model.musicAudioNode)
  }

  func test_random_addsFiveSatellites() {
    sut.random(direction: .clockWise)

    XCTAssertEqual(sut.model.satelliteNodes.count, 5)
    XCTAssertEqual(sut.children.compactMap { $0 as? Satellite }.count, 5)
  }

  func test_setSpeed_updatesPhysicsAndModel() {
    sut.setSpeed(3)

    XCTAssertEqual(sut.physicsWorld.speed, 3)
    XCTAssertEqual(sut.model.speedMultiplier, 3)
  }

  func test_clear_removesAllSatellites() {
    sut.random(direction: .random)

    sut.clear()

    XCTAssertTrue(sut.model.satelliteNodes.isEmpty)
    XCTAssertTrue(sut.children.compactMap { $0 as? Satellite }.isEmpty)
  }
}
