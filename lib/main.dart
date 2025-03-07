import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/di/di.dart';
import 'core/env.dart';
import 'presentation/pages/calendar_page.dart';
import 'presentation/pages/create_page.dart';
import 'presentation/pages/detail_page.dart';
import 'presentation/theme/dark_theme.dart';
import 'presentation/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // await initializeDateFormatting('ko_KR', 'null');
  Env.init(Environ.local);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
        '/': (context) => CreatePage(),
        // ignore: prefer_const_constructors
        '/calendar': (context) => CalendarPage(),
        '/detail': (context) => DetailPage(),
      },
    );
  }
}
