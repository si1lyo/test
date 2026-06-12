import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_page.dart';
import 'onboarding_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(MyApp(savedThemeMode: savedThemeMode, onboardingDone: onboardingDone));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  final bool onboardingDone;
  const MyApp({super.key, this.savedThemeMode, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      // ライトモードの設定
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF428475),
        fontFamily: 'NotoSansJP',
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF428475),
        fontFamily: 'NotoSansJP',
        scaffoldBackgroundColor: const Color(0xFF1B1D1C),
        cardColor: const Color(0xFF262928),
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      
      // ここで全体の見た目を一気に変える指示を出す
      builder: (theme, darkTheme) => MaterialApp(
        title: 'まだある？',
        debugShowCheckedModeBanner: false,
        theme: theme,      // builderから渡されたテーマを適用
        darkTheme: darkTheme, // builderから渡されたダークテーマを適用
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return const MainScreen();
            }
            if (!onboardingDone) {
              return const OnboardingPage();
            }
            return const AuthPage();
          },
        ),
      ),
    );
  }
}