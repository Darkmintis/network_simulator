import Foundation
import NetworkExtension

/**
 Packet tunnel provider — local traffic shaper (no remote VPN server).

 STATUS: WIP / UNTESTED ON DEVICE
 Contributors should validate on a real iPhone with proper entitlements.
 Copy this class into the host app's Network Extension target
 (see example/ios/NetworkSimulatorTunnel and doc/ios-setup.md).
 */
open class NetworkSimulatorPacketTunnelProvider: NEPacketTunnelProvider {
  private let shaper = NetworkConditionShaper()
  private var config = TunnelConfig.from(map: nil)
  private let queue = DispatchQueue(label: "com.darkmintis.network_simulator.tunnel")

  open override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    if let proto = protocolConfiguration as? NETunnelProviderProtocol,
       let providerConfig = proto.providerConfiguration {
      config = TunnelConfig.from(map: providerConfig)
      shaper.update(config: config)
    }

    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
    let ipv4 = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.255"])
    ipv4.includedRoutes = [NEIPv4Route.default()]
    settings.ipv4Settings = ipv4
    settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
    settings.mtu = 1500

    setTunnelNetworkSettings(settings) { [weak self] error in
      if let error = error {
        completionHandler(error)
        return
      }
      self?.readPackets()
      completionHandler(nil)
    }
  }

  open override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    completionHandler()
  }

  open override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
    guard
      let object = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
      let type = object["type"] as? String,
      type == "updateConfig",
      let configMap = object["config"] as? [String: Any]
    else {
      completionHandler?(nil)
      return
    }
    config = TunnelConfig.from(map: configMap)
    shaper.update(config: config)
    completionHandler?(nil)
  }

  private func readPackets() {
    packetFlow.readPackets { [weak self] packets, protocols in
      guard let self = self else { return }
      self.queue.async {
        var outPackets: [Data] = []
        var outProtocols: [NSNumber] = []
        for (index, packet) in packets.enumerated() {
          if self.shaper.shouldDrop() {
            continue
          }
          self.shaper.shape(byteCount: packet.count)
          // WIP: full userspace NAT/forwarding still needs contributor work.
          // Echoing shaped packets is insufficient for production; replace with
          // a userspace stack / forwarding engine that sends via NWConnection
          // outside the tunnel to avoid loops.
          outPackets.append(packet)
          outProtocols.append(protocols[index])
        }
        if !outPackets.isEmpty {
          self.packetFlow.writePackets(outPackets, withProtocols: outProtocols)
        }
        self.readPackets()
      }
    }
  }
}
