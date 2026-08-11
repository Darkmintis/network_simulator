import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_simulator/network_simulator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final navigatorKey = GlobalKey<NavigatorState>();

  await NetworkSimulator.init(
    enableOverlay: true,
    navigatorKey: navigatorKey,
    providerBundleIdentifier:
        'com.example.networkSimulator.NetworkSimulatorTunnel',
  );

  runApp(NetworkSimulatorExampleApp(navigatorKey: navigatorKey));
}

class NetworkSimulatorExampleApp extends StatelessWidget {
  const NetworkSimulatorExampleApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Network Simulator',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF22D3EE),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  String _result = 'Start the tunnel from the overlay, then fetch.';

  Future<void> _get(String path) async {
    setState(() => _result = 'Loading $path ...');
    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com$path'),
      );
      setState(
        () => _result = 'HTTP ${response.statusCode} · ${response.body.length} bytes',
      );
    } catch (error) {
      setState(() => _result = 'Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Simulator'),
        actions: [
          TextButton(
            onPressed: () => NetworkSimulator.setMode(NetworkMode.slow3G),
            child: const Text('Slow 3G'),
          ),
          TextButton(
            onPressed: () => NetworkSimulator.offline(),
            child: const Text('Offline'),
          ),
          TextButton(
            onPressed: () async => NetworkSimulator.stopTunnel(),
            child: const Text('Stop'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: NetworkSimulator.controller,
              builder: (context, _) {
                final c = NetworkSimulator.controller;
                return Text(
                  'Tunnel: ${c.status.label}\n${c.stats.summary}',
                  textAlign: TextAlign.center,
                );
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => NetworkSimulator.startTunnel(),
              child: const Text('Start tunnel'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => _get('/posts'),
                  child: const Text('GET /posts'),
                ),
                FilledButton(
                  onPressed: () => _get('/posts/1'),
                  child: const Text('GET /posts/1'),
                ),
                FilledButton(
                  onPressed: () => _get('/comments'),
                  child: const Text('GET /comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
