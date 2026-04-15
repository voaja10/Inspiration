import 'package:flutter/material.dart';

import 'screens/sessions_list_screen.dart';

class PurchaseSessionApp extends StatelessWidget {
  const PurchaseSessionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purchase Session Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SessionsListScreen(),
    );
  }
}
