import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/app_drawer.dart';
import '../routes.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? chatName;
  final String? conversationId;
  final bool isGroup;

  const HomeScreen({
    super.key,
    this.userId,
    this.chatName,
    this.conversationId,
    this.isGroup = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _cachedUserId;
  String? _cachedConversationId;
  bool _isGroup = false;
  Map<String, bool> _typingUsers = {};
  final StreamController<List<Message>> _messagesController = StreamController<List<Message>>.broadcast();
  StreamSubscription<List<Message>>? _messagesSubscription;
  List<Message> _pendingMessages = [];
  List<Message> _serverMessages = [];
  String? _otherUserAvatarUrl;
  bool _isLoadingAvatar = true;

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messagesController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (widget.conversationId != null) {
      _cachedConversationId = widget.conversationId;
      _isGroup = widget.isGroup;
      _markMessagesAsRead();
      return;
    }

    if (args?['conversationId'] != null) {
      _cachedConversationId = args?['conversationId'] as String;
      _isGroup = args?['isGroup'] as bool? ?? false;
      _markMessagesAsRead();
      return;
    }

    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _cachedUserId = widget.userId;
      _loadOtherUserAvatar(widget.userId!);
      return;
    }

    final newUserId = args?['userId'] as String?;
    if (newUserId != null && newUserId.isNotEmpty) {
      _cachedUserId = newUserId;
      _loadOtherUserAvatar(newUserId);
    }
  }
  
  Future<void> _loadOtherUserAvatar(String userId) async {
    try {
      final client = Supabase.instance.client;
      final profile = await client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          _otherUserAvatarUrl = profile['avatar_url'];
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar avatar: $e');
      if (mounted) {
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_cachedConversationId != null) {
      await SupabaseService.markMessagesAsRead(_cachedConversationId!);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _emitCombinedMessages() {
    if (_messagesController.isClosed) return;
    
    final allMessages = <Message>[];
    allMessages.addAll(_serverMessages);
    
    for (final pending in _pendingMessages) {
      final existsInServer = _serverMessages.any((server) {
        return server.content == pending.content &&
            server.senderId == pending.senderId &&
            (server.createdAt.difference(pending.createdAt).inSeconds.abs() < 5);
      });
      
      if (!existsInServer) {
        allMessages.add(pending);
      }
    }
    
    allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _messagesController.add(allMessages);
  }

  Future<void> _handleLogout() async {
    try {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erro ao sair: ${e.toString().replaceFirst('Exception: ', '')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSendMessage(String content) async {
    String? tempId;
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticMessage = Message(
        id: tempId,
        content: content,
        senderId: currentUser.id,
        senderName: currentUser.userMetadata?['name'] ?? 'Você',
        createdAt: DateTime.now(),
      );

      setState(() {
        _pendingMessages.add(optimisticMessage);
      });

      _emitCombinedMessages();

      if (_isGroup && _cachedConversationId != null) {
        await SupabaseService.sendGroupMessage(_cachedConversationId!, content);
      } else {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String? ?? widget.userId;

        if (userId == null || userId.isEmpty) {
          throw Exception('Usuário não encontrado ou ID inválido');
        }

        await SupabaseService.sendMessage(content, userId);
      }

      _scrollToBottom();
    } catch (e) {
      if (tempId != null) {
        setState(() {
          _pendingMessages.removeWhere((msg) => msg.id == tempId);
        });
        _emitCombinedMessages();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade50,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseService.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Usuário';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF374151),
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.conversations);
            }
          },
        ),
        title: Row(
          children: [
            _otherUserAvatarUrl != null && _otherUserAvatarUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      _otherUserAvatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getColorFromName(_getChatName()),
                                _getColorFromName(_getChatName()).withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getChatName().isNotEmpty
                                  ? _getChatName()[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getColorFromName(_getChatName()),
                          _getColorFromName(_getChatName()).withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getChatName().isNotEmpty
                            ? _getChatName()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getChatName(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF374151),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversa com ${_getChatName()}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Color(0xFFF3F4F6),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isGroup && _cachedConversationId != null) {
                    if (_messagesSubscription == null) {
                      _messagesSubscription = SupabaseService.getGroupMessagesStream(_cachedConversationId!).listen(
                        (serverMessages) {
                          if (!mounted) return;
                          
                          _serverMessages = serverMessages;
                          
                          setState(() {
                            _pendingMessages.removeWhere((pending) {
                              return serverMessages.any((server) {
                                return server.content == pending.content &&
                                    server.senderId == pending.senderId &&
                                    (server.createdAt.difference(pending.createdAt).inSeconds.abs() < 5);
                              });
                            });
                          });

                          _emitCombinedMessages();
                        },
                        onError: (error) {
                          if (!_messagesController.isClosed) {
                            _messagesController.addError(error);
                          }
                        },
                      );
                    }
                  } else {
                    String? userId = widget.userId;

                    if (userId == null || userId.isEmpty) {
                      final args = ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                      userId = args?['userId'] as String?;
                    }

                    if (userId == null || userId.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Erro: ID do usuário não encontrado',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final previousUserId = _cachedUserId;
                    _cachedUserId = userId;

                    if (previousUserId != userId) {
                      _messagesSubscription?.cancel();
                      _messagesSubscription = null;
                      _pendingMessages.clear();
                      _serverMessages.clear();
                    }

                    if (_messagesSubscription == null) {
                      // Carregar conversationId se ainda não tiver
                      if (_cachedConversationId == null) {
                        _loadConversationId(userId);
                      }
                      
                      _messagesSubscription = SupabaseService.getMessagesStream(userId).listen(
                        (serverMessages) async {
                          if (!mounted) return;
                          
                          _serverMessages = serverMessages;
                          
                          setState(() {
                            _pendingMessages.removeWhere((pending) {
                              return serverMessages.any((server) {
                                return server.content == pending.content &&
                                    server.senderId == pending.senderId &&
                                    (server.createdAt.difference(pending.createdAt).inSeconds.abs() < 5);
                              });
                            });
                          });

                          _emitCombinedMessages();
                          
                          // Marcar mensagens como lidas quando receber novas mensagens
                          if (_cachedConversationId != null) {
                            await SupabaseService.markMessagesAsRead(_cachedConversationId!);
                          }
                        },
                        onError: (error) {
                          if (!_messagesController.isClosed) {
                            _messagesController.addError(error);
                          }
                        },
                      );
                    }
                  }

                  return StreamBuilder<List<Message>>(
                    stream: _messagesController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        final errorMessage = snapshot.error
                            .toString()
                            .replaceFirst('Exception: ', '');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    size: 40,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Erro ao carregar mensagens',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    errorMessage,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.red.shade700,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Tentar novamente'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Carregando mensagens...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      final messages = snapshot.data!;

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6366F1).withOpacity(0.1),
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 40,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Nenhuma mensagem ainda',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Seja o primeiro a enviar uma mensagem!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser?.id;

                          final showDateSeparator =
                              index == 0 ||
                                  !_isSameDay(message.createdAt,
                                      messages[index - 1].createdAt);

                          return Column(
                            children: [
                              if (showDateSeparator)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _formatDate(message.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: const Color(0xFF6B7280),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              MessageBubble(
                                message: message,
                                isMe: isMe,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            MessageInput(
              onSendMessage: _handleSendMessage,
              recipientId: _getUserId(),
            ),
          ],
        ),
      ),
    );
  }

  String _getChatName() {
    if (widget.chatName != null && widget.chatName!.isNotEmpty) {
      return widget.chatName!;
    }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['chatName'] as String? ?? 'Conversa';
  }

  String _getUserId() {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['userId'] as String? ?? '';
  }

  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    final localDate1 = date1.isUtc ? date1.toLocal() : date1;
    final localDate2 = date2.isUtc ? date2.toLocal() : date2;
    
    return localDate1.year == localDate2.year &&
        localDate1.month == localDate2.month &&
        localDate1.day == localDate2.day;
  }

  String _formatDate(DateTime date) {
    final localDate = date.isUtc ? date.toLocal() : date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (messageDate == today) {
      return 'HOJE';
    } else if (messageDate == yesterday) {
      return 'ONTEM';
    } else {
      final weekdays = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 
                       'Quinta-feira', 'Sexta-feira', 'Sábado'];
      final months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                     'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
      
      final weekday = weekdays[localDate.weekday % 7];
      final month = months[localDate.month - 1];
      
      return '$weekday, ${localDate.day} de $month de ${localDate.year}';
    }
  }

  Future<void> _loadConversationId(String userId) async {
    if (_cachedConversationId != null) {
      _listenToTypingIndicators(_cachedConversationId!);
      return;
    }

    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final client = Supabase.instance.client;
      final conversationId = await client.rpc(
        'create_direct_conversation',
        params: {
          'user1_id': user.id,
          'user2_id': userId,
        },
      );

      _cachedConversationId = conversationId;
      _listenToTypingIndicators(conversationId);
    } catch (e) {
      print('Erro ao obter conversation ID: $e');
    }
  }

  void _listenToTypingIndicators(String conversationId) {
    SupabaseService.getTypingIndicators(conversationId).listen((indicators) {
      if (mounted) {
        setState(() {
          _typingUsers = indicators;
        });
      }
    });
  }

  Stream<Map<String, String>> _getTypingUsersNames(List<String> userIds) async* {
    if (userIds.isEmpty) {
      yield {};
      return;
    }

    try {
      final client = Supabase.instance.client;
      final profiles = await client
          .from('profiles')
          .select('id, name')
          .inFilter('id', userIds);

      final names = <String, String>{};
      for (final profile in profiles) {
        names[profile['id']] = profile['name'] ?? 'Usuário';
      }

      yield names;
    } catch (e) {
      print('Erro ao buscar nomes: $e');
      yield {};
    }
  }
}
