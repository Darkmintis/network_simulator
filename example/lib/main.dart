import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:network_simulator/network_simulator.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://reqres.in',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      contentType: Headers.jsonContentType,
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
    const background = Color(0xFF081120);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Network Simulator Demo',
      theme:
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF22D3EE),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: background,
            useMaterial3: true,
          ).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: background,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
            ),
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
  final _emailController = TextEditingController(text: 'eve.holt@reqres.in');
  final _passwordController = TextEditingController(text: 'cityslicka');

  bool _loading = false;
  String _status = 'Ready';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _status = 'Signing in...';
    });

    try {
      final response = await widget.dio.post<Map<String, dynamic>>(
        '/api/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Token received: ${response.data?['token'] ?? 'unknown'}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login request completed. Open the Network Simulator overlay to inspect the log.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = error.message ?? 'Request failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Request failed')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _status = 'Fetching users...';
    });

    try {
      await widget.dio.get('/api/users?page=2');
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'User feed fetched successfully.';
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = error.message ?? 'Request failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Simulator Example'),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF081120), Color(0xFF0E1B33)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF14213D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App-level network simulation',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the floating Network Simulator button to switch modes and watch live request logs update in real time.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: _loading ? null : _login,
                            child: Text(
                              _loading ? 'Working...' : 'Login request',
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: _loading ? null : _fetchUsers,
                            child: const Text('Fetch users'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _StatusCard(status: _status),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: NetworkSimulator.logger,
                  builder: (context, _) {
                    final logs = NetworkSimulator.logger.logs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest logs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (logs.isEmpty)
                          Text(
                            'No requests yet. Trigger one of the actions above.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white60,
                            ),
                          )
                        else
                          ...logs
                              .take(3)
                              .map(
                                (log) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LogCard(log: log),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        status,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final NetworkLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${log.method} ${log.url}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${log.durationMs} ms · ${log.success ? 'success' : 'failed'}${log.statusCode == null ? '' : ' · ${log.statusCode}'}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (log.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              log.errorMessage!,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}
