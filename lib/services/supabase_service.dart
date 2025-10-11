import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String _getAuthErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '429':
          return 'Por motivos de segurança, aguarde 45 segundos antes de tentar novamente.';
        case '400':
          if (error.message.contains('Invalid login credentials')) {
            return 'Email ou senha incorretos.';
          }
          if (error.message.contains('User already registered')) {
            return 'Este email já está cadastrado.';
          }
          if (error.message.contains('Password should be at least')) {
            return 'A senha deve ter pelo menos 6 caracteres.';
          }
          return 'Dados inválidos. Verifique suas informações.';
        case '422':
          return 'Email inválido. Por favor, use um email válido.';
        default:
          return error.message;
      }
    }
    
    if (error.toString().contains('over_email_send_rate_limit')) {
      return 'Por motivos de segurança, aguarde 45 segundos antes de tentar novamente.';
    }
    
    if (error.toString().contains('NetworkException') || 
        error.toString().contains('SocketException')) {
      return 'Erro de conexão. Verifique sua internet.';
    }
    
    return 'Ocorreu um erro. Tente novamente.';
  }

  static Future<AuthResponse> signUp(String email, String password, String name) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

  
      if (response.user != null) {
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'name': name,
        });
      }

      return response;
    } catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Erro ao sair: ${e.toString()}');
    }
  }

  static User? get currentUser => _client.auth.currentUser;

  static Future<AppUser?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      // Criar um perfil simples baseado nos dados do usuário autenticado
      return AppUser.fromJson({
        'id': user.id,
        'email': user.email ?? '',
        'name': user.userMetadata?['name'] ?? 'Usuário',
        'created_at': user.createdAt ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erro ao carregar perfil: ${e.toString()}');
    }
  }

  static Future<List<Message>> getMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // Retornar mensagens mockadas para demonstração
      return [
        Message(
          id: '1',
          content: 'Olá! Bem-vindo ao Connect!',
          senderId: 'system',
          senderName: 'Sistema',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isFavorite: false,
          isArchived: false,
        ),
        Message(
          id: '2',
          content: 'Este é um app de mensagens minimalista',
          senderId: 'system',
          senderName: 'Sistema',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isFavorite: false,
          isArchived: false,
        ),
      ];
    } catch (e) {
      throw Exception('Erro ao carregar mensagens: ${e.toString()}');
    }
  }

  static Future<void> sendMessage(String content, {String? imageUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para enviar mensagens.');
      }

      // Simular envio de mensagem (em produção, salvaria no Supabase)
      final senderName = user.userMetadata?['name'] ?? 'Usuário';
      
      // Para demonstração, apenas simular sucesso
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('Mensagem enviada: $content por $senderName');
    } catch (e) {
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('SocketException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  static Stream<List<Message>> getMessagesStream() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    // Retornar stream de mensagens mockadas para demonstração
    return Stream.value([
      Message(
        id: '1',
        content: 'Olá! Bem-vindo ao Connect!',
        senderId: 'system',
        senderName: 'Sistema',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isFavorite: false,
        isArchived: false,
      ),
      Message(
        id: '2',
        content: 'Este é um app de mensagens minimalista',
        senderId: 'system',
        senderName: 'Sistema',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isFavorite: false,
        isArchived: false,
      ),
    ]);
  }

  static Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para atualizar o perfil.');
      }

      // Simular atualização de perfil (em produção, atualizaria no Supabase)
      if (name != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'name': name}),
        );
      }
      
      print('Perfil atualizado: $name');
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: ${e.toString()}');
    }
  }

  static Future<void> toggleFavorite(String messageId, bool isFavorite) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      // Simular favoritar mensagem (em produção, salvaria no Supabase)
      print('Mensagem ${isFavorite ? 'desfavoritada' : 'favoritada'}: $messageId');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      throw Exception('Erro ao favoritar mensagem: ${e.toString()}');
    }
  }

  static Future<List<Message>> getFavoriteMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // Retornar lista vazia para demonstração
      return [];
    } catch (e) {
      throw Exception('Erro ao carregar favoritos: ${e.toString()}');
    }
  }

  static Future<void> toggleArchived(String messageId, bool isArchived) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      // Simular arquivar mensagem (em produção, salvaria no Supabase)
      print('Mensagem ${isArchived ? 'desarquivada' : 'arquivada'}: $messageId');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      throw Exception('Erro ao arquivar mensagem: ${e.toString()}');
    }
  }

  static Future<List<Message>> getArchivedMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // Retornar lista vazia para demonstração
      return [];
    } catch (e) {
      throw Exception('Erro ao carregar arquivados: ${e.toString()}');
    }
  }
}
