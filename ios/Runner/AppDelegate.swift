import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "taskflow.app/platform",
        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getDocumentsDirectory":
          // App-private, persistent directory used for taskflow_data.json.
          let paths = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true)
          result(paths.first ?? NSTemporaryDirectory())
        case "copyToClipboard":
          if let args = call.arguments as? [String: Any],
            let text = args["text"] as? String
          {
            UIPasteboard.general.string = text
            result(nil)
          } else {
            result(
              FlutterError(code: "bad_args", message: "Missing 'text' argument", details: nil))
          }
        case "getClipboard":
          result(UIPasteboard.general.string)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
