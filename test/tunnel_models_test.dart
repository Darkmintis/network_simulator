import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';

void main() {
  group('TunnelStatus', () {
    test('parse known wire values', () {
      expect(TunnelStatus.parse('idle'), TunnelStatus.idle);
      expect(TunnelStatus.parse('preparing'), TunnelStatus.preparing);
      expect(TunnelStatus.parse('connecting'), TunnelStatus.connecting);
      expect(TunnelStatus.parse('connected'), TunnelStatus.connected);
      expect(TunnelStatus.parse('disconnecting'), TunnelStatus.disconnecting);
      expect(TunnelStatus.parse('error'), TunnelStatus.error);
      expect(TunnelStatus.parse('unsupported'), TunnelStatus.unsupported);
    });

    test('parse unknown and null as idle', () {
      expect(TunnelStatus.parse(null), TunnelStatus.idle);
      expect(TunnelStatus.parse('nope'), TunnelStatus.idle);
      expect(TunnelStatus.parse(''), TunnelStatus.idle);
    });

    test('labels and activity flags', () {
      expect(TunnelStatus.connected.label, 'Connected');
      expect(TunnelStatus.idle.isActive, isFalse);
      expect(TunnelStatus.preparing.isActive, isTrue);
      expect(TunnelStatus.connecting.isActive, isTrue);
      expect(TunnelStatus.connected.isActive, isTrue);
      expect(TunnelStatus.error.isActive, isFalse);
    });

    test('wireName matches enum name', () {
      for (final status in TunnelStatus.values) {
        expect(status.wireName, status.name);
      }
    });
  });

  group('TunnelStats', () {
    test('zero factory', () {
      const stats = TunnelStats.zero();
      expect(stats.bytesUploaded, 0);
      expect(stats.bytesDownloaded, 0);
      expect(stats.packetsDropped, 0);
      expect(stats.uploadMbps, 0);
      expect(stats.downloadMbps, 0);
    });

    test('fromMap with missing keys defaults safely', () {
      final stats = TunnelStats.fromMap(<String, dynamic>{});
      expect(stats.bytesUploaded, 0);
      expect(stats.summary, contains('dropped 0'));
    });

    test('fromMap parses numeric values', () {
      final stats = TunnelStats.fromMap({
        'bytesUploaded': 100,
        'bytesDownloaded': 200,
        'packetsUploaded': 3,
        'packetsDownloaded': 4,
        'packetsDropped': 5,
        'uploadMbps': 1.25,
        'downloadMbps': 2.5,
      });
      expect(stats.bytesUploaded, 100);
      expect(stats.bytesDownloaded, 200);
      expect(stats.packetsUploaded, 3);
      expect(stats.packetsDownloaded, 4);
      expect(stats.packetsDropped, 5);
      expect(stats.uploadMbps, 1.25);
      expect(stats.downloadMbps, 2.5);
      expect(stats.summary, contains('2.50 Mbps'));
      expect(stats.summary, contains('1.25 Mbps'));
      expect(stats.summary, contains('dropped 5'));
    });
  });
}
