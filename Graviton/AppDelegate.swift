//  Created by Dominik Hauser on 22.12.21.
//

import UIKit
import AVFAudio

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    application.isIdleTimerDisabled = true
    // Background music mixes with other audio and respects the silent switch
    try? AVAudioSession.sharedInstance().setCategory(.ambient)
    UserDefaults.standard.register(defaults: ["soundEnabled": true])
    return true
  }

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}
