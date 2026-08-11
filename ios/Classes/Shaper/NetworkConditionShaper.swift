import Foundation

/// Shared shaper contract matching Android NetworkConditionShaper.
public final class NetworkConditionShaper {
  private var latencyMs: Double = 0
  private var jitterMs: Double = 0
  private var packetLoss: Double = 0
  private var offline: Bool = false
  private var uploadBytesPerSecond: Double = .infinity
  private var downloadBytesPerSecond: Double = .infinity
  private let lock = NSLock()

  public init() {}

  public func update(config: TunnelConfig) {
    lock.lock()
    defer { lock.unlock() }
    latencyMs = config.latencyMs
    jitterMs = config.jitterMs
    packetLoss = config.packetLoss
    offline = config.isOffline
    uploadBytesPerSecond = mbpsToBps(config.uploadMbps)
    downloadBytesPerSecond = mbpsToBps(config.downloadMbps)
  }

  public func shouldDrop() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    if offline { return true }
    if packetLoss <= 0 { return false }
    return Double.random(in: 0..<1) < min(max(packetLoss, 0), 1)
  }

  public func shape(byteCount: Int) {
    lock.lock()
    let latency = latencyMs
    let jitter = jitterMs
    let rate = downloadBytesPerSecond
    lock.unlock()

    if rate.isFinite && rate > 0 {
      let seconds = Double(byteCount) / rate
      Thread.sleep(forTimeInterval: seconds)
    }
    var delay = latency
    if jitter > 0 {
      delay += Double.random(in: -jitter...jitter)
    }
    if delay > 0 {
      Thread.sleep(forTimeInterval: delay / 1000.0)
    }
  }

  private func mbpsToBps(_ mbps: Double) -> Double {
    if !mbps.isFinite { return .infinity }
    if mbps <= 0 { return 0 }
    return mbps * 1024 * 1024 / 8
  }
}
