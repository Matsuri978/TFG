import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arceituna/services/services.dart';
import 'package:arceituna/screens/screens.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


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
      title: 'ARceituna',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      home: AuthService.instance.currentUser == null ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}