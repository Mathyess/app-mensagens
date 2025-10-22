import 'dart:async';
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

      print('📤 Enviando mensagem para: $recipientId');

      // Criar ou obter conversa direta
      final conversationId = await _client.rpc('create_direct_conversation', params: {
        'user1_id': user.id,
        'user2_id': recipientId
      });

      print('💬 Conversa ID: $conversationId');

      // Inserir mensagem no banco
      final response = await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': content,
        'message_type': imageUrl != null ? 'image' : 'text',
        'file_url': imageUrl,
      }).select().single();

      print('✅ Mensagem enviada: ${response['id']}');
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('SocketException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  static Stream<List<Message>> getMessagesStream(String recipientId) async* {
    final user = currentUser;
    if (user == null) {
      print('❌ Usuário não autenticado');
      yield [];
      return;
    }

    // Validar recipientId
    if (recipientId.isEmpty) {
      print('❌ recipientId está vazio');
      yield [];
      return;
    }

    try {
      print('📤 Buscando conversa com: $recipientId');
      
      // Criar ou obter conversa direta
      final conversationId = await _client.rpc('create_direct_conversation', params: {
        'user1_id': user.id,
        'user2_id': recipientId
      });

      print('📱 Conversation ID: $conversationId');

      // Buscar nome do remetente para cada mensagem
      final profiles = <String, String>{};
      
      // Buscar mensagens do banco de dados com realtime
      await for (final data in _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)) {
        
        final messages = <Message>[];
        
        for (final msg in data) {
          final senderId = msg['sender_id'];
          
          // Cache de perfis para evitar múltiplas consultas
          if (!profiles.containsKey(senderId)) {
            try {
              final profile = await _client
                  .from('profiles')
                  .select('name')
                  .eq('id', senderId)
                  .single();
              profiles[senderId] = profile['name'] ?? 'Usuário';
            } catch (e) {
              profiles[senderId] = 'Usuário';
            }
          }
          
          messages.add(Message(
            id: msg['id'],
            content: msg['content'] ?? '',
            senderId: senderId,
            senderName: profiles[senderId] ?? 'Usuário',
            createdAt: DateTime.parse(msg['created_at']),
            imageUrl: msg['file_url'],
            isFavorite: false,
            isArchived: false,
          ));
        }
        
        yield messages;
      }
    } catch (e) {
      print('❌ Erro no stream de mensagens: $e');
      yield [];
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

  // Buscar todos os usuários cadastrados (exceto o usuário atual)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await _client
          .from('profiles')
          .select('id, name, email, avatar_url, is_online, last_seen, created_at')
          .neq('id', user.id)
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      // Em caso de erro, retornar lista vazia em vez de lançar exceção
      return [];
    }
  }

  // Buscar usuários por nome ou email
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final user = currentUser;
      if (user == null) return [];

      if (query.isEmpty) {
        return await getAllUsers();
      }

      final response = await _client
          .from('profiles')
          .select('id, name, email, avatar_url, is_online, last_seen, created_at')
          .neq('id', user.id)
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      // Em caso de erro, retornar lista vazia em vez de lançar exceção
      return [];
    }
  }

  // Buscar conversas do usuário atual
  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ Usuário não autenticado');
        return [];
      }

      print('🔍 Buscando conversas para usuário: ${user.id}');

      // Buscar conversas usando JOIN
      final result = await _client
          .from('conversation_participants')
          .select('''
            conversation_id,
            conversations!inner(id, name, type, created_at)
          ''')
          .eq('user_id', user.id)
          .filter('left_at', 'is', null);

      print('✅ Conversas encontradas: ${result.length}');

      if (result.isEmpty) {
        return [];
      }

      // Transformar em formato esperado
      final conversations = <Map<String, dynamic>>[];
      
      for (final item in result) {
        final conv = item['conversations'];
        String conversationName = conv['name'] ?? 'Conversa';
        String? otherUserId;
        
        // Para conversas diretas, SEMPRE buscar o outro participante
        if (conv['type'] == 'direct') {
          try {
            final otherParticipants = await _client
                .from('conversation_participants')
                .select('user_id, profiles!inner(name)')
                .eq('conversation_id', conv['id'])
                .neq('user_id', user.id)
                .limit(1);
            
            if (otherParticipants.isNotEmpty) {
              otherUserId = otherParticipants[0]['user_id'];
              // Usar o nome do outro participante se não houver nome na conversa
              if (conv['name'] == null || conv['name'].isEmpty) {
                conversationName = otherParticipants[0]['profiles']['name'];
              }
              print('👤 Outro usuário: $otherUserId - $conversationName');
            }
          } catch (e) {
            print('❌ Erro ao buscar nome do participante: $e');
          }
        }
        
        // Buscar última mensagem
        String lastMessage = 'Nova conversa';
        String lastMessageTime = _formatTime(DateTime.parse(conv['created_at']));
        
        try {
          final messages = await _client
              .from('messages')
              .select('content, created_at')
              .eq('conversation_id', conv['id'])
              .order('created_at', ascending: false)
              .limit(1);
          
          if (messages.isNotEmpty) {
            lastMessage = messages[0]['content'] ?? 'Nova conversa';
            lastMessageTime = _formatTime(DateTime.parse(messages[0]['created_at']));
          }
        } catch (e) {
          print('Erro ao buscar última mensagem: $e');
        }
        
        conversations.add({
          'id': conv['id'],
          'name': conversationName,
          'lastMessage': lastMessage,
          'time': lastMessageTime,
          'avatarUrl': null,
          'hasUnread': false,
          'unreadCount': 0,
          'otherUserId': otherUserId, // Adicionar ID do outro usuário
        });
      }
      
      return conversations;
    } catch (e) {
      print('❌ Erro ao carregar conversas: $e');
      return [];
    }
  }

  static String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Agora';
    }
  }

  // Buscar outros participantes de uma conversa
  static Future<List<Map<String, dynamic>>> getOtherParticipants(
      String conversationId, String currentUserId) async {
    try {
      final response = await _client
          .from('conversation_participants')
          .select('user_id, profiles!inner(id, name, email)')
          .eq('conversation_id', conversationId)
          .neq('user_id', currentUserId)
          .filter('left_at', 'is', null);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar participantes: $e');
      return [];
    }
  }

  // Remover conversa do histórico
  static Future<void> removeConversation(String conversationId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Marcar como saído da conversa
      await _client
          .from('conversation_participants')
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', user.id);
      
      print('Conversa removida: $conversationId');
    } catch (e) {
      throw Exception('Erro ao remover conversa: ${e.toString()}');
    }
  }
}
