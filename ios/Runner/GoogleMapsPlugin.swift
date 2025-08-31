import Flutter
import UIKit
import GoogleMaps
import MapKit

class GoogleMapsPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.artbeat.app/google_maps", binaryMessenger: registrar.messenger())
    let instance = GoogleMapsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showMap":
      if let args = call.arguments as? [String: Any],
         let lat = args["latitude"] as? Double,
         let lng = args["longitude"] as? Double {
        showMap(latitude: lat, longitude: lng)
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

  private func showMap(latitude: Double, longitude: Double) {
    let mapVC = MapViewController(latitude: latitude, longitude: longitude)
    mapVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen

    // Get the root view controller from the key window
    if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
      rootVC.present(mapVC, animated: true, completion: nil)
    }
  }
}
