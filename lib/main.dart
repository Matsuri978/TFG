import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tfg/services/services.dart';
import 'package:tfg/screens/screens.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: 'https://ujuauhkkztdrjpkxqwfx.supabase.co',
    anonKey: 'sb_publishable_gXo6WkuD8zDW1vlGh2YTog_xdyWspXJ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TFG Olivar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: AuthService.instance.currentUser == null ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}