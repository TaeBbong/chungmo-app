import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/di/di.dart';
import 'core/env.dart';
import 'presentation/pages/calendar/calendar_page.dart';
import 'presentation/pages/create/create_page.dart';
import 'presentation/theme/dark_theme.dart';
import 'presentation/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
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
      initialRoute: '/',
      routes: {
        '/': (context) => CreatePage(),
        '/calendar': (context) => CalendarPage(),
      },
    );
  }
}
