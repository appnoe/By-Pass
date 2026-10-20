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

## Credits

By-Pass is developed by Appnö GmbH and is based on [Gravity Zen](https://apps.apple.com/us/app/gravity-zen/id1602081846) by Dominik Hauser.

## Licence

MIT, see [LICENSE](LICENSE).
