import 'package:chungmo/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/di/di.dart';
import 'core/env.dart';
import 'core/navigation/app_navigation.dart';
import 'core/services/notification_service.dart';
import 'core/services/preferences_checker.dart';
import 'core/utils/constants.dart';
import 'presentation/pages/pages.dart';
import 'presentation/theme/dark_theme.dart';
import 'presentation/theme/light_theme.dart';
import 'domain/entities/schedule.dart';
import 'domain/entities/schedule_draft.dart';

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
  // Firebase AI Logic calls carry an App Check token. Play Integrity only
  // attests store/CI-signed builds, so debug builds use the debug provider —
  // its token (printed to the console on first run) must be registered in
  // Firebase console > App Check > Apps > Manage debug tokens.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );
  // Route Flutter and uncaught async errors to Crashlytics; skip in debug so
  // development noise does not pollute the release crash reports.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  widgetsBinding.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await configureDependencies(environment: Env.backendType);
  final NotificationService notificationService = getIt<NotificationService>();
  await notificationService.getPermissions();
  await notificationService.init();
  final bool onboarded =
      await getIt<PreferencesChecker>().hasKey(Constants.onboardingDoneKey);
  // await initializeDateFormatting('ko_KR', 'null');
  Future.delayed(const Duration(seconds: 1), () {
    FlutterNativeSplash.remove();
  });
  runApp(MainApp(showOnboarding: !onboarded));
}

class MainApp extends StatelessWidget {
  final bool showOnboarding;

  const MainApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
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
      initialRoute: showOnboarding ? '/onboarding' : '/',
      // The default generator expands '/onboarding' into '/' plus
      // '/onboarding', instantiating a hidden home underneath whose coach
      // mark tour fails offscreen; build exactly one initial route instead.
      onGenerateInitialRoutes: (String initialRoute) => [
        MaterialPageRoute<void>(
          settings: RouteSettings(name: initialRoute),
          builder: (_) => initialRoute == '/onboarding'
              ? const OnboardingPage()
              : const CreatePage(),
        ),
      ],
      routes: {
        '/': (context) => const CreatePage(),
        '/onboarding': (context) => OnboardingPage(
              review: ModalRoute.of(context)!.settings.arguments == true,
            ),
        // ignore: prefer_const_constructors
        '/calendar': (context) => CalendarPage(),
        '/detail': (context) {
          final schedule =
              ModalRoute.of(context)!.settings.arguments as Schedule;
          return DetailPage(schedule: schedule);
        },
        '/schedule/form': (context) {
          final draft =
              ModalRoute.of(context)!.settings.arguments as ScheduleDraft?;
          return ScheduleFormPage(draft: draft);
        },
        '/schedule/record': (context) {
          final schedule =
              ModalRoute.of(context)!.settings.arguments as Schedule;
          return RecordPage(schedule: schedule);
        },
        '/stats': (context) => const StatsPage(),
        '/about': (context) => const AboutPage(),
        '/about/developer_info': (context) => const DeveloperInfoPage(),
      },
    );
  }
}
