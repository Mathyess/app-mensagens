import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final Map<String, StreamController<List<Message>>> _messageStreams = {};

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

      // Buscar perfil no banco de dados
      try {
        final profile = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        return AppUser.fromJson({
          'id': profile['id'],
          'email': profile['email'] ?? user.email ?? '',
          'name': profile['name'] ?? user.userMetadata?['name'] ?? 'Usuário',
          'avatar_url': profile['avatar_url'],
          'created_at': profile['created_at'] ?? user.createdAt ?? DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Se não encontrar perfil, criar um simples baseado nos dados do auth
        return AppUser.fromJson({
          'id': user.id,
          'email': user.email ?? '',
          'name': user.userMetadata?['name'] ?? 'Usuário',
          'created_at': user.createdAt ?? DateTime.now().toIso8601String(),
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

      // Retornar lista vazia - mensagens serão carregadas via stream
      return [];
    } catch (e) {
      throw Exception('Erro ao carregar mensagens: ${e.toString()}');
    }
  }

  // Upload de arquivo para o Storage do Supabase
  static Future<String> uploadFile(String filePath, String fileName) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para fazer upload.');
      }

      // Criar nome único para o arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '$timestamp-$fileName';
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      // Determinar pasta baseada no tipo
      String folder = 'files';
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
        folder = 'images';
      }

      Uint8List fileBytes;
      
      // Sempre usar XFile (funciona tanto na web quanto mobile/desktop)
      final xfile = XFile(filePath);
      fileBytes = await xfile.readAsBytes();
      
      // Verificar tamanho do arquivo (limite de 20MB)
      final fileSizeInMB = fileBytes.length / (1024 * 1024);
      if (fileSizeInMB > 20) {
        throw Exception('Arquivo muito grande. Tamanho máximo: 20MB');
      }
      
      // Upload para o Storage (bucket 'messages')
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

      // Obter URL pública
      final publicUrl = _client.storage
          .from('messages')
          .getPublicUrl('$folder/$uniqueFileName');

      print('✅ Arquivo enviado: $publicUrl');
      return publicUrl;
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

      print('📤 Enviando mensagem para: $recipientId');

      // Criar ou obter conversa direta
      final conversationId = await _client.rpc('create_direct_conversation', params: {
        'user1_id': user.id,
        'user2_id': recipientId
      });

      print('💬 Conversa ID: $conversationId');

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

      // Inserir mensagem no banco com timestamp explícito
      final now = DateTime.now().toUtc();
      final response = await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': content.isEmpty ? (imageUrl != null ? '📷 Imagem' : fileUrl != null ? '📎 Arquivo' : '') : content,
        'message_type': messageType,
        'file_url': fileUrlToUse,
        'created_at': now.toIso8601String(),
      }).select().single();

      print('✅ Mensagem enviada: ${response['id']} em ${now.toIso8601String()}');
      
      // Forçar refresh do stream (opcional - o Realtime deve capturar automaticamente)
      // Mas isso garante que a mensagem apareça imediatamente
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      if (e.toString().contains('NetworkException') || 
          e.toString().contains('SocketException')) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
      throw Exception('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  static Stream<List<Message>> getMessagesStream(String recipientId) {
    final user = currentUser;
    if (user == null) {
      print('❌ Usuário não autenticado');
      return Stream.value([]);
    }

    // Validar recipientId
    if (recipientId.isEmpty) {
      print('❌ recipientId está vazio');
      return Stream.value([]);
    }

    // Criar chave única para o stream
    final streamKey = '${user.id}_$recipientId';
    
    // Se já existe um stream para esta conversa, retornar ele
    if (_messageStreams.containsKey(streamKey)) {
      return _messageStreams[streamKey]!.stream;
    }

    // Criar novo StreamController
    final controller = StreamController<List<Message>>.broadcast();
    _messageStreams[streamKey] = controller;

    _initializeMessageStream(recipientId, controller);
    
    return controller.stream;
  }

  static Future<void> _initializeMessageStream(String recipientId, StreamController<List<Message>> controller) async {
    final user = currentUser;
    if (user == null) {
      controller.add([]);
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
      
      // Função auxiliar para processar mensagens
      List<Message> _processMessages(List<dynamic> data) {
        final messages = <Message>[];
        
        for (final msg in data) {
          final senderId = msg['sender_id'];
          
          // Parse reactions
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

          // Converter data UTC para fuso horário local
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
            isDeletedForEveryone: msg['is_deleted_for_everyone'] ?? false,
            isEdited: msg['is_edited'] ?? false,
            editedAt: editedAt,
            reactions: reactions,
          ));
        }
        return messages;
      }
      
      // Primeiro, carregar mensagens existentes
      try {
        final initialMessages = await _client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);
        
        print('📥 Carregando ${initialMessages.length} mensagens existentes');
        
        // Buscar nomes dos perfis em batch
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
        
        final messages = _processMessages(initialMessages);
        print('✅ Enviando ${messages.length} mensagens iniciais para o UI');
        controller.add(messages);
      } catch (e) {
        print('❌ Erro ao carregar mensagens iniciais: $e');
        controller.add([]);
      }
      
      // Depois, escutar novas mensagens via stream
      _client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .listen((data) async {
        
        print('📨 Recebido ${data.length} mensagens do stream');
        
        // Buscar nomes dos perfis em batch para novas mensagens
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
            // Preencher com valores padrão
            for (final id in newSenderIds) {
              profiles[id] = 'Usuário';
            }
          }
        }
        
        final messages = _processMessages(data);
        print('✅ Enviando ${messages.length} mensagens do stream para o UI');
        
        // Adicionar ao controller
        if (!controller.isClosed) {
          controller.add(messages);
        }
      }, onError: (error) {
        print('❌ Erro no stream de mensagens: $error');
        if (!controller.isClosed) {
          controller.addError(error);
        }
      });
      
    } catch (e) {
      print('❌ Erro no stream de mensagens: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      if (!controller.isClosed) {
        controller.add([]);
      }
    }
  }

  // Método para limpar streams quando não precisar mais
  static void disposeMessageStream(String recipientId) {
    final user = currentUser;
    if (user == null) return;
    
    final streamKey = '${user.id}_$recipientId';
    final controller = _messageStreams[streamKey];
    if (controller != null) {
      controller.close();
      _messageStreams.remove(streamKey);
    }
  }


  static Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Você precisa estar logado para atualizar o perfil.');
      }

      // Atualizar nome no auth se fornecido
      if (name != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'name': name}),
        );
      }

      // Atualizar perfil no banco
      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      } else if (avatarUrl == null && name == null) {
        // Se avatarUrl foi explicitamente null, remover
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

      // Atualizar status de favorito no banco de dados
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

      // Buscar mensagens favoritas nessas conversas
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

        // Parse reactions
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
          isDeletedForEveryone: msg['is_deleted_for_everyone'] ?? false,
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

      // Atualizar status de arquivado no banco de dados
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

      // Buscar mensagens arquivadas do usuário (em conversas onde ele participa)
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

      // Buscar mensagens arquivadas nessas conversas
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

        // Parse reactions
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
          isDeletedForEveryone: msg['is_deleted_for_everyone'] ?? false,
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

  // Deletar mensagem apenas para mim
  static Future<void> deleteMessageForMe(String messageId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Marcar como deletada apenas para o usuário atual (soft delete)
      await _client
          .from('messages')
          .update({
            'is_deleted': true,
          })
          .eq('id', messageId);

      print('✅ Mensagem deletada para mim: $messageId');
    } catch (e) {
      print('❌ Erro ao deletar mensagem: $e');
      throw Exception('Erro ao deletar mensagem: ${e.toString()}');
    }
  }

  // Deletar mensagem para todos
  static Future<void> deleteMessageForEveryone(String messageId) async {
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
        throw Exception('Você só pode deletar suas próprias mensagens para todos.');
      }

      // Marcar como deletada para todos (soft delete)
      await _client
          .from('messages')
          .update({
            'is_deleted_for_everyone': true,
            'content': 'Esta mensagem foi deletada',
          })
          .eq('id', messageId);

      print('✅ Mensagem deletada para todos: $messageId');
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
}
