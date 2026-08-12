import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_simulator/network_simulator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NetworkSimulator.init(
    providerBundleIdentifier:
        'com.example.networkSimulator.NetworkSimulatorTunnel',
  );
  runApp(const ExampleApp());
}

/// Minimal demo app — only shows HTTP requests against a live API.
///
/// The network simulator is opened separately via the app-bar icon.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ApiDemoPage(),
    );
  }
}

class _RequestResult {
  _RequestResult({
    required this.label,
    required this.durationMs,
    this.statusCode,
    this.error,
    this.bytes,
  });

  final String label;
  final int durationMs;
  final int? statusCode;
  final String? error;
  final int? bytes;
}

class ApiDemoPage extends StatefulWidget {
  const ApiDemoPage({super.key});

  @override
  State<ApiDemoPage> createState() => _ApiDemoPageState();
}

class _ApiDemoPageState extends State<ApiDemoPage> {
  _RequestResult? _lastResult;
  bool _loading = false;

  Future<void> _request(String label, Future<http.Response> Function() call) async {
    setState(() {
      _loading = true;
      _lastResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final response = await call();
      stopwatch.stop();
      setState(() {
        _lastResult = _RequestResult(
          label: label,
          durationMs: stopwatch.elapsedMilliseconds,
          statusCode: response.statusCode,
          bytes: response.body.length,
        );
      });
    } catch (error) {
      stopwatch.stop();
      setState(() {
        _lastResult = _RequestResult(
          label: label,
          durationMs: stopwatch.elapsedMilliseconds,
          error: error.toString(),
        );
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
        actions: const [NetworkSimulatorLauncherIcon()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _loading
                  ? null
                  : () => _request(
                      'GET /posts',
                      () => http.get(
                        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
                      ),
                    ),
              child: const Text('GET /posts'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () => _request(
                      'GET /posts/1',
                      () => http.get(
                        Uri.parse(
                          'https://jsonplaceholder.typicode.com/posts/1',
                        ),
                      ),
                    ),
              child: const Text('GET /posts/1'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () => _request(
                      'POST /posts',
                      () => http.post(
                        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
                        headers: {'Content-Type': 'application/json'},
                        body: '{"title":"test","body":"hello","userId":1}',
                      ),
                    ),
              child: const Text('POST /posts'),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_lastResult != null && !_loading) ...[
              Text(
                _lastResult!.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _lastResult!.error != null
                    ? '${_lastResult!.durationMs} ms · Error: ${_lastResult!.error}'
                    : '${_lastResult!.durationMs} ms · HTTP ${_lastResult!.statusCode} · ${_lastResult!.bytes} bytes',
                style: TextStyle(
                  color: _lastResult!.error != null ? Colors.red : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
