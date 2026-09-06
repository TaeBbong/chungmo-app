import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Lets pages observe their own route transitions (RouteAware); the home
/// screen uses it to drop text-field focus when another page covers it, so
/// coming back never re-summons the keyboard.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
