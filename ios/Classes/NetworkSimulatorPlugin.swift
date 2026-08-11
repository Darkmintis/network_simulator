import Flutter
import Foundation
import NetworkExtension

/**
 Flutter plugin entry for iOS tunnel control.

 WIP: Packet tunnel provider must live in a host Network Extension target.
 See docs/ios-setup.md and docs/ios-wip.md.
 */
public class NetworkSimulatorPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var statusEventSink: FlutterEventSink?
  private var statsEventSink: FlutterEventSink?
  private var errorEventSink: FlutterEventSink?
  private let tunnelManager = TunnelManager()
  private var status: String = "idle"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NetworkSimulatorPlugin()
    instance.methodChannel = FlutterMethodChannel(
      name: "network_simulator/tunnel",
      binaryMessenger: registrar.messenger()
    )
    instance.methodChannel?.setMethodCallHandler(instance.handle)

    FlutterEventChannel(name: "network_simulator/tunnel_status", binaryMessenger: registrar.messenger())
      .setStreamHandler(StatusStreamHandler(plugin: instance))
    FlutterEventChannel(name: "network_simulator/tunnel_stats", binaryMessenger: registrar.messenger())
      .setStreamHandler(StatsStreamHandler(plugin: instance))
    FlutterEventChannel(name: "network_simulator/tunnel_errors", binaryMessenger: registrar.messenger())
      .setStreamHandler(ErrorStreamHandler(plugin: instance))
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(true)
    case "getStatus":
      result(status)
    case "startTunnel":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: "Missing arguments", details: nil))
        return
      }
      let config = TunnelConfig.from(map: args["config"] as? [String: Any])
      let providerId = args["providerBundleIdentifier"] as? String
      emitStatus("preparing")
      tunnelManager.start(
        config: config,
        providerBundleIdentifier: providerId
      ) { [weak self] error in
        if let error = error {
          self?.emitStatus("error")
          self?.errorEventSink?(error.localizedDescription)
          result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
        } else {
          self?.emitStatus("connected")
          result(nil)
        }
      }
    case "stopTunnel":
      emitStatus("disconnecting")
      tunnelManager.stop { [weak self] error in
        if let error = error {
          self?.emitStatus("error")
          self?.errorEventSink?(error.localizedDescription)
          result(FlutterError(code: "stop_failed", message: error.localizedDescription, details: nil))
        } else {
          self?.emitStatus("idle")
          result(nil)
        }
      }
    case "updateConfig":
      let config = TunnelConfig.from(map: call.arguments as? [String: Any])
      tunnelManager.updateConfig(config) { [weak self] error in
        if let error = error {
          self?.errorEventSink?(error.localizedDescription)
          result(FlutterError(code: "update_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  fileprivate func emitStatus(_ value: String) {
    status = value
    statusEventSink?(value)
  }

  fileprivate func setStatusSink(_ sink: FlutterEventSink?) { statusEventSink = sink }
  fileprivate func setStatsSink(_ sink: FlutterEventSink?) { statsEventSink = sink }
  fileprivate func setErrorSink(_ sink: FlutterEventSink?) { errorEventSink = sink }
}

private class StatusStreamHandler: NSObject, FlutterStreamHandler {
  weak var plugin: NetworkSimulatorPlugin?
  init(plugin: NetworkSimulatorPlugin) { self.plugin = plugin }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    plugin?.setStatusSink(events)
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    plugin?.setStatusSink(nil)
    return nil
  }
}

private class StatsStreamHandler: NSObject, FlutterStreamHandler {
  weak var plugin: NetworkSimulatorPlugin?
  init(plugin: NetworkSimulatorPlugin) { self.plugin = plugin }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    plugin?.setStatsSink(events)
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    plugin?.setStatsSink(nil)
    return nil
  }
}

private class ErrorStreamHandler: NSObject, FlutterStreamHandler {
  weak var plugin: NetworkSimulatorPlugin?
  init(plugin: NetworkSimulatorPlugin) { self.plugin = plugin }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    plugin?.setErrorSink(events)
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    plugin?.setErrorSink(nil)
    return nil
  }
}
