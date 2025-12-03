import 'package:chungmo/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/di/di.dart';
import 'core/env.dart';
import 'core/navigation/app_navigation.dart';
import 'core/services/notification_service.dart';
import 'presentation/pages/pages.dart';
import 'presentation/theme/dark_theme.dart';
import 'presentation/theme/light_theme.dart';
import 'domain/entities/schedule.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  if (kDebugMode) {
    Env.init(
        environment: Environ.local, remoteSource: RemoteSourceEnv.firebase);
  } else {
    Env.init(
        environment: Environ.production,
        remoteSource: RemoteSourceEnv.firebase);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await configureDependencies(environment: Env.backendType);
  final NotificationService notificationService = getIt<NotificationService>();
  await notificationService.getPermissions();
  await notificationService.init();
  // await initializeDateFormatting('ko_KR', 'null');
  Future.delayed(const Duration(seconds: 1), () {
    FlutterNativeSplash.remove();
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const CreatePage(),
        // ignore: prefer_const_constructors
        '/calendar': (context) => CalendarPage(),
        '/detail': (context) {
          final schedule =
              ModalRoute.of(context)!.settings.arguments as Schedule;
          return DetailPage(schedule: schedule);
        },
        '/about': (context) => const AboutPage(),
        '/about/developer_info': (context) => const DeveloperInfoPage(),
      },
    );
  }
}
