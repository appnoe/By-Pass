import XCTest

/// Produces the App Store screenshots. Skipped in normal test runs; enable with
///
///     TEST_RUNNER_BYPASS_SCREENSHOTS=1 xcodebuild test -only-testing:GravityUITests/StoreScreenshotTests …
///
/// Runs in German, the store's primary language.
@MainActor
final class StoreScreenshotTests: XCTestCase {

  var app: XCUIApplication!

  override func setUp() async throws {
    try XCTSkipUnless(ProcessInfo.processInfo.environment["BYPASS_SCREENSHOTS"] == "1",
                      "Store screenshots are only taken on request")
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    app = XCUIApplication()
    app.launchArguments += ["-soundEnabled", "NO", "-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
  }

  func test_01_onboarding() {
    app.launchArguments += ["-hasSeenOnboarding", "NO"]
    app.launch()
    XCTAssertTrue(app.staticTexts["Tippen, ziehen & loslassen"].waitForExistence(timeout: 15))
    // let the demo hand reach the middle of its drag
    sleep(5)
    takeScreenshot(named: "01_onboarding")
  }

  func test_02_oneSun() {
    launchToDock()
    for (radius, angle, factor) in [(170.0, 1.57, 1.0), (255.0, 4.7, 0.95), (420.0, 1.45, 1.0)] {
      launchPlanet(radius: radius, angle: angle, centralMass: 1, speedFactor: factor)
    }
    develop(seconds: 14)
    takeScreenshot(named: "02_one_sun")
  }

  func test_03_threeSuns() {
    launchToDock()
    app.buttons["3 Sonnen"].tap()
    clear()
    // well outside the sun triangle the three suns act like one central mass
    for (radius, angle, factor) in [(430.0, 1.57, 1.0), (480.0, 4.71, 0.95), (540.0, 1.5, 0.9), (600.0, 4.6, 0.92)] {
      launchPlanet(radius: radius, angle: angle, centralMass: 3, speedFactor: factor)
    }
    develop(seconds: 9)
    takeScreenshot(named: "03_three_suns")
  }

  func test_04_twoSuns() {
    launchToDock()
    app.buttons["2 Sonnen"].tap()
    clear()
    for (radius, angle, factor) in [(250.0, 1.57, 0.9), (290.0, 4.7, 0.9), (400.0, 1.4, 0.85), (460.0, 4.6, 0.8)] {
      launchPlanet(radius: radius, angle: angle, centralMass: 2, speedFactor: factor)
    }
    develop(seconds: 14)
    takeScreenshot(named: "04_two_suns")
  }

  // MARK: - Helper

  private func launchToDock() {
    app.launchArguments += ["-hasSeenOnboarding", "YES"]
    app.launch()
    XCTAssertTrue(app.buttons["Löschen"].waitForExistence(timeout: 15))
  }

  private func clear() {
    app.buttons["Löschen"].tap()
    XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 5))
  }

  /// Fast forward for a while so that the trails build up, then back to normal speed.
  private func develop(seconds: UInt32) {
    app.buttons["Vorspulen"].tap()
    sleep(seconds)
    app.buttons["Vorspulen"].tap()
    sleep(1)
  }

  /// Places a planet at `radius` (scene points) from the centre and launches it
  /// counter-clockwise with roughly circular-orbit speed around `centralMass` suns.
  /// Angles near ±π/2 keep start and release point on screen (horizontal drag).
  private func launchPlanet(radius: Double, angle: Double, centralMass: Double, speedFactor: Double) {
    // GameScene: 750×1334 scene, .aspectFill, launch velocity = (position − release) × 0.6,
    // circular speed v = √(GM/r) with GM = 3 375 000 per sun
    let size = app.frame.size
    let scale = max(size.width / 750, size.height / 1334)
    // stay well inside the visible area: a drag starting under the window
    // controls would move the app window on iPad
    let radius = min(radius, 0.8 * (size.height / 2) / scale)
    let speed = (3_375_000 * centralMass / radius).squareRoot() * speedFactor
    let dragLength = speed / 0.6

    let start = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
    // counter-clockwise tangent is (−sin, cos); release point lies opposite to it
    let release = CGPoint(x: start.x + dragLength * sin(angle), y: start.y - dragLength * cos(angle))

    func screen(_ p: CGPoint) -> XCUICoordinate {
      let origin = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
      return origin.withOffset(CGVector(dx: size.width / 2 + p.x * scale, dy: size.height / 2 - p.y * scale))
    }
    screen(start).press(forDuration: 0.1, thenDragTo: screen(release), withVelocity: .default, thenHoldForDuration: 0.05)
  }

  private func takeScreenshot(named name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
