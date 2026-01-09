/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/main.dart
 * Description: Entry point of the Open Battery Flutter application. Initializes the app with providers and sets up the main material app.
 * Author: Shishir Dey
 * License: MIT
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bms_provider.dart';
import 'ui/theme.dart';
import 'ui/screens/splash_screen.dart';

void main() {
  runApp(const OpenBattery());
}

class OpenBattery extends StatelessWidget {
  const OpenBattery({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BmsProvider())],
      child: MaterialApp(
        title: 'Open Battery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
