import XCTest
@testable import By_Pass
import SpriteKit

@MainActor
final class GravityModelTests: XCTestCase {

  var sut: GravityModel!
  var scene: SKScene!

  override func setUp() async throws {
    scene = SKScene(size: CGSize(width: 750, height: 1334))
    sut = GravityModel()
    sut.setup(scene: scene)
  }

  override func tearDown() async throws {
    sut = nil
    scene = nil
  }

  // MARK: - Sun orbit

  func test_threeSuns_keepEquilateralTriangleOverTime() {
    sut.setNumberOfBlackHoles(to: 3, in: scene)

    // ten minutes of simulation at 60 Hz
    for _ in 0..<36_000 {
      sut.updateSunOrbit(dt: 1.0 / 60.0)
    }

    let suns = sut.activeSunPositions()
    XCTAssertEqual(suns.count, 3)
    for (a, b) in [(0, 1), (1, 2), (2, 0)] {
      XCTAssertEqual(distance(suns[a], suns[b]), 224, accuracy: 0.01)
    }
    let centroid = CGPoint(x: suns.map(\.x).reduce(0, +) / 3, y: suns.map(\.y).reduce(0, +) / 3)
    XCTAssertEqual(centroid.x, 0, accuracy: 0.01)
    XCTAssertEqual(centroid.y, 0, accuracy: 0.01)
  }

  func test_sunOrbit_doesNotDependOnFrameRate() {
    sut.setNumberOfBlackHoles(to: 2, in: scene)
    for _ in 0..<600 { sut.updateSunOrbit(dt: 1.0 / 60.0) }
    let at60Hz = sut.activeSunPositions()

    sut.setNumberOfBlackHoles(to: 2, in: scene)
    for _ in 0..<1200 { sut.updateSunOrbit(dt: 1.0 / 120.0) }
    let at120Hz = sut.activeSunPositions()

    for (p, q) in zip(at60Hz, at120Hz) {
      XCTAssertEqual(p.x, q.x, accuracy: 0.01)
      XCTAssertEqual(p.y, q.y, accuracy: 0.01)
    }
  }

  func test_backToOneSun_resetsCentreAndDisablesFields() {
    sut.setNumberOfBlackHoles(to: 3, in: scene)
    sut.setNumberOfBlackHoles(to: 1, in: scene)

    XCTAssertEqual(sut.activeSunPositions(), [CGPoint(x: 4, y: 4)])
    XCTAssertNil(sut.secondCenter.parent)
    XCTAssertNil(sut.thirdCenter.parent)
  }

  // MARK: - Trajectory preview

  func test_trajectory_circularOrbitKeepsRadius() {
    let sun = sut.activeSunPositions()[0]
    let r: CGFloat = 200
    let start = CGPoint(x: sun.x + r, y: sun.y)
    let speed = sqrt(3_375_000 / r)

    let points = sut.trajectoryPoints(from: start, velocity: CGVector(dx: 0, dy: speed))

    XCTAssertEqual(points.count, 360)
    for point in points {
      XCTAssertEqual(distance(point, sun), r, accuracy: r * 0.03)
    }
  }

  func test_trajectory_stopsWhenHittingTheSun() {
    let sun = sut.activeSunPositions()[0]

    let points = sut.trajectoryPoints(from: CGPoint(x: sun.x + 100, y: sun.y), velocity: .zero)

    XCTAssertLessThan(points.count, 360)
  }

  // MARK: - Placing satellites

  func test_addVelocity_launchesSatelliteAndForgetsPlacement() {
    let node = sut.satellite(with: CGPoint(x: 100, y: 0), id: 1)
    scene.addChild(node)

    sut.addVelocityToSatellite(id: 1, input: CGPoint(x: 100, y: -50))

    XCTAssertTrue(sut.temporaryNodes.isEmpty)
    XCTAssertTrue(sut.velocityNodes.isEmpty)
    let velocity = try! XCTUnwrap(node.physicsBody?.velocity)
    XCTAssertEqual(velocity.dx, 0, accuracy: 0.001)
    XCTAssertEqual(velocity.dy, 30, accuracy: 0.001)
  }

  func test_cancelPendingSatellites_removesOnlySatellitesBeingPlaced() {
    let launched = sut.satellite(with: CGPoint(x: 100, y: 0), id: 1)
    scene.addChild(launched)
    sut.addVelocityToSatellite(id: 1, input: CGPoint(x: 100, y: -50))
    let pending = sut.satellite(with: CGPoint(x: -100, y: 0), id: 2)
    scene.addChild(pending)

    sut.cancelPendingSatellites()

    XCTAssertEqual(sut.satelliteNodes, [launched as! Satellite])
    XCTAssertNil(pending.parent)
    XCTAssertTrue(sut.temporaryNodes.isEmpty)
  }

  func test_clear_removesPlacementStateAndVelocityIndicator() {
    let node = sut.satellite(with: CGPoint(x: 100, y: 0), id: 1)
    scene.addChild(node)
    if let indicator = sut.updateVelocity(id: 1, input: CGPoint(x: 120, y: 20)) {
      scene.addChild(indicator)
    }

    sut.clear()

    XCTAssertTrue(sut.satelliteNodes.isEmpty)
    XCTAssertTrue(sut.temporaryNodes.isEmpty)
    XCTAssertTrue(sut.velocityNodes.isEmpty)
  }

  func test_random_respectsSatelliteLimit() {
    for id in 0..<(GravityModel.maxSatellites - 2) {
      _ = sut.satellite(with: CGPoint(x: id, y: 0), id: id)
    }

    let added = sut.random(size: scene.size, direction: .random)

    XCTAssertEqual(added.count, 2)
    XCTAssertEqual(sut.satelliteNodes.count, GravityModel.maxSatellites)
    XCTAssertFalse(sut.canAddSatellite)
    XCTAssertTrue(sut.random(size: scene.size, direction: .random).isEmpty)
  }

  // MARK: - Helper

  private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    hypot(a.x - b.x, a.y - b.y)
  }
}
