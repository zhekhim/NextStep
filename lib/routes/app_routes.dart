import 'package:flutter/material.dart';

import '../auth/screens/register_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String register = '/register';

  static Map<String, WidgetBuilder> get routes => {
    register: (_) => const RegisterScreen(),
  };
}
