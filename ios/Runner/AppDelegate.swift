import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var launchUri: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let url = launchOptions?[.url] as? URL {
      launchUri = url.absoluteString
    }
    DispatchQueue.main.async { [weak self] in
      guard let controller = self?.window?.rootViewController as? FlutterViewController else {
        return
      }
      let channel = FlutterMethodChannel(
        name: "spendping/launch",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "consumeLaunch" {
          result(self?.launchUri)
          self?.launchUri = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    launchUri = url.absoluteString
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(
        name: "spendping/launch",
        binaryMessenger: controller.binaryMessenger
      ).invokeMethod("opened", arguments: url.absoluteString)
    }
    return true
  }
}
