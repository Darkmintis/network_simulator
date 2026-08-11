/// Preset network condition profiles applied by the native traffic shaper.
enum NetworkMode {
  normal,
  slow2G,
  slow3G,
  fast3G,
  unstable4G,
  offline,
  custom,
}

extension NetworkModeProfile on NetworkMode {
  String get label {
    switch (this) {
      case NetworkMode.normal:
        return 'Normal';
      case NetworkMode.slow2G:
        return 'Slow 2G';
      case NetworkMode.slow3G:
        return 'Slow 3G';
      case NetworkMode.fast3G:
        return 'Fast 3G';
      case NetworkMode.unstable4G:
        return 'Unstable 4G';
      case NetworkMode.offline:
        return 'Offline';
      case NetworkMode.custom:
        return 'Custom';
    }
  }
}
