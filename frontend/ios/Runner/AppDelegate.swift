import Flutter
import UIKit
import GoogleMaps
#if canImport(workmanager_apple)
import workmanager_apple
#elseif canImport(workmanager)
import workmanager
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyA2wcm3xW9ImUYiIRGgPPrGzcwhnAN7HLU")
#if canImport(workmanager_apple)
    WorkmanagerPlugin.registerLaunchHandlers()
#elseif canImport(workmanager)
    WorkmanagerPlugin.registerLaunchHandlers()
#endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
