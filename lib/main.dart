import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String supabaseUrl = 'https://dfwyrovkjvtvrbncwrmi.supabase.co';
  String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmd3lyb3ZranZ0dnJibmN3cm1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MTQyNDYsImV4cCI6MjA3NTI5MDI0Nn0.vVF7fc7IUhPg9co2VOCwQrCQCgXhum1-dBr2PoJifkg';
  
  // Try to load .env file only if not on web
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;
    } catch (e) {
      print('Could not load .env file: $e');
    }
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Mensagens',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Inter',
        primaryColor: const Color(0xFF6366F1), // Índigo suave
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6366F1), // Índigo suave
          secondary: const Color(0xFF8B5CF6), // Roxo suave
          tertiary: const Color(0xFF06B6D4), // Ciano suave
          surface: Colors.white,
          background: const Color(0xFFFAFAFA),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF1F2937),
          onBackground: const Color(0xFF374151),
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE5E7EB),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
          headlineMedium: TextStyle(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          titleMedium: TextStyle(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          labelMedium: TextStyle(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
      home: AppRoutes.getInitialRoute(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
