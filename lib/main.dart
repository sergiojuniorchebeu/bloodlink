import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projetdonsanguin/screens/user/auth/login_page.dart';
import 'package:projetdonsanguin/screens/user/auth/sign_up.dart';
import 'package:projetdonsanguin/screens/user/home/home.dart';
import 'package:projetdonsanguin/screens/user/landing_page.dart';
import 'package:projetdonsanguin/services/auth/authservices.dart';

import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BloodLinkApp());
}

class BloodLinkApp extends StatelessWidget {
  const BloodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BloodLink',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F7F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
      home: const LandingPage(), // ✅ Démarre sur la Landing
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const _AuthGate(), // AuthGate redirige vers HomeShell ou Login
      },
    );
  }
}

/// Vérifie l’auth puis charge le profil Firestore pour passer isVerified + role à HomeShell.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = snap.data;
        if (user == null) {
          return const LoginPage();
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: UserService.I.getProfile(user.uid),
          builder: (context, profSnap) {
            if (profSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final data = profSnap.data ?? {};
            final isVerified = (data['isVerified'] ?? false) as bool;
            final role = (data['role'] ?? 'donneur') as String;
            return HomeShell(isVerified: isVerified, role: role);
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
