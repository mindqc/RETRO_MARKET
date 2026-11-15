import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/retro_theme.dart';
import 'core/widgets/seasonal_decor_overlay.dart';

/// Root Application Widget for izithrift (RETRO MARKET).
class IzithriftApp extends ConsumerWidget {
  const IzithriftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: RetroTheme.lightTheme,
      builder: (context, child) {
        return SeasonalDecorOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
