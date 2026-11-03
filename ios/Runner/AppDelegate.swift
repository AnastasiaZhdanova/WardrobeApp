import Flutter
import LocalAuthentication
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppLockPlugin") {
      AppLockPlugin.register(with: registrar)
    }
  }
}

/// Handles `wardrobe_app/app_lock`. Replies `{status, message}`, see
/// `method_channel_device_auth.dart` for the contract.
///
/// `.deviceOwnerAuthentication` = Face ID / Touch ID with the passcode as
/// fallback, so a failed face scan never locks the owner out.
final class AppLockPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "wardrobe_app/app_lock", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(AppLockPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "authenticate" else {
      result(FlutterMethodNotImplemented)
      return
    }
    let reason = (call.arguments as? [String: Any])?["reason"] as? String ?? "Unlock"
    // A fresh context per attempt: a reused one keeps a previous success.
    let context = LAContext()
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      result(["status": "unavailable"])
      return
    }
    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
      success, error in
      // LocalAuthentication calls back on a private queue; Flutter results
      // must be delivered on the main thread.
      DispatchQueue.main.async {
        result(Self.reply(success: success, error: error))
      }
    }
  }

  private static func reply(success: Bool, error: Error?) -> [String: Any?] {
    if success { return ["status": "success"] }
    switch (error as? LAError)?.code {
    case .userCancel?, .appCancel?, .systemCancel?:
      return ["status": "cancelled"]
    case .passcodeNotSet?, .biometryNotAvailable?:
      return ["status": "unavailable"]
    default:
      return ["status": "failed", "message": error?.localizedDescription ?? "Not recognised."]
    }
  }
}
