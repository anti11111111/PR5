import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_api.dart';
import 'auth/auth_notifier.dart';
import 'core/api_client.dart';
import 'core/api_exceptions.dart';
import 'core/config.dart';
import 'data/catalog_cache.dart';
import 'repositories/salon_api.dart';
import 'router.dart';
import 'state/catalog_controller.dart';
import 'widgets/inactivity_watcher.dart';

const _accounts = {
  'admin': ('admin@salon.local', 'Admin123!'),
  'manager': ('manager@salon.local', 'Manager1!'),
  'reader': ('reader@salon.local', 'Reader12!'),
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final params = Uri.base.queryParameters;
  ShotFlags.delayMs = int.tryParse(params['__delay'] ?? '') ?? 0;
  ShotFlags.failCode = int.tryParse(params['__fail'] ?? '');
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenBox();
  final dio = buildDio(tokens: tokens);
  final auth = AuthNotifier(prefs, AuthApi(dio), tokens);
  tokens.refresh = auth.refresh;
  final shot = params['shot'];
  final account = _accounts[shot];
  if (account != null) {
    try {
      await auth.login(account.$1, account.$2);
      final tamper = params['tamper'];
      if (tamper != null) {
        await auth.tamperRole(tamper);
      }
    } on ApiException catch (error) {
      auth.message = error.message;
    }
  } else {
    await auth.restore();
  }
  final cache = CatalogCache();
  final api = SalonApi(dio);
  if (auth.isAuthenticated) {
    try {
      await api.warm(cache);
    } on ApiException catch (error) {
      cache.notice = error.message;
    }
  } else if (auth.message != null) {
    cache.notice = auth.message;
  }
  final router = buildRouter(auth);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        Provider<Dio>.value(value: dio),
        Provider.value(value: api),
        Provider.value(value: cache),
        ChangeNotifierProvider(create: (_) => CatalogController(cache, api)),
      ],
      child: SalonApp(auth: auth, router: router),
    ),
  );
}

class SalonApp extends StatefulWidget {
  const SalonApp({super.key, required this.auth, required this.router});

  final AuthNotifier auth;
  final GoRouter router;

  @override
  State<SalonApp> createState() => _SalonAppState();
}

class _SalonAppState extends State<SalonApp> {
  var _warning = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Автосалон',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      routerConfig: widget.router,
      builder: (context, child) {
        return InactivityWatcher(
          enabled: widget.auth.isAuthenticated,
          onWarning: () => setState(() => _warning = true),
          onTimeout: () => _end('idle'),
          onLimit: () => _end('limit'),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (_warning && widget.auth.isAuthenticated)
                IdleWarning(onContinue: () => setState(() => _warning = false)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _end(String reason) async {
    setState(() => _warning = false);
    await widget.auth.logout();
    widget.router.go('/login?reason=$reason');
  }
}
