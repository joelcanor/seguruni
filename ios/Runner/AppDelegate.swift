import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Inicializa Google Maps con tu API key
    GMSServices.provideAPIKey("AIzaSyDmyKO5io62kzxQTPEHLaTxMQYRnUmSQe8")
    
    // Registra los plugins generados por Flutter
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
