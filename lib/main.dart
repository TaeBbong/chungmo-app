import 'package:flutter/material.dart';

import 'core/di/di.dart';
import 'presentation/pages/create/create_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CreatePage(),
    );
  }
}
