# By-Pass

By-Pass is an iOS app built with SpriteKit. It simulates a gravitational field with one, two or three suns and lets you launch planets into it: touch to place a planet, drag to set its velocity (a preview shows the expected orbit in single-sun mode) and release to launch it. Watching the planets follow their trails feels a bit like meditation.

By-Pass is based on Gravity Zen by Dominik Hauser.

## Features

- 1, 2 or 3 suns – multiple suns orbit their common centre of mass (circular orbit / Lagrange triangle)
- Mutual attraction between planets, procedurally textured planets, particle trails
- Fast-forward (3×), pinch to zoom
- Background music that can be switched off
- Screenshot (tap) and screen recording (long press) to the photo library

## Requirements

- Xcode 26 or newer
- iOS 26 or newer (the HUD uses Liquid Glass)

## Build & Test

Open `By-Pass.xcodeproj` and run the `By-Pass` scheme. The Debug configuration installs as “By-Pass Dev” (`de.appnoe.by-pass.debug`) next to the release build.

Unit tests live in `GravityTests` (run with ⌘U). The UI tests in `GravityUITests` are skipped in the scheme by default; they also produce screenshots as test attachments.

The build number shown in the app comes from `CURRENT_PROJECT_VERSION`, the version from `MARKETING_VERSION`.

## Screenshots

![](screenshots/01.png)
![](screenshots/02.png)
![](screenshots/03.png)

## Licence

MIT
