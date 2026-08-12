import NetworkExtension
import Foundation

/**
 WIP example Packet Tunnel provider.
 Create an Xcode Network Extension target named NetworkSimulatorTunnel and
 add this file. Configure entitlements per doc/ios-setup.md.

 This target is NOT wired into the Xcode project automatically — contributors
 must add the extension target on macOS.
 */
class PacketTunnelProvider: NEPacketTunnelProvider {
  private var latencyMs: Double = 0
  private var jitterMs: Double = 0
  private var packetLoss: Double = 0
  private var offline: Bool = false

  override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    if let proto = protocolConfiguration as? NETunnelProviderProtocol,
       let config = proto.providerConfiguration {
      latencyMs = config["latencyMs"] as? Double ?? 0
      jitterMs = config["jitterMs"] as? Double ?? 0
      packetLoss = config["packetLoss"] as? Double ?? 0
      offline = config["isOffline"] as? Bool ?? false
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
      self?.readLoop()
      completionHandler(nil)
    }
  }

  override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    completionHandler()
  }

  private func readLoop() {
    packetFlow.readPackets { [weak self] packets, protocols in
      guard let self = self else { return }
      var shaped: [Data] = []
      var shapedProtocols: [NSNumber] = []
      for (i, packet) in packets.enumerated() {
        if self.offline || (self.packetLoss > 0 && Double.random(in: 0..<1) < self.packetLoss) {
          continue
        }
        var delay = self.latencyMs
        if self.jitterMs > 0 {
          delay += Double.random(in: -self.jitterMs...self.jitterMs)
        }
        if delay > 0 {
          Thread.sleep(forTimeInterval: max(0, delay) / 1000.0)
        }
        // WIP: replace with real userspace forwarder (see doc/ios-wip.md).
        shaped.append(packet)
        shapedProtocols.append(protocols[i])
      }
      if !shaped.isEmpty {
        self.packetFlow.writePackets(shaped, withProtocols: shapedProtocols)
      }
      self.readLoop()
    }
  }
}
