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
    // Initialize Google Maps
    GMSServices.provideAPIKey("AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA")
    
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
