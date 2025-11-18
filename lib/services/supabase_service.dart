import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'local_storage_service.dart';

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

  static Future<AuthResponse> signUp(
      String email, String password, String name) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      Future<void> saveProfile() async {
        final user = response.user;
        if (user == null) return;

        final profileData = {
          'id': user.id,
          'name': name,
          'email': user.email,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await _client
              .from('profiles')
              .upsert(profileData, onConflict: 'id', ignoreDuplicates: false);
        } catch (e) {
          print('Erro ao salvar perfil após signup: $e');
          rethrow;
        }
      }

      if (response.user != null && response.session == null) {
        await saveProfile();
        throw Exception('CONFIRM_EMAIL');
      }

      if (response.user != null) {
        await saveProfile();
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

      try {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        final String? userCreatedAtRaw = user.createdAt;
        final userCreatedAt =
            userCreatedAtRaw ?? DateTime.now().toIso8601String();
        return AppUser.fromJson({
          'id': profile['id'],
          'email': profile['email'] ?? user.email ?? '',
          'name': profile['name'] ?? (user.userMetadata?['name'] ?? 'Usuário'),
          'avatar_url': profile['avatar_url'],
          'created_at': profile['created_at'] ?? userCreatedAt,
        });
      } catch (e) {
        final String? userCreatedAtRaw = user.createdAt;
        final userCreatedAt =
            userCreatedAtRaw ?? DateTime.now().toIso8601String();
        return AppUser.fromJson({
          'id': user.id,
          'email': user.email ?? '',
          'name': user.userMetadata?['name'] ?? 'Usuário',
          'created_at': userCreatedAt,
        });
      }
    } catch (e) {
      print('Erro ao carregar perfil: $e');
      return null;
    }
  }

  static Future<List<Message>> getMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      return [];
    } catch (e) {
      throw Exception('Erro ao carregar mensagens: ${e.toString()}');
    }
  }

  static Future<String> uploadFile(String filePath, String fileName) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para fazer upload.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '$timestamp-$fileName';
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      String folder = 'files';
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
        folder = 'images';
      }

      Uint8List fileBytes;
      
      final xfile = XFile(filePath);
      fileBytes = await xfile.readAsBytes();
      
      final fileSizeInMB = fileBytes.length / (1024 * 1024);
      if (fileSizeInMB > 20) {
        throw Exception('Arquivo muito grande. Tamanho máximo: 20MB');
      }
      
      await _client.storage
          .from('messages')
          .uploadBinary(
            '$folder/$uniqueFileName',
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExtension),
              upsert: false,
            ),
          );

      final publicUrl = _client.storage
          .from('messages')
          .getPublicUrl('$folder/$uniqueFileName');

      print('✅ Arquivo enviado: $publicUrl');
      print('📝 Tipo da URL: ${publicUrl.runtimeType}');
      
      // Garantir que retornamos uma string
      final urlString = publicUrl.toString();
      print('🔗 URL final: $urlString');
      
      return urlString;
    } catch (e) {
      print('❌ Erro ao fazer upload: $e');
      if (e.toString().contains('already exists')) {
        throw Exception('Arquivo já existe. Tente novamente.');
      }
      if (e.toString().contains('Platform._operatingSystem')) {
        throw Exception('Erro: Este recurso não está disponível na web. Use uma imagem selecionada da galeria.');
      }
      throw Exception('Erro ao fazer upload: ${e.toString()}');
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<void> sendMessage(String content, String recipientId, {String? imageUrl, String? fileUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para enviar mensagens.');
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      print('📤 Enviando mensagem para: $recipientId (Online: $isOnline)');

      String messageType = 'text';
      String? fileUrlToUse;
      if (imageUrl != null) {
        messageType = 'image';
        fileUrlToUse = imageUrl;
      } else if (fileUrl != null) {
        messageType = 'file';
        fileUrlToUse = fileUrl;
      }

      String conversationId;
      
      if (isOnline) {
        conversationId = await _client.rpc('create_direct_conversation', params: {
          'user1_id': user.id,
          'user2_id': recipientId
        });

        print('💬 Conversa ID: $conversationId');

        final response = await _client.from('messages').insert({
          'conversation_id': conversationId,
          'sender_id': user.id,
          'content': content.isEmpty ? (imageUrl != null ? '📷 Imagem' : fileUrl != null ? '📎 Arquivo' : '') : content,
          'message_type': messageType,
          'file_url': fileUrlToUse,
        }).select().single();

        print('✅ Mensagem enviada: ${response['id']}');
      } else {
        conversationId = 'temp_${user.id}_$recipientId';
        
        await LocalStorageService.savePendingMessage(
          conversationId: conversationId,
          content: content.isEmpty ? (imageUrl != null ? '📷 Imagem' : fileUrl != null ? '📎 Arquivo' : '') : content,
          fileUrl: fileUrlToUse,
          messageType: messageType,
          isGroup: false,
        );
        print('💾 Mensagem salva localmente para envio posterior');
      }
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('SocketException')) {
        try {
          final user = currentUser;
          if (user != null) {
            final conversationId = 'temp_${user.id}_$recipientId';
            
            String messageType = 'text';
            String? fileUrlToUse;
            if (imageUrl != null) {
              messageType = 'image';
              fileUrlToUse = imageUrl;
            } else if (fileUrl != null) {
              messageType = 'file';
              fileUrlToUse = fileUrl;
            }

            await LocalStorageService.savePendingMessage(
              conversationId: conversationId,
              content: content.isEmpty ? (imageUrl != null ? '📷 Imagem' : fileUrl != null ? '📎 Arquivo' : '') : content,
              fileUrl: fileUrlToUse,
              messageType: messageType,
              isGroup: false,
            );
          }
        } catch (_) {}
        throw Exception('Erro de conexão. Mensagem será enviada quando a conexão for restaurada.');
      }
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  static Future<void> syncPendingMessages() async {
    try {
      final pending = await LocalStorageService.getPendingMessages();
      if (pending.isEmpty) return;

      final user = currentUser;
      if (user == null) return;

      for (final pendingMsg in pending) {
        try {
          final conversationId = pendingMsg['conversation_id'] as String;
          
          if (pendingMsg['is_group'] == 1) {
            await sendGroupMessage(
              conversationId,
              pendingMsg['content'] as String,
              imageUrl: pendingMsg['file_url'] as String?,
              fileUrl: pendingMsg['file_url'] as String?,
            );
          } else {
            String actualConversationId = conversationId;
            
            if (conversationId.startsWith('temp_')) {
              final parts = conversationId.split('_');
              if (parts.length >= 3) {
                final recipientId = parts[2];
                actualConversationId = await _client.rpc('create_direct_conversation', params: {
                  'user1_id': user.id,
                  'user2_id': recipientId
                });
              }
            }
            
            await _client.from('messages').insert({
              'conversation_id': actualConversationId,
              'sender_id': user.id,
              'content': pendingMsg['content'],
              'message_type': pendingMsg['message_type'],
              'file_url': pendingMsg['file_url'],
            });
          }
          
          await LocalStorageService.removePendingMessage(pendingMsg['id'] as String);
        } catch (e) {
          print('Erro ao sincronizar mensagem pendente: $e');
        }
      }
    } catch (e) {
      print('Erro ao sincronizar mensagens pendentes: $e');
    }
  }

  static Stream<List<Message>> getMessagesStream(String recipientId) async* {
    final user = currentUser;
    if (user == null) {
      print('❌ Usuário não autenticado');
      yield [];
      return;
    }

    if (recipientId.isEmpty) {
      print('❌ recipientId está vazio');
      yield [];
      return;
    }

    try {
      print('📤 Buscando conversa com: $recipientId');
      
      final conversationId = await _client.rpc('create_direct_conversation', params: {
        'user1_id': user.id,
        'user2_id': recipientId
      });

      print('📱 Conversation ID: $conversationId');

      try {
        final cachedMessages = await LocalStorageService.getCachedMessages(conversationId);
        if (cachedMessages.isNotEmpty) {
          yield cachedMessages;
        }
      } catch (e) {
        print('Erro ao carregar cache: $e');
      }

      final profiles = <String, String>{};
      
      List<Message> processMessages(List<dynamic> data) {
        final messages = <Message>[];
        
        for (final msg in data) {
          final senderId = msg['sender_id'];
          
          Map<String, List<String>>? reactions;
          if (msg['reactions'] != null && msg['reactions'] is Map) {
            reactions = Map<String, List<String>>.from(
              (msg['reactions'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value ?? []),
                ),
              ),
            );
          }

          final createdAtUtc = DateTime.parse(msg['created_at']);
          final createdAt = createdAtUtc.isUtc 
              ? createdAtUtc.toLocal() 
              : createdAtUtc;
          
          DateTime? editedAt;
          if (msg['edited_at'] != null) {
            final editedAtUtc = DateTime.parse(msg['edited_at']);
            editedAt = editedAtUtc.isUtc 
                ? editedAtUtc.toLocal() 
                : editedAtUtc;
          }
          
          messages.add(Message(
            id: msg['id'],
            content: msg['content'] ?? '',
            senderId: senderId,
            senderName: profiles[senderId] ?? 'Usuário',
            createdAt: createdAt,
            imageUrl: msg['file_url'],
            isFavorite: msg['is_favorite'] ?? false,
            isArchived: msg['is_archived'] ?? false,
            isDeleted: msg['is_deleted'] ?? false,
            isEdited: msg['is_edited'] ?? false,
            editedAt: editedAt,
            reactions: reactions,
          ));
        }
        return messages;
      }
      
      try {
        final initialMessages = await _client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);
        
        print('📥 Carregando ${initialMessages.length} mensagens existentes');
        
        final senderIds = initialMessages.map((m) => m['sender_id'] as String).toSet().toList();
        if (senderIds.isNotEmpty) {
          final profilesData = await _client
              .from('profiles')
              .select('id, name')
              .inFilter('id', senderIds);
          
          for (final profile in profilesData) {
            profiles[profile['id']] = profile['name'] ?? 'Usuário';
          }
        }
        
        final messages = processMessages(initialMessages);
        print('✅ Enviando ${messages.length} mensagens iniciais para o UI');
        
        try {
          await LocalStorageService.cacheMessages(conversationId, messages);
        } catch (e) {
          print('Erro ao salvar no cache: $e');
        }
        
        yield messages;
      } catch (e) {
        print('❌ Erro ao carregar mensagens iniciais: $e');
      }
      
      await for (final data in _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)) {
        
        print('📨 Recebido ${data.length} mensagens do stream');
        
        final senderIds = data.map((m) => m['sender_id'] as String).toSet().toList();
        final newSenderIds = senderIds.where((id) => !profiles.containsKey(id)).toList();
        
        if (newSenderIds.isNotEmpty) {
          try {
            final profilesData = await _client
                .from('profiles')
                .select('id, name')
                .inFilter('id', newSenderIds);
            
            for (final profile in profilesData) {
              profiles[profile['id']] = profile['name'] ?? 'Usuário';
            }
          } catch (e) {
            print('❌ Erro ao buscar perfis: $e');
            for (final id in newSenderIds) {
              profiles[id] = 'Usuário';
            }
          }
        }
        
        final messages = processMessages(data);
        print('✅ Enviando ${messages.length} mensagens do stream para o UI');
        
        try {
          await LocalStorageService.cacheMessages(conversationId, messages);
        } catch (e) {
          print('Erro ao atualizar cache: $e');
        }
        
        yield messages;
      }
    } catch (e) {
      print('❌ Erro no stream de mensagens: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      yield [];
    }
  }


  static Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para atualizar o perfil.');
      }

      if (name != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'name': name}),
        );
      }

      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      } else if (avatarUrl == null && name == null) {
        updateData['avatar_url'] = null;
      }
      
      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
        await _client
            .from('profiles')
            .update(updateData)
            .eq('id', user.id);
      }
      
      print('✅ Perfil atualizado: ${name ?? 'avatar'}');
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      throw Exception('Erro ao atualizar perfil: ${e.toString()}');
    }
  }

  static Future<void> toggleFavorite(String messageId, bool isFavorite) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      await _client
          .from('messages')
          .update({
            'is_favorite': !isFavorite,
          })
          .eq('id', messageId);

      print('Mensagem ${isFavorite ? 'desfavoritada' : 'favoritada'}: $messageId');
    } catch (e) {
      throw Exception('Erro ao favoritar mensagem: ${e.toString()}');
    }
  }

  static Future<List<Message>> getFavoriteMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      // Buscar mensagens favoritas do usuário (em conversas onde ele participa)
      // Primeiro, buscar IDs das conversas do usuário
      final userConversations = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', user.id)
          .filter('left_at', 'is', null);
      
      if (userConversations.isEmpty) return [];
      
      final conversationIds = userConversations
          .map((conv) => conv['conversation_id'] as String)
          .toList();

      final response = await _client
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey(name)
          ''')
          .eq('is_favorite', true)
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      final messages = <Message>[];
      
      for (final msg in response) {
        final senderName = msg['profiles'] != null && msg['profiles'] is Map
            ? (msg['profiles'] as Map)['name'] ?? 'Usuário'
            : 'Usuário';

        Map<String, List<String>>? reactions;
        if (msg['reactions'] != null && msg['reactions'] is Map) {
          reactions = Map<String, List<String>>.from(
            (msg['reactions'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                List<String>.from(value ?? []),
              ),
            ),
          );
        }

        messages.add(Message(
          id: msg['id'],
          content: msg['content'] ?? '',
          senderId: msg['sender_id'],
          senderName: senderName,
          createdAt: DateTime.parse(msg['created_at']),
          imageUrl: msg['file_url'],
          isFavorite: msg['is_favorite'] ?? false,
          isArchived: msg['is_archived'] ?? false,
          isDeleted: msg['is_deleted'] ?? false,
          isEdited: msg['is_edited'] ?? false,
          editedAt: msg['edited_at'] != null 
              ? DateTime.parse(msg['edited_at']) 
              : null,
          reactions: reactions,
        ));
      }

      return messages;
    } catch (e) {
      print('Erro ao carregar favoritos: $e');
      return [];
    }
  }

  static Future<void> toggleArchived(String messageId, bool isArchived) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      await _client
          .from('messages')
          .update({
            'is_archived': !isArchived,
          })
          .eq('id', messageId);

      print('Mensagem ${isArchived ? 'desarquivada' : 'arquivada'}: $messageId');
    } catch (e) {
      throw Exception('Erro ao arquivar mensagem: ${e.toString()}');
    }
  }

  static Future<List<Message>> getArchivedMessages() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final userConversations = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', user.id)
          .filter('left_at', 'is', null);
      
      if (userConversations.isEmpty) return [];
      
      final conversationIds = userConversations
          .map((conv) => conv['conversation_id'] as String)
          .toList();

      final response = await _client
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey(name)
          ''')
          .eq('is_archived', true)
          .inFilter('conversation_id', conversationIds)
          .order('created_at', ascending: false);

      final messages = <Message>[];
      
      for (final msg in response) {
        final senderName = msg['profiles'] != null && msg['profiles'] is Map
            ? (msg['profiles'] as Map)['name'] ?? 'Usuário'
            : 'Usuário';

        Map<String, List<String>>? reactions;
        if (msg['reactions'] != null && msg['reactions'] is Map) {
          reactions = Map<String, List<String>>.from(
            (msg['reactions'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                List<String>.from(value ?? []),
              ),
            ),
          );
        }

        messages.add(Message(
          id: msg['id'],
          content: msg['content'] ?? '',
          senderId: msg['sender_id'],
          senderName: senderName,
          createdAt: DateTime.parse(msg['created_at']),
          imageUrl: msg['file_url'],
          isFavorite: msg['is_favorite'] ?? false,
          isArchived: msg['is_archived'] ?? false,
          isDeleted: msg['is_deleted'] ?? false,
          isEdited: msg['is_edited'] ?? false,
          editedAt: msg['edited_at'] != null 
              ? DateTime.parse(msg['edited_at']) 
              : null,
          reactions: reactions,
        ));
      }

      return messages;
    } catch (e) {
      print('Erro ao carregar arquivados: $e');
      return [];
    }
  }

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
      return [];
    }
  }

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
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('❌ Usuário não autenticado');
        return [];
      }

      print('🔍 Buscando conversas para usuário: ${user.id}');

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

      final conversations = <Map<String, dynamic>>[];
      
      for (final item in result) {
        final conv = item['conversations'];
        String conversationName = conv['name'] ?? 'Conversa';
        String? otherUserId;
        String? avatarUrl;
        bool isOnline = false;
        
        if (conv['type'] == 'direct') {
          try {
            final otherParticipants = await _client
                .from('conversation_participants')
                .select('user_id, profiles!inner(name, avatar_url, is_online)')
                .eq('conversation_id', conv['id'])
                .neq('user_id', user.id)
                .limit(1);
            
            if (otherParticipants.isNotEmpty) {
              otherUserId = otherParticipants[0]['user_id'];
              final profile = otherParticipants[0]['profiles'];
              avatarUrl = profile['avatar_url'];
              isOnline = profile['is_online'] ?? false;
              
              conversationName = profile['name'] ?? 'Usuário';
              print('👤 Outro usuário: $otherUserId - $conversationName');
              print('🖼️ Avatar URL: $avatarUrl');
              print('🟢 Online: $isOnline');
            }
          } catch (e) {
            print('❌ Erro ao buscar nome do participante: $e');
          }
        }
        
        String lastMessage = 'Nova conversa';
        String lastMessageTime = _formatTime(DateTime.parse(conv['created_at']));
        DateTime? lastMessageDate;
        
        try {
          final messages = await _client
              .from('messages')
              .select('content, created_at')
              .eq('conversation_id', conv['id'])
              .order('created_at', ascending: false)
              .limit(1);
          
          if (messages.isNotEmpty) {
            lastMessage = messages[0]['content'] ?? 'Nova conversa';
            lastMessageDate = DateTime.parse(messages[0]['created_at']);
            lastMessageTime = _formatTime(lastMessageDate);
          } else {
            lastMessageDate = DateTime.parse(conv['created_at']);
          }
        } catch (e) {
          print('Erro ao buscar última mensagem: $e');
          lastMessageDate = DateTime.parse(conv['created_at']);
        }
        
        int unreadCount = 0;
        try {
          final result = await _client.rpc('count_unread_messages', params: {
            'p_conversation_id': conv['id'],
            'p_user_id': user.id,
          });
          unreadCount = result ?? 0;
          print('📬 Mensagens não lidas: $unreadCount');
        } catch (e) {
          print('⚠️ Erro ao contar mensagens não lidas (função pode não existir): $e');
          try {
            final messages = await _client
                .from('messages')
                .select('id')
                .eq('conversation_id', conv['id'])
                .neq('sender_id', user.id);
            
            int count = 0;
            for (final msg in messages) {
              final reads = await _client
                  .from('message_reads')
                  .select('id')
                  .eq('message_id', msg['id'])
                  .eq('user_id', user.id)
                  .maybeSingle();
              
              if (reads == null) count++;
            }
            unreadCount = count;
          } catch (e2) {
            print('⚠️ Erro no fallback de contagem: $e2');
          }
        }
        
        conversations.add({
          'id': conv['id'],
          'name': conversationName,
          'type': conv['type'] ?? 'direct',
          'lastMessage': lastMessage,
          'time': lastMessageTime,
          'lastMessageDate': lastMessageDate, // Adicionar data para ordenação
          'avatarUrl': avatarUrl,
          'isOnline': isOnline,
          'hasUnread': unreadCount > 0,
          'unreadCount': unreadCount,
          'otherUserId': otherUserId,
        });
      }
      
      // Ordenar conversas por data da última mensagem (mais recente primeiro)
      conversations.sort((a, b) {
        final dateA = a['lastMessageDate'] as DateTime?;
        final dateB = b['lastMessageDate'] as DateTime?;
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateB.compareTo(dateA); // Ordem decrescente (mais recente primeiro)
      });
      
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

  // Editar mensagem (até 15 minutos após envio)
  static Future<void> editMessage(String messageId, String newContent) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verificar se a mensagem pertence ao usuário
      final message = await _client
          .from('messages')
          .select('sender_id, created_at, is_deleted')
          .eq('id', messageId)
          .single();

      if (message['sender_id'] != user.id) {
        throw Exception('Você só pode editar suas próprias mensagens.');
      }

      if (message['is_deleted'] == true) {
        throw Exception('Não é possível editar uma mensagem deletada.');
      }

      // Verificar se passou 15 minutos
      final createdAt = DateTime.parse(message['created_at']);
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      if (difference.inMinutes > 15) {
        throw Exception('Não é possível editar mensagens após 15 minutos.');
      }

      // Atualizar mensagem
      await _client
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
            'edited_at': now.toIso8601String(),
          })
          .eq('id', messageId);

      print('✅ Mensagem editada: $messageId');
    } catch (e) {
      print('❌ Erro ao editar mensagem: $e');
      throw Exception('Erro ao editar mensagem: ${e.toString()}');
    }
  }

  // Deletar mensagem
  static Future<void> deleteMessage(String messageId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verificar se a mensagem pertence ao usuário
      final message = await _client
          .from('messages')
          .select('sender_id')
          .eq('id', messageId)
          .single();

      if (message['sender_id'] != user.id) {
        throw Exception('Você só pode deletar suas próprias mensagens.');
      }

      // Marcar como deletada (soft delete)
      await _client
          .from('messages')
          .update({
            'is_deleted': true,
            'content': 'Esta mensagem foi deletada',
          })
          .eq('id', messageId);

      print('✅ Mensagem deletada: $messageId');
    } catch (e) {
      print('❌ Erro ao deletar mensagem: $e');
      throw Exception('Erro ao deletar mensagem: ${e.toString()}');
    }
  }

  // Adicionar/remover reação a uma mensagem
  static Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar mensagem atual
      final message = await _client
          .from('messages')
          .select('reactions')
          .eq('id', messageId)
          .single();

      Map<String, List<String>> reactions = {};
      if (message['reactions'] != null && message['reactions'] is Map) {
        reactions = Map<String, List<String>>.from(
          (message['reactions'] as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              List<String>.from(value ?? []),
            ),
          ),
        );
      }

      // Adicionar ou remover reação
      if (reactions.containsKey(emoji)) {
        final userIds = reactions[emoji]!;
        if (userIds.contains(user.id)) {
          // Remover reação
          userIds.remove(user.id);
          if (userIds.isEmpty) {
            reactions.remove(emoji);
          }
        } else {
          // Adicionar reação
          userIds.add(user.id);
        }
      } else {
        // Adicionar nova reação
        reactions[emoji] = [user.id];
      }

      // Atualizar no banco
      await _client
          .from('messages')
          .update({'reactions': reactions})
          .eq('id', messageId);

      print('✅ Reação atualizada: $emoji');
    } catch (e) {
      print('❌ Erro ao atualizar reação: $e');
      throw Exception('Erro ao atualizar reação: ${e.toString()}');
    }
  }

  // Atualizar status online do usuário
  static Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _client
          .from('profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Status online é atualizado na tabela profiles e será refletido via Realtime stream
    } catch (e) {
      print('Erro ao atualizar status online: $e');
    }
  }

  // Stream de status online de um usuário
  static Stream<bool> getUserOnlineStatus(String userId) {
    try {
      return _client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .map((data) {
            if (data.isEmpty) return false;
            return data[0]['is_online'] ?? false;
          });
    } catch (e) {
      print('Erro ao obter status online: $e');
      return Stream.value(false);
    }
  }

  // Enviar indicador de "digitando" (usando uma tabela temporária ou Presence)
  // Nota: Para uma implementação completa, seria necessário criar uma tabela 'typing_indicators'
  // ou usar Presence do Realtime de forma mais elaborada
  static Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Usar uma tabela temporária para indicadores de typing
      // Esta tabela precisa ser criada no Supabase
      if (isTyping) {
        await _client
            .from('typing_indicators')
            .upsert({
              'conversation_id': conversationId,
              'user_id': user.id,
              'is_typing': true,
              'updated_at': DateTime.now().toIso8601String(),
            });
      } else {
        await _client
            .from('typing_indicators')
            .delete()
            .eq('conversation_id', conversationId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Ignorar erro se a tabela não existir
      print('Erro ao enviar indicador de digitação: $e');
    }
  }

  // Stream de indicadores de "digitando" em uma conversa
  static Stream<Map<String, bool>> getTypingIndicators(String conversationId) {
    try {
      final user = currentUser;
      if (user == null) return Stream.value({});

      // Stream de indicadores de typing
      return _client
          .from('typing_indicators')
          .stream(primaryKey: ['conversation_id', 'user_id'])
          .eq('conversation_id', conversationId)
          .map((data) {
            final indicators = <String, bool>{};
            for (final item in data) {
              // Filtrar manualmente para excluir o usuário atual
              if (item['user_id'] != user.id) {
                indicators[item['user_id']] = item['is_typing'] ?? false;
              }
            }
            return indicators;
          });
    } catch (e) {
      print('Erro ao obter indicadores de digitação: $e');
      return Stream.value({});
    }
  }

  // Criar grupo
  static Future<String> createGroup(String name, List<String> participantIds, {bool isPublic = false}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para criar grupos.');
      }

      // Criar conversa do tipo grupo
      final conversationResponse = await _client
          .from('conversations')
          .insert({
            'name': name,
            'type': 'group',
            'is_public': isPublic,
            'created_by': user.id,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'];

      // Adicionar criador como participante
      await _client.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': user.id,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Adicionar outros participantes
      for (final participantId in participantIds) {
        if (participantId != user.id) {
          await _client.from('conversation_participants').insert({
            'conversation_id': conversationId,
            'user_id': participantId,
            'joined_at': DateTime.now().toIso8601String(),
          });
        }
      }

      print('✅ Grupo criado: $conversationId');
      return conversationId;
    } catch (e) {
      print('❌ Erro ao criar grupo: $e');
      throw Exception('Erro ao criar grupo: ${e.toString()}');
    }
  }

  // Buscar grupos públicos
  static Future<List<Map<String, dynamic>>> searchPublicGroups(String query) async {
    try {
      final user = currentUser;
      if (user == null) return [];

      var queryBuilder = _client
          .from('conversations')
          .select('id, name, type, is_public, created_at')
          .eq('type', 'group')
          .eq('is_public', true);

      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('name', '%$query%');
      }

      final groups = await queryBuilder.order('created_at', ascending: false).limit(20);

      return List<Map<String, dynamic>>.from(groups);
    } catch (e) {
      print('Erro ao buscar grupos públicos: $e');
      return [];
    }
  }

  // Entrar em um grupo público
  static Future<void> joinGroup(String conversationId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para entrar em grupos.');
      }

      // Verificar se o grupo é público
      final group = await _client
          .from('conversations')
          .select('is_public, type')
          .eq('id', conversationId)
          .single();

      if (group['type'] != 'group') {
        throw Exception('Esta não é uma conversa de grupo.');
      }

      if (group['is_public'] != true) {
        throw Exception('Este grupo é privado. Você precisa de um convite.');
      }

      // Verificar se já é participante
      final existing = await _client
          .from('conversation_participants')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Você já é membro deste grupo.');
      }

      // Adicionar como participante
      await _client.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': user.id,
        'joined_at': DateTime.now().toIso8601String(),
      });

      print('✅ Entrou no grupo: $conversationId');
    } catch (e) {
      print('❌ Erro ao entrar no grupo: $e');
      throw Exception('Erro ao entrar no grupo: ${e.toString()}');
    }
  }

  // Adicionar participantes a um grupo
  static Future<void> addParticipantsToGroup(String conversationId, List<String> participantIds) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado.');
      }

      // Verificar se é admin/criador do grupo
      final group = await _client
          .from('conversations')
          .select('created_by, type')
          .eq('id', conversationId)
          .single();

      if (group['type'] != 'group') {
        throw Exception('Esta não é uma conversa de grupo.');
      }

      if (group['created_by'] != user.id) {
        throw Exception('Apenas o criador do grupo pode adicionar participantes.');
      }

      // Adicionar participantes
      for (final participantId in participantIds) {
        final existing = await _client
            .from('conversation_participants')
            .select('id')
            .eq('conversation_id', conversationId)
            .eq('user_id', participantId)
            .maybeSingle();

        if (existing == null) {
          await _client.from('conversation_participants').insert({
            'conversation_id': conversationId,
            'user_id': participantId,
            'joined_at': DateTime.now().toIso8601String(),
          });
        }
      }

      print('✅ Participantes adicionados ao grupo');
    } catch (e) {
      print('❌ Erro ao adicionar participantes: $e');
      throw Exception('Erro ao adicionar participantes: ${e.toString()}');
    }
  }

  // Enviar mensagem para grupo
  static Future<void> sendGroupMessage(String conversationId, String content, {String? imageUrl, String? fileUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para enviar mensagens.');
      }

      // Verificar se é participante do grupo
      final participant = await _client
          .from('conversation_participants')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('user_id', user.id)
          .filter('left_at', 'is', null)
          .maybeSingle();

      if (participant == null) {
        throw Exception('Você não é membro deste grupo.');
      }

      // Determinar tipo de mensagem
      String messageType = 'text';
      String? fileUrlToUse;
      if (imageUrl != null) {
        messageType = 'image';
        fileUrlToUse = imageUrl;
      } else if (fileUrl != null) {
        messageType = 'file';
        fileUrlToUse = fileUrl;
      }

      // Inserir mensagem no banco
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': content.isEmpty ? (imageUrl != null ? '📷 Imagem' : fileUrl != null ? '📎 Arquivo' : '') : content,
        'message_type': messageType,
        'file_url': fileUrlToUse,
      });

      print('✅ Mensagem enviada para o grupo');
    } catch (e) {
      print('❌ Erro ao enviar mensagem para grupo: $e');
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  // Obter stream de mensagens de grupo
  static Stream<List<Message>> getGroupMessagesStream(String conversationId) async* {
    final user = currentUser;
    if (user == null) {
      yield [];
      return;
    }

    try {
      final profiles = <String, String>{};

      List<Message> processMessages(List<dynamic> data) {
        final messages = <Message>[];

        for (final msg in data) {
          final senderId = msg['sender_id'];

          Map<String, List<String>>? reactions;
          if (msg['reactions'] != null && msg['reactions'] is Map) {
            reactions = Map<String, List<String>>.from(
              (msg['reactions'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value ?? []),
                ),
              ),
            );
          }

          final createdAtUtc = DateTime.parse(msg['created_at']);
          final createdAt = createdAtUtc.isUtc ? createdAtUtc.toLocal() : createdAtUtc;

          DateTime? editedAt;
          if (msg['edited_at'] != null) {
            final editedAtUtc = DateTime.parse(msg['edited_at']);
            editedAt = editedAtUtc.isUtc ? editedAtUtc.toLocal() : editedAtUtc;
          }

          messages.add(Message(
            id: msg['id'],
            content: msg['content'] ?? '',
            senderId: senderId,
            senderName: profiles[senderId] ?? 'Usuário',
            createdAt: createdAt,
            imageUrl: msg['file_url'],
            isFavorite: msg['is_favorite'] ?? false,
            isArchived: msg['is_archived'] ?? false,
            isDeleted: msg['is_deleted'] ?? false,
            isEdited: msg['is_edited'] ?? false,
            editedAt: editedAt,
            reactions: reactions,
          ));
        }
        return messages;
      }

      // Carregar mensagens existentes
      try {
        final initialMessages = await _client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);

        final senderIds = initialMessages.map((m) => m['sender_id'] as String).toSet().toList();
        if (senderIds.isNotEmpty) {
          final profilesData = await _client
              .from('profiles')
              .select('id, name')
              .inFilter('id', senderIds);

          for (final profile in profilesData) {
            profiles[profile['id']] = profile['name'] ?? 'Usuário';
          }
        }

        final messages = processMessages(initialMessages);
        yield messages;
      } catch (e) {
        print('❌ Erro ao carregar mensagens iniciais: $e');
      }

      // Escutar novas mensagens via stream
      await for (final data in _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)) {
        final senderIds = data.map((m) => m['sender_id'] as String).toSet().toList();
        final newSenderIds = senderIds.where((id) => !profiles.containsKey(id)).toList();

        if (newSenderIds.isNotEmpty) {
          try {
            final profilesData = await _client
                .from('profiles')
                .select('id, name')
                .inFilter('id', newSenderIds);

            for (final profile in profilesData) {
              profiles[profile['id']] = profile['name'] ?? 'Usuário';
            }
          } catch (e) {
            print('❌ Erro ao buscar perfis: $e');
            for (final id in newSenderIds) {
              profiles[id] = 'Usuário';
            }
          }
        }

        final messages = processMessages(data);
        yield messages;
      }
    } catch (e) {
      print('❌ Erro no stream de mensagens do grupo: $e');
      yield [];
    }
  }

  // Marcar mensagens como lidas
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      print('📖 Marcando mensagens como lidas na conversa: $conversationId');

      // Tentar usar a função do banco de dados
      try {
        await _client.rpc('mark_messages_as_read', params: {
          'p_conversation_id': conversationId,
          'p_user_id': user.id,
        });
        print('✅ Mensagens marcadas como lidas via função RPC');
      } catch (e) {
        print('⚠️ Função RPC não disponível, usando fallback: $e');
        
        // Fallback: marcar manualmente
        final messages = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', conversationId)
            .neq('sender_id', user.id);

        for (final msg in messages) {
          try {
            await _client.from('message_reads').insert({
              'message_id': msg['id'],
              'user_id': user.id,
              'read_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            // Ignorar erro se já existe (conflito de unique constraint)
            if (!e.toString().contains('duplicate') && !e.toString().contains('unique')) {
              print('⚠️ Erro ao marcar mensagem como lida: $e');
            }
          }
        }
        print('✅ Mensagens marcadas como lidas via fallback');
      }
    } catch (e) {
      print('❌ Erro ao marcar mensagens como lidas: $e');
    }
  }

  // Verificar se uma mensagem foi lida
  static Future<bool> isMessageRead(String messageId, String userId) async {
    try {
      final read = await _client
          .from('message_reads')
          .select('id')
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .maybeSingle();

      return read != null;
    } catch (e) {
      print('❌ Erro ao verificar leitura: $e');
      return false;
    }
  }

  // Obter lista de usuários que leram uma mensagem
  static Future<List<String>> getMessageReaders(String messageId) async {
    try {
      final reads = await _client
          .from('message_reads')
          .select('user_id')
          .eq('message_id', messageId);

      return reads.map((r) => r['user_id'] as String).toList();
    } catch (e) {
      print('❌ Erro ao buscar leitores: $e');
      return [];
    }
  }

  // Stream de status de leitura de uma mensagem
  static Stream<List<String>> getMessageReadersStream(String messageId) {
    try {
      return _client
          .from('message_reads')
          .stream(primaryKey: ['id'])
          .eq('message_id', messageId)
          .map((data) => data.map((r) => r['user_id'] as String).toList());
    } catch (e) {
      print('❌ Erro no stream de leitores: $e');
      return Stream.value([]);
    }
  }
}
