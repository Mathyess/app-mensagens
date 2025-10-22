import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';
import 'config/supabase_config.dart';
import 'theme/matrix_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Usar configuração centralizada
  SupabaseConfig.printConfig();
  
  try {
    // Limpar qualquer instância anterior
    try {
      await Supabase.instance.dispose();
    } catch (e) {
      // Ignorar erro se não houver instância
    }
    
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase inicializado com sucesso!');
    
    // Testar conexão
    final client = Supabase.instance.client;
    print('🔍 Testando conexão...');
    final response = await client.from('profiles').select('count').limit(1);
    print('✅ Conexão testada com sucesso!');
    
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
      title: '> MATRIX_CHAT_',
      debugShowCheckedModeBanner: false,
      theme: MatrixTheme.darkTheme,
      darkTheme: MatrixTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: AppRoutes.getInitialRoute(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
