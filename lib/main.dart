import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

import 'core/di/di.dart';
import 'core/env.dart';
import 'core/services/notification_service.dart';
import 'presentation/pages/about_page.dart';
import 'presentation/pages/abouts/developer_info_page.dart';
import 'presentation/pages/calendar_page.dart';
import 'presentation/pages/create_page.dart';
import 'presentation/pages/detail_page.dart';
import 'presentation/theme/dark_theme.dart';
import 'presentation/theme/light_theme.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await configureDependencies();
  final NotificationService notificationService = getIt<NotificationService>();
  await notificationService.getPermissions();
  await notificationService.init();
  // await initializeDateFormatting('ko_KR', 'null');
  if (kDebugMode) {
    Env.init(Environ.local);
  } else {
    Env.init(Environ.production);
  }
  FlutterNativeSplash.remove();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LightTheme.theme,
      darkTheme: DarkTheme.theme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
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
        '/detail': (context) => DetailPage(),
        '/about': (context) => const AboutPage(),
        '/about/developer_info': (context) => const DeveloperInfoPage(),
      },
    );
  }
}
