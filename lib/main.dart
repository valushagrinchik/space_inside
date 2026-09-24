import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF52665A),
      secondary: Color(0xFFA8B5A5),
      surface: Color(0xFFF5F2EA),
      onSurface: Color(0xFF292B28),
    );
    final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    return MaterialApp(
      title: 'Space Inside',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontFamily: 'Inter'),
      ),
      home: const HomeScreen(),
    );
  }
}
