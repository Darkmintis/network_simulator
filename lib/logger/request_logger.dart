import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/network_log.dart';

class NetworkSimulatorLogger extends ChangeNotifier {
  final List<NetworkLog> _logs = <NetworkLog>[];

  UnmodifiableListView<NetworkLog> get logs => UnmodifiableListView(_logs);

  void log(NetworkLog log) {
    _logs.insert(0, log);
    if (_logs.length > 100) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    if (_logs.isEmpty) {
      return;
    }
    _logs.clear();
    notifyListeners();
  }
}
