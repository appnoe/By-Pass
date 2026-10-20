//  Created by Dominik Hauser on 02.01.22.
//  Copyright © 2022 dasdom. All rights reserved.
//

import XCTest
@testable import By_Pass
import SpriteKit

@MainActor
final class GameSceneTests: XCTestCase {

  var sut: GameScene!
  var skView: SKView!

  override func setUp() async throws {
    skView = SKView(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
    sut = GameScene()
    skView.presentScene(sut)
  }

  override func tearDown() async throws {
    skView = nil
    sut = nil
  }

  func test_random_addsFiveSatellitesToScene() {
    sut.random(direction: .clockWise)

    XCTAssertEqual(sut.model.satelliteNodes.count, 5)
    XCTAssertEqual(sut.children.compactMap { $0 as? Satellite }.count, 5)
  }

  func test_setSimulationSpeed_scalesPhysicsAndTrails() {
    sut.random(direction: .random)
    let emitter = try! XCTUnwrap(sut.model.satelliteNodes.first?.children.compactMap { $0 as? SKEmitterNode }.first)
    let baseRate = emitter.particleBirthRate

    sut.setSimulationSpeed(3)

    XCTAssertEqual(sut.physicsWorld.speed, 3)
    XCTAssertEqual(emitter.particleBirthRate, baseRate * 3, accuracy: 0.001)

    sut.setSimulationSpeed(1)

    XCTAssertEqual(emitter.particleBirthRate, baseRate, accuracy: 0.001)
  }

  func test_newSatelliteDuringFastForward_getsScaledTrail() {
    sut.setSimulationSpeed(3)

    sut.random(direction: .random)

    let emitter = try! XCTUnwrap(sut.model.satelliteNodes.first?.children.compactMap { $0 as? SKEmitterNode }.first)
    XCTAssertEqual(emitter.particleBirthRate, 60 * 3, accuracy: 0.001)
  }
}
