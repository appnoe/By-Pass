//  GravityModelTests.swift

import XCTest
import SpriteKit
@testable import By_Pass

final class GravityModelTests: XCTestCase {

  var sut: GravityModel!
  var scene: SKScene!

  override func setUpWithError() throws {
    sut = GravityModel()
    scene = SKScene(size: CGSize(width: 750, height: 1334))
    sut.setup(scene: scene)
  }

  override func tearDownWithError() throws {
    sut = nil
    scene = nil
  }

  // MARK: - Setup

  func test_setup_addsSunOnlyOnce() {
    sut.setup(scene: scene)

    XCTAssertEqual(scene.children.filter { $0 === sut.center }.count, 1)
    XCTAssertEqual(scene.children.filter { $0 === sut.gravityNode }.count, 1)
  }

  // MARK: - Suns

  func test_oneSun_onlyFirstFieldIsActive() {
    sut.setNumberOfBlackHoles(to: 3, in: scene)
    sut.setNumberOfBlackHoles(to: 1, in: scene)

    XCTAssertEqual(sut.activeSunPositions().count, 1)
    XCTAssertNil(sut.secondCenter.parent)
    XCTAssertNil(sut.thirdCenter.parent)
  }

  func test_twoSuns_orbitClockwiseAtConstantDistance() {
    sut.setNumberOfBlackHoles(to: 2, in: scene)
    let start = sut.center.position

    sut.updateSunOrbit(dt: 0.1)

    // Left sun moves upwards when rotating clockwise
    XCTAssertGreaterThan(sut.center.position.y, start.y)
    XCTAssertEqual(distance(sut.center.position, sut.secondCenter.position), 224, accuracy: 0.001)
  }

  func test_threeSuns_keepTriangleOverLongRun() {
    sut.setNumberOfBlackHoles(to: 3, in: scene)

    // ~10 minutes at 120 Hz
    for _ in 0..<72_000 {
      sut.updateSunOrbit(dt: 1.0 / 120.0)
    }

    let p = sut.activeSunPositions()
    XCTAssertEqual(p.count, 3)
    XCTAssertEqual(distance(p[0], p[1]), 224, accuracy: 0.01)
    XCTAssertEqual(distance(p[1], p[2]), 224, accuracy: 0.01)
    XCTAssertEqual(distance(p[2], p[0]), 224, accuracy: 0.01)

    let centroid = CGPoint(x: (p[0].x + p[1].x + p[2].x) / 3, y: (p[0].y + p[1].y + p[2].y) / 3)
    XCTAssertEqual(centroid.x, 0, accuracy: 0.01)
    XCTAssertEqual(centroid.y, 0, accuracy: 0.01)
  }

  func test_sunOrbit_isIndependentOfFrameRate() {
    sut.setNumberOfBlackHoles(to: 3, in: scene)
    for _ in 0..<60 { sut.updateSunOrbit(dt: 1.0 / 60.0) }
    let at60Hz = sut.center.position

    sut.setNumberOfBlackHoles(to: 3, in: scene)
    for _ in 0..<120 { sut.updateSunOrbit(dt: 1.0 / 120.0) }
    let at120Hz = sut.center.position

    XCTAssertEqual(at60Hz.x, at120Hz.x, accuracy: 0.001)
    XCTAssertEqual(at60Hz.y, at120Hz.y, accuracy: 0.001)
  }

  // MARK: - Trajectory preview

  func test_trajectoryPoints_fallTowardsSun() {
    let points = sut.trajectoryPoints(from: CGPoint(x: 300, y: 4), velocity: .zero, steps: 30)

    XCTAssertEqual(points.count, 30)
    XCTAssertLessThan(points.last!.x, 300)
  }

  func test_trajectoryPoints_stopAtSun() {
    let points = sut.trajectoryPoints(from: CGPoint(x: 30, y: 4), velocity: .zero)

    XCTAssertLessThan(points.count, 360)
  }

  // MARK: - Placing satellites

  func test_launchedSatellite_isNoLongerPending() {
    let node = sut.satellite(with: CGPoint(x: 100, y: 100), id: 1)
    scene.addChild(node)

    sut.addVelocityToSatellite(id: 1, input: CGPoint(x: 90, y: 90))

    XCTAssertTrue(sut.temporaryNodes.isEmpty)
    XCTAssertNotNil(node.physicsBody)
    XCTAssertTrue(sut.satelliteNodes.first === node)
  }

  func test_cancelPendingSatellites_removesOnlyPendingOnes() {
    let launched = sut.satellite(with: CGPoint(x: 100, y: 100), id: 1)
    scene.addChild(launched)
    sut.addVelocityToSatellite(id: 1, input: CGPoint(x: 90, y: 90))

    let pending = sut.satellite(with: CGPoint(x: -100, y: 100), id: 2)
    scene.addChild(pending)
    if let velocityNode = sut.updateVelocity(id: 2, input: CGPoint(x: -90, y: 90)) {
      scene.addChild(velocityNode)
    }

    sut.cancelPendingSatellites()

    XCTAssertEqual(sut.satelliteNodes.count, 1)
    XCTAssertTrue(sut.satelliteNodes.first === launched)
    XCTAssertNil(pending.parent)
    XCTAssertTrue(sut.temporaryNodes.isEmpty)
    XCTAssertTrue(sut.velocityNodes.isEmpty)
  }

  func test_clear_forgetsPendingPlacements() {
    let pending = sut.satellite(with: CGPoint(x: 100, y: 100), id: 1)
    scene.addChild(pending)

    sut.clear()

    XCTAssertTrue(sut.satelliteNodes.isEmpty)
    XCTAssertTrue(sut.temporaryNodes.isEmpty)
  }

  // MARK: - Fast-forward

  func test_speedMultiplier_setsAbsoluteTrailBirthRate() {
    let first = launchSatellite(id: 1)
    let baseRate = trailEmitter(of: first).particleBirthRate

    sut.speedMultiplier = 3
    let second = launchSatellite(id: 2)

    XCTAssertEqual(trailEmitter(of: first).particleBirthRate, baseRate * 3)
    XCTAssertEqual(trailEmitter(of: second).particleBirthRate, baseRate * 3)

    sut.speedMultiplier = 1

    XCTAssertEqual(trailEmitter(of: first).particleBirthRate, baseRate)
    XCTAssertEqual(trailEmitter(of: second).particleBirthRate, baseRate)
  }

  // MARK: - Sound

  func test_sound_requiresSatellitesAndEnabledSound() {
    sut.addSound(node: SKAudioNode(avAudioNode: nil))
    XCTAssertNil(sut.sound())

    _ = launchSatellite(id: 1)
    XCTAssertNotNil(sut.sound())

    sut.disableSound()
    XCTAssertNil(sut.sound())
  }

  // MARK: - Helpers

  private func launchSatellite(id: Int) -> SKNode {
    let node = sut.satellite(with: CGPoint(x: 100 + CGFloat(id) * 20, y: 100), id: id)
    scene.addChild(node)
    sut.addVelocityToSatellite(id: id, input: CGPoint(x: 90, y: 90))
    return node
  }

  private func trailEmitter(of node: SKNode) -> SKEmitterNode {
    guard let emitter = node.children.compactMap({ $0 as? SKEmitterNode }).first else {
      XCTFail("satellite has no trail emitter")
      return SKEmitterNode()
    }
    return emitter
  }

  private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    hypot(a.x - b.x, a.y - b.y)
  }
}
