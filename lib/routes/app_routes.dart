import 'package:flutter/material.dart';

import '../auth/screens/login_screen.dart';
import '../auth/screens/register_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
  };
}
