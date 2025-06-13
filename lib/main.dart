import 'package:flutter/material.dart';
import 'screens/text_fixer_home_screen.dart';

void main() {
  runApp(TextFixerApp());
}

class TextFixerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextFixer',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Roboto',
      ),
      home: TextFixerHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
