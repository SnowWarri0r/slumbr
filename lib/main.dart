import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home_page.dart';

void main() => runApp(const SlumbrApp());

class SlumbrApp extends StatelessWidget {
  const SlumbrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slumbr',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.teal.shade300),
      ),
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
