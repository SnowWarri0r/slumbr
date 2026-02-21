import 'package:flutter/material.dart';
import 'home_page.dart';

void main() => runApp(const EarSaviorApp());

class EarSaviorApp extends StatelessWidget {
  const EarSaviorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slumbr',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.teal.shade300),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
