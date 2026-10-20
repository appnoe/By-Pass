//  Created by Dominik Hauser on 31.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import XCTest

@MainActor
final class GravityUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUp() async throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait

    app = XCUIApplication()
    // Skip onboarding, keep the test run silent and in English
    app.launchArguments += [
      "-hasSeenOnboarding", "YES",
      "-soundEnabled", "NO",
      "-AppleLanguages", "(en)",
      "-AppleLocale", "en_US",
    ]
    app.launch()
  }

  override func tearDown() async throws {
    XCUIDevice.shared.orientation = .portrait
  }

  func test_dock_switchesSunsAndFastForward() throws {
    let threeSuns = app.buttons["3 suns"]
    XCTAssertTrue(threeSuns.waitForExistence(timeout: 15), "Dock did not appear after the splash screen")
    XCTAssertTrue(app.buttons["1 sun"].isSelected)

    threeSuns.tap()

    XCTAssertTrue(threeSuns.isSelected)
    XCTAssertFalse(app.buttons["1 sun"].isSelected)

    for label in ["Fast forward", "Capture", "Clear", "Sound", "Info"] {
      XCTAssertTrue(app.buttons[label].isHittable, "\(label) not reachable")
    }
    app.buttons["Fast forward"].tap()
    app.buttons["Fast forward"].tap()

    takeScreenshot(named: "dock_portrait")
  }

  func test_dock_isReachableInLandscape() throws {
    XCTAssertTrue(app.buttons["Info"].waitForExistence(timeout: 15))

    XCUIDevice.shared.orientation = .landscapeLeft

    for label in ["1 sun", "2 suns", "3 suns", "Fast forward", "Capture", "Clear", "Sound", "Info"] {
      XCTAssertTrue(app.buttons[label].isHittable, "\(label) not reachable in landscape")
    }
    takeScreenshot(named: "dock_landscape")
  }

  func test_soundButton_togglesState() throws {
    // A launch argument would override the stored setting, so relaunch without it
    app.terminate()
    app.launchArguments.removeAll { $0 == "-soundEnabled" || $0 == "NO" }
    app.launch()
    let sound = app.buttons["Sound"]
    XCTAssertTrue(sound.waitForExistence(timeout: 15))
    let before = sound.value as? String

    sound.tap()

    XCTAssertNotEqual(sound.value as? String, before)
    sound.tap()
    XCTAssertEqual(sound.value as? String, before)
  }

  func test_clear_removesAllPlanets() throws {
    let clear = app.buttons["Clear"]
    XCTAssertTrue(clear.waitForExistence(timeout: 15))

    clear.tap()

    let emptyCount = app.staticTexts["0"]
    XCTAssertTrue(emptyCount.waitForExistence(timeout: 5))
  }
}

extension GravityUITests {
  func takeScreenshot(named name: String) {
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(
      uniformTypeIdentifier: "public.png",
      name: "Screenshot-\(name).png",
      payload: screenshot.pngRepresentation,
      userInfo: nil)
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
