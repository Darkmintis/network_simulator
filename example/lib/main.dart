import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:network_simulator/network_simulator.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  NetworkSimulator.init(
    dio: dio,
    enableOverlay: true,
    navigatorKey: navigatorKey,
  );

  runApp(NetworkSimulatorExampleApp(dio: dio, navigatorKey: navigatorKey));
}

class NetworkSimulatorExampleApp extends StatelessWidget {
  const NetworkSimulatorExampleApp({
    super.key,
    required this.dio,
    required this.navigatorKey,
  });

  final Dio dio;
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
      home: DemoHomePage(dio: dio),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key, required this.dio});

  final Dio dio;

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  String _result = 'Tap a button to make a request';

  Future<void> _getPosts() async {
    setState(() => _result = 'Loading posts...');
    try {
      final response = await widget.dio.get('/posts');
      setState(() => _result = 'Fetched ${response.data.length} posts');
    } on DioException catch (e) {
      setState(() => _result = 'Error: ${e.message}');
    }
  }

  Future<void> _getPost(int id) async {
    setState(() => _result = 'Loading post $id...');
    try {
      final response = await widget.dio.get('/posts/$id');
      setState(() => _result = 'Post $id: ${response.data['title']}');
    } on DioException catch (e) {
      setState(() => _result = 'Error: ${e.message}');
    }
  }

  Future<void> _getComments() async {
    setState(() => _result = 'Loading comments...');
    try {
      final response = await widget.dio.get('/comments');
      setState(() => _result = 'Fetched ${response.data.length} comments');
    } on DioException catch (e) {
      setState(() => _result = 'Error: ${e.message}');
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
            onPressed: () => NetworkSimulator.reset(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: _getPosts,
                  child: const Text('GET /posts'),
                ),
                FilledButton(
                  onPressed: () => _getPost(1),
                  child: const Text('GET /posts/1'),
                ),
                FilledButton(
                  onPressed: _getComments,
                  child: const Text('GET /comments'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
