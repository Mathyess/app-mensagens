import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'routes.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SupabaseConfig.printConfig();
  
  try {
    try {
      await Supabase.instance.dispose();
    } catch (e) {
    }
    
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase inicializado com sucesso!');
    
    final client = Supabase.instance.client;
    print('🔍 Testando conexão...');
    final response = await client.from('profiles').select('count').limit(1);
    print('✅ Conexão testada com sucesso!');
    
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        print('🌐 Conexão restaurada, sincronizando mensagens pendentes...');
        SupabaseService.syncPendingMessages();
      }
    });
    
  } catch (e) {
    print('❌ Erro ao inicializar Supabase: $e');
    print('🔍 Detalhes do erro: ${e.toString()}');
    rethrow;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Inter',
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6366F1), 
          secondary: const Color(0xFF8B5CF6), 
          tertiary: const Color(0xFF06B6D4), 
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
