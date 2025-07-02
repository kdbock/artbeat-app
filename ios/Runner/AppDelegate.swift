import Flutter
import UIKit
import GoogleMaps
import MapKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps by reading API key from Info.plist
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["GMSApiKey"] as? String {
      print("Google Maps API Key found: \(String(apiKey.prefix(10)))...")
      GMSServices.provideAPIKey(apiKey)
    } else {
      print("ERROR: Google Maps API Key not found in Info.plist")
      // Fallback to hardcoded key
      GMSServices.provideAPIKey("AIzaSyBvmSCvenoo9u-eXNzKm_oDJJJjC0MbqHA")
    }
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let mapChannel = FlutterMethodChannel(
      name: "com.artbeat.app/google_maps",
      binaryMessenger: controller.binaryMessenger)
    
    mapChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      switch call.method {
      case "showMap":
        if let args = call.arguments as? [String: Any],
           let lat = args["latitude"] as? Double,
           let lng = args["longitude"] as? Double {
          self.showMap(latitude: lat, longitude: lng)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGS",
                            message: "Invalid arguments",
                            details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func showMap(latitude: Double, longitude: Double) {
    let mapVC = MapViewController(latitude: latitude, longitude: longitude)
    mapVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
    window?.rootViewController?.present(mapVC, animated: true, completion: nil)
  }
}
