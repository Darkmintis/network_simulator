import Foundation
import NetworkExtension

/**
 Manages NETunnelProviderManager lifecycle for the host app.

 WIP / needs device testing — contributors: verify entitlements and provider bundle id.
 */
final class TunnelManager {
  private var manager: NETunnelProviderManager?

  func start(
    config: TunnelConfig,
    providerBundleIdentifier: String?,
    completion: @escaping (Error?) -> Void
  ) {
    guard let providerBundleIdentifier, !providerBundleIdentifier.isEmpty else {
      completion(
        NSError(
          domain: "network_simulator",
          code: 1,
          userInfo: [
            NSLocalizedDescriptionKey:
              "providerBundleIdentifier is required on iOS. See doc/ios-setup.md",
          ]
        )
      )
      return
    }

    NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
      if let error = error {
        completion(error)
        return
      }

      let manager = managers?.first ?? NETunnelProviderManager()
      let proto = NETunnelProviderProtocol()
      proto.providerBundleIdentifier = providerBundleIdentifier
      proto.serverAddress = "NetworkSimulator Local"
      proto.providerConfiguration = config.toProviderDict()

      manager.protocolConfiguration = proto
      manager.localizedDescription = "Network Simulator"
      manager.isEnabled = true

      manager.saveToPreferences { saveError in
        if let saveError = saveError {
          completion(saveError)
          return
        }
        manager.loadFromPreferences { loadError in
          if let loadError = loadError {
            completion(loadError)
            return
          }
          do {
            try manager.connection.startVPNTunnel()
            self?.manager = manager
            completion(nil)
          } catch {
            completion(error)
          }
        }
      }
    }
  }

  func stop(completion: @escaping (Error?) -> Void) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      if let error = error {
        completion(error)
        return
      }
      managers?.forEach { $0.connection.stopVPNTunnel() }
      completion(nil)
    }
  }

  func updateConfig(_ config: TunnelConfig, completion: @escaping (Error?) -> Void) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      if let error = error {
        completion(error)
        return
      }
      guard let manager = managers?.first,
            let connection = manager.connection as? NETunnelProviderSession,
            let proto = manager.protocolConfiguration as? NETunnelProviderProtocol else {
        completion(nil)
        return
      }
      proto.providerConfiguration = config.toProviderDict()
      manager.protocolConfiguration = proto
      manager.saveToPreferences { saveError in
        if let saveError = saveError {
          completion(saveError)
          return
        }
        let message: [String: Any] = ["type": "updateConfig", "config": config.toProviderDict()]
        do {
          let data = try JSONSerialization.data(withJSONObject: message)
          try connection.sendProviderMessage(data) { _ in }
          completion(nil)
        } catch {
          completion(error)
        }
      }
    }
  }
}
