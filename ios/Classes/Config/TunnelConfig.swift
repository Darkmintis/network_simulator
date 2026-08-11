import Foundation

/// Immutable shaping parameters shared with the packet tunnel provider.
public struct TunnelConfig: Codable {
  public var mode: String
  public var latencyMs: Double
  public var downloadMbps: Double
  public var uploadMbps: Double
  public var jitterMs: Double
  public var packetLoss: Double
  public var isOffline: Bool

  public static func from(map: [String: Any]?) -> TunnelConfig {
    let download = (map?["downloadMbps"] as? Double) ?? -1
    let upload = (map?["uploadMbps"] as? Double) ?? -1
    return TunnelConfig(
      mode: map?["mode"] as? String ?? "normal",
      latencyMs: map?["latencyMs"] as? Double ?? 0,
      downloadMbps: download < 0 ? .infinity : download,
      uploadMbps: upload < 0 ? .infinity : upload,
      jitterMs: map?["jitterMs"] as? Double ?? 0,
      packetLoss: map?["packetLoss"] as? Double ?? 0,
      isOffline: map?["isOffline"] as? Bool ?? false
    )
  }

  public func toProviderDict() -> [String: Any] {
    [
      "mode": mode,
      "latencyMs": latencyMs,
      "downloadMbps": downloadMbps.isFinite ? downloadMbps : -1,
      "uploadMbps": uploadMbps.isFinite ? uploadMbps : -1,
      "jitterMs": jitterMs,
      "packetLoss": packetLoss,
      "isOffline": isOffline,
    ]
  }
}
