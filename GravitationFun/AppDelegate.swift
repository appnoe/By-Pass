//  Created by Dominik Hauser on 22.12.21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    application.isIdleTimerDisabled = true
    return true
  }

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}

func infoForKey(_ key: String) -> String? {
  return (Bundle.main.infoDictionary?[key] as? String)?
    .replacingOccurrences(of: "\\", with: "")
}
