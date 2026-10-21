# By-Pass – Der Sonnensystem-Simulator

By-Pass is an interactive lab for Newtonian physics on iPhone, iPad, Mac and Apple Vision. Place planets with a drag gesture (the gesture sets the launch velocity) and watch them orbit one, two or three suns.

[![Download on the App Store](https://img.shields.io/badge/App_Store-By--Pass-blue?logo=apple)](https://apps.apple.com/de/app/by-pass/id6760612355)

## Features

- Planets with a launch gesture and a live orbit preview (single-sun mode)
- One sun, a binary star or three suns in a Lagrange triangle
- Gravity between all planets, procedurally generated planet textures
- Fast forward, screenshots and screen recordings to the photo library
- Liquid Glass control dock, background music with on/off switch
- German and English, no data collection ([privacy policy](https://www.appnoe.de/datenschutzerklaerung.html))

## Screenshots

![](screenshots/01.png)
![](screenshots/02.png)
![](screenshots/03.png)

## Development

Requirements: Xcode 26 or later, iOS/iPadOS 26 deployment target, Swift 6.

```bash
open By-Pass.xcodeproj
```

The `By-Pass` scheme runs the unit tests (`GravityTests`) and the UI tests (`GravityUITests`):

```bash
xcodebuild -project By-Pass.xcodeproj -scheme By-Pass -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Project layout:

| Folder | Content |
|---|---|
| `Graviton/GravityLogic` | Physics model (`GravityModel`), planets, sun and emitter nodes |
| `Graviton/Zen` | Scene, view controller, control dock, splash, onboarding, info sheet |
| `GravityTests`, `GravityUITests` | Unit and UI tests |
| `docs` | Privacy policy as published on appnoe.de |

Branching follows git flow: `main`, `develop`, `feature/*`, `fix/*`, `release/*`.

## Release

`scripts/asc.py` talks to the App Store Connect API. The API key (role App Manager) lives in the login keychain as a generic password, service `App Store Connect API`, account = key ID, value = base64 of the `.p8` file; it is never written to disk except as a short-lived temporary copy for `xcodebuild`.

```bash
# read-only check of the API access
scripts/asc.py GET '/v1/apps?filter[bundleId]=de.appnoe.by-pass'
```

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` on `release/<version>`, merge into `main` and `develop`, tag.
2. Archive and upload from the tag:

   ```bash
   scripts/asc.py keyfile -- sh -c 'xcodebuild -project By-Pass.xcodeproj -scheme By-Pass -configuration Release \
     -destination generic/platform=iOS -archivePath build/By-Pass.xcarchive archive \
     -allowProvisioningUpdates -authenticationKeyPath "$ASC_KEY_PATH" \
     -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" &&
   xcodebuild -exportArchive -archivePath build/By-Pass.xcarchive -exportOptionsPlist scripts/ExportOptions.plist \
     -exportPath build/export -allowProvisioningUpdates -authenticationKeyPath "$ASC_KEY_PATH" \
     -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"'
   ```

3. Store screenshots (German, iPhone 6.9" and iPad 13"):

   ```bash
   TEST_RUNNER_BYPASS_SCREENSHOTS=1 xcodebuild -project By-Pass.xcodeproj -scheme By-Pass \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
     -only-testing:GravityUITests/StoreScreenshotTests -resultBundlePath build/shots.xcresult test
   ```

4. Create the version, attach the build, release notes and screenshots in App Store Connect (or via the API), then submit for review.

## Credits

By-Pass is developed by Appnö GmbH and is based on [Gravity Zen](https://apps.apple.com/us/app/gravity-zen/id1602081846) by Dominik Hauser.

## Licence

MIT, see [LICENSE](LICENSE).
