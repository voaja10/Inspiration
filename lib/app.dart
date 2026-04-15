import 'package:flutter/material.dart';

import 'screens/sessions_list_screen.dart';
import 'utils/strings.dart';

class PurchaseSessionApp extends StatelessWidget {
  const PurchaseSessionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 2,
          centerTitle: false,
        ),
      ),
      home: const SessionsListScreen(),
    );
  }
}
