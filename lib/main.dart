import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const CampusGuardApp());
}

class CampusGuardApp extends StatelessWidget {
  const CampusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: const HomeScreen(),
    );
  }
}