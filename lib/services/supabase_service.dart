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

  // Autenticação
  static Future<AuthResponse> signUp(String email, String password, String name) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // Create profile after successful signup
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

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return AppUser.fromJson({
        ...response,
        'email': user.email ?? '',
      });
    } catch (e) {
      throw Exception('Erro ao carregar perfil: ${e.toString()}');
    }
  }

  // Mensagens
  static Future<List<Message>> getMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await _client
          .from('messages')
          .select('*, favorites!left(user_id)')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).map((json) {
        final favorites = json['favorites'] as List?;
        final isFavorite = favorites?.any((fav) => fav['user_id'] == user.id) ?? false;
        
        return Message.fromJson({
          ...json,
          'is_favorite': isFavorite,
        });
      }).toList();
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

      final profile = await getCurrentUserProfile();
      final senderName = profile?.name ?? 'Usuário';

      await _client.from('messages').insert({
        'content': content,
        'sender_id': user.id,
        'sender_name': senderName,
        'image_url': imageUrl,
      });
    } catch (e) {
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('SocketException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  // Stream de mensagens em tempo real
  static Stream<List<Message>> getMessagesStream() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .asyncMap((data) async {
          final messageIds = data.map((msg) => msg['id']).toList();
          
          final favorites = await _client
              .from('favorites')
              .select('message_id')
              .eq('user_id', user.id)
              .inFilter('message_id', messageIds);
          
          final favoriteIds = (favorites as List)
              .map((fav) => fav['message_id'])
              .toSet();
          
          return data.map((json) {
            return Message.fromJson({
              ...json,
              'is_favorite': favoriteIds.contains(json['id']),
            });
          }).toList();
        });
  }

  static Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para atualizar o perfil.');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: ${e.toString()}');
    }
  }

  // Favoritos
  static Future<void> toggleFavorite(String messageId, bool isFavorite) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      if (isFavorite) {
        await _client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('message_id', messageId);
      } else {
        await _client.from('favorites').insert({
          'user_id': user.id,
          'message_id': messageId,
        });
      }
    } catch (e) {
      throw Exception('Erro ao favoritar mensagem: ${e.toString()}');
    }
  }

  static Future<List<Message>> getFavoriteMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('message_id, messages(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final messageData = json['messages'];
        return Message.fromJson({
          ...messageData,
          'is_favorite': true,
        });
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar favoritos: ${e.toString()}');
    }
  }

  // Arquivados
  static Future<void> toggleArchived(String messageId, bool isArchived) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      if (isArchived) {
        await _client
            .from('archived')
            .delete()
            .eq('user_id', user.id)
            .eq('message_id', messageId);
      } else {
        await _client.from('archived').insert({
          'user_id': user.id,
          'message_id': messageId,
        });
      }
    } catch (e) {
      throw Exception('Erro ao arquivar mensagem: ${e.toString()}');
    }
  }

  static Future<List<Message>> getArchivedMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await _client
          .from('archived')
          .select('message_id, messages(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final messageData = json['messages'];
        return Message.fromJson({
          ...messageData,
          'is_archived': true,
        });
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar arquivados: ${e.toString()}');
    }
  }
}
