//  Created by Dominik Hauser on 31.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import XCTest

class GravityUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false

    app = XCUIApplication()
    // Skip the first-launch onboarding overlay
    app.launchArguments += ["-hasSeenOnboarding", "YES"]
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  func test_hudControlsAreReachable() throws {
    // The splash screen is shown for ~5 s before the game appears
    let sun3 = app.buttons["sun3"]
    XCTAssertTrue(sun3.waitForExistence(timeout: 10))

    sun3.tap()
    app.buttons["sun2"].tap()
    app.buttons["sun1"].tap()

    app.buttons["speed"].tap()
    app.buttons["speed"].tap()

    app.buttons["sound"].tap()
    app.buttons["sound"].tap()

    app.buttons["clear"].tap()
    XCTAssertTrue(app.staticTexts["satellitesCount"].exists)
  }

  func test_takeScreenshots() throws {
    let sun1 = app.buttons["sun1"]
    XCTAssertTrue(sun1.waitForExistence(timeout: 10))

    sleep(20)
    takeScreenshot(named: "one_sun")

    app.buttons["sun2"].tap()
    sleep(20)
    takeScreenshot(named: "two_suns")

    app.buttons["sun3"].tap()
    sleep(20)
    takeScreenshot(named: "three_suns")

    app.buttons["info"].tap()
    sleep(2)
    takeScreenshot(named: "info")
  }
}

extension GravityUITests {
  func takeScreenshot(named name: String) {
    sleep(1)

    // Take the screenshot
    let fullScreenshot = XCUIScreen.main.screenshot()

    // Create a new attachment to save our screenshot
    // and give it a name consisting of the "named"
    // parameter and the device name, so we can find
    // it later.
    let screenshotAttachment = XCTAttachment(
      uniformTypeIdentifier: "public.png",
      name: "Screenshot-\(UIDevice.current.name)-\(name).png",
      payload: fullScreenshot.pngRepresentation,
      userInfo: nil)

    // Usually Xcode will delete attachments after
    // the test has run; we don't want that!
    screenshotAttachment.lifetime = .keepAlways

    // Add the attachment to the test log,
    // so we can retrieve it later
    add(screenshotAttachment)
  }
}
