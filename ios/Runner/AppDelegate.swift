import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Get API key from configuration
    if let apiKey = Bundle.main.infoDictionary?["GoogleMapsApiKey"] as? String {
      GMSServices.provideAPIKey(apiKey)
    } else {
      fatalError("Google Maps API key not found in configuration")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
