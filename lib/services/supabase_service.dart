import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Sistema de conversas individuais
  static final Map<String, List<Message>> _conversations = {};
  static final StreamController<Map<String, List<Message>>> _conversationsController = StreamController<Map<String, List<Message>>>.broadcast();

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

      // Se o usuário foi criado mas precisa confirmar email
      if (response.user != null && response.session == null) {
        // Criar perfil mesmo sem sessão ativa
        try {
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'name': name,
          });
        } catch (e) {
          // Ignorar erro se o perfil já existe
          print('Perfil já existe ou erro ao criar: $e');
        }
        
        // Lançar exceção especial para confirmação de email
        throw Exception('CONFIRM_EMAIL');
      }

      // Se chegou aqui, o usuário foi criado e já está logado
      if (response.user != null) {
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'name': name,
        });
      }

      return response;
    } catch (e) {
      if (e.toString().contains('CONFIRM_EMAIL')) {
        throw Exception('CONFIRM_EMAIL');
      }
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
      // Limpar conversas ao sair
      _conversations.clear();
      _conversationsController.add({});
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

      // Retornar lista vazia - mensagens serão carregadas via stream
      return [];
    } catch (e) {
      throw Exception('Erro ao carregar mensagens: ${e.toString()}');
    }
  }

  static Future<void> sendMessage(String content, String recipientId, {String? imageUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para enviar mensagens.');
      }

      final senderName = user.userMetadata?['name'] ?? 'Usuário';
      
      // Criar nova mensagem
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        senderId: user.id,
        senderName: senderName,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        isFavorite: false,
        isArchived: false,
      );
      
      // Adicionar à conversa específica
      if (!_conversations.containsKey(recipientId)) {
        _conversations[recipientId] = [];
      }
      _conversations[recipientId]!.insert(0, newMessage);
      
      // Notificar o stream
      _conversationsController.add(Map.from(_conversations));
      
      // Simular delay de rede
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('Mensagem enviada: $content por $senderName para $recipientId');
    } catch (e) {
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('SocketException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  static Stream<List<Message>> getMessagesStream(String recipientId) {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    // Se não há mensagens para este usuário, adicionar algumas de exemplo
    if (!_conversations.containsKey(recipientId) || _conversations[recipientId]!.isEmpty) {
      _addSampleMessages(recipientId);
    }

    // Retornar stream das mensagens desta conversa
    return _conversationsController.stream.map((conversations) => 
      conversations[recipientId] ?? []);
  }

  static void _addSampleMessages(String recipientId) {
    final user = currentUser;
    if (user == null) return;

    // Adicionar algumas mensagens de exemplo para esta conversa
    final sampleMessages = [
      Message(
        id: 'sample_1_$recipientId',
        content: 'Olá! Como você está?',
        senderId: recipientId,
        senderName: _getUserNameById(recipientId),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isFavorite: false,
        isArchived: false,
      ),
      Message(
        id: 'sample_2_$recipientId',
        content: 'Oi! Estou bem, obrigado! E você?',
        senderId: user.id,
        senderName: user.userMetadata?['name'] ?? 'Usuário',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        isFavorite: false,
        isArchived: false,
      ),
      Message(
        id: 'sample_3_$recipientId',
        content: 'Também estou bem! Que bom te ver por aqui 😊',
        senderId: recipientId,
        senderName: _getUserNameById(recipientId),
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        isFavorite: false,
        isArchived: false,
      ),
    ];

    _conversations[recipientId] = sampleMessages;
  }

  static String _getUserNameById(String userId) {
    // Mapear IDs para nomes (em produção viria do banco)
    switch (userId) {
      case 'maria_oliveira':
        return 'Maria Oliveira';
      case 'ana_silva':
        return 'Ana Silva';
      case 'carlos_santos':
        return 'Carlos Santos';
      case 'joao_costa':
        return 'João Costa';
      case 'pedro_lima':
        return 'Pedro Lima';
      default:
        return 'Usuário';
    }
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
