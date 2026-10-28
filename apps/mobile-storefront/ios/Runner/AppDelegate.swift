import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Google Maps key from Info.plist (filled from ios/Flutter/MapsKey.xcconfig,
  /// which isn't committed). Empty until a key is provided.
  private var mapsKey: String {
    let key = (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String) ?? ""
    return key.hasPrefix("$(") ? "" : key.trimmingCharacters(in: .whitespaces)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps crashes if a map is shown without a key, so it's only
    // initialised when one exists; Dart asks `isConfigured` and otherwise
    // falls back to the OpenStreetMap picker.
    if !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "solary/maps", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "isConfigured" {
          result(!(self?.mapsKey.isEmpty ?? true))
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
