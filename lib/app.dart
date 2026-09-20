import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/app_localizations.dart';
import 'core/theme.dart';
import 'core/token_store.dart';
import 'screens/auth/auth_gate.dart';
import 'services/badge_service.dart';
import 'services/bird_log_service.dart';
import 'services/species_service.dart';
import 'services/upload_service.dart';
import 'services/user_service.dart';
import 'state/auth_session.dart';
import 'state/settings_controller.dart';

class WingmarkApp extends StatelessWidget {
  const WingmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TokenStore/ApiClient are plain singletons: created once, reused by
        // everything below (services + AuthSession all share one ApiClient
        // so the 401-refresh-and-retry logic applies everywhere).
        Provider(create: (_) => TokenStore()),
        Provider(create: (context) => ApiClient(context.read<TokenStore>())),
        ChangeNotifierProvider(
          create: (context) => AuthSession(
            tokenStore: context.read<TokenStore>(),
            apiClient: context.read<ApiClient>(),
          ),
        ),
        Provider(create: (context) => UserService(context.read<ApiClient>())),
        Provider(
            create: (context) => BirdLogService(context.read<ApiClient>())),
        Provider(
            create: (context) => SpeciesService(context.read<ApiClient>())),
        Provider(
            create: (context) => BadgeService(context.read<ApiClient>())),
        Provider(
            create: (context) => UploadService(context.read<ApiClient>())),
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          // Keeps the backend's Accept-Language header (used to resolve
          // species/badge/favorite-species text) in sync with the app's
          // effective language.
          context.read<ApiClient>().languageCode = settings.effectiveLanguageCode;
          return MaterialApp(
            title: 'wingmark',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeData,
            locale: settings.resolvedLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
