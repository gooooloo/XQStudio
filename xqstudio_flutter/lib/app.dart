import 'package:flutter/material.dart';
import 'package:xqstudio/ui/home/home_screen.dart';

class XQStudioApp extends StatelessWidget {
  const XQStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XQStudio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
