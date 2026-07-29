import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'screens/role_select_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: IjishoApp()));
}

class IjishoApp extends StatelessWidget {
  const IjishoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IJISHO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.base,
      home: const RoleSelectScreen(),
    );
  }
}
