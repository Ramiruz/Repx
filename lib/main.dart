import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/pushup_counter.dart';
import 'services/settings_service.dart';
import 'services/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/drawing_utils.dart';
import 'package:REPX/l10n/app_localizations.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // 📱 POR DEFECTO: PORTRAIT para toda la app (vertical)
  // Solo ExerciseScreen cambiará a landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PushUpCounter()),
        ChangeNotifierProvider(
          create: (_) => SettingsService()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'REPX',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: DrawingUtils.primaryColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(foregroundColor: Colors.white),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

