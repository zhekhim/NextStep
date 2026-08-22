import 'package:flutter/material.dart';

import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';
import '../navigation/main_navigation_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String mainNavigation = '/main';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    mainNavigation: (_) => const MainNavigationScreen(),
  };
}
