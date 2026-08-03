import 'package:flutter/material.dart';

import 'demo_catalog.dart';
import 'theme.dart';

void main() {
  runApp(const HitExampleApp());
}

class HitExampleApp extends StatelessWidget {
  const HitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hit examples',
      debugShowCheckedModeBanner: false,
      theme: HitExampleTheme.light(),
      home: const DemoCatalogPage(),
    );
  }
}
