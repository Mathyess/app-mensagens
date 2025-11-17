import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../theme/matrix_theme.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? chatName;

  const HomeScreen({
    super.key,
    this.userId,
    this.chatName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _cachedUserId;
  String? _cachedConversationId;
  Map<String, bool> _typingUsers = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _cachedUserId = widget.userId;
      return;
    }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final newUserId = args?['userId'] as String?;

    if (newUserId != null && newUserId.isNotEmpty) {
      _cachedUserId = newUserId;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
<<<<<<< HEAD
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
=======
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
    }
  }

  String _getChatName() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return widget.chatName ?? args?['chatName'] ?? 'Chat';
  }

  Future<void> _handleSendMessage(String content) async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    print('📨 Enviando mensagem...');
    print('📦 Args: $args');

    final recipientId = _cachedUserId ?? widget.userId ?? args?['userId'];
    print('🔑 UserId extraído: "$recipientId"');

    if (recipientId == null || recipientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Destinatário não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await SupabaseService.sendMessage(content, recipientId);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final recipientId = _cachedUserId ?? widget.userId ?? args?['userId'];

    print('🔍 Build StreamBuilder - userId do widget: "${widget.userId}", dos args: "${args?['userId']}"');

    return Scaffold(
      backgroundColor: MatrixTheme.darkerBackground,
      appBar: AppBar(
        backgroundColor: MatrixTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MatrixTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    MatrixTheme.primaryPurple,
                    MatrixTheme.lightPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getChatName().isNotEmpty
                      ? _getChatName()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getChatName(),
                style: const TextStyle(
                  color: MatrixTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (recipientId == null || recipientId.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum destinatário selecionado',
                      style: TextStyle(
                        color: MatrixTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<Message>>(
                  stream: SupabaseService.getMessagesStream(recipientId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(MatrixTheme.primaryPurple),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar mensagens',
                              style: const TextStyle(
                                color: MatrixTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: const TextStyle(
                                color: MatrixTheme.textSecondary,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: MatrixTheme.cardBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: MatrixTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Nenhuma mensagem ainda',
                              style: TextStyle(
                                color: MatrixTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Envie uma mensagem para começar',
                              style: TextStyle(
                                color: MatrixTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _scrollToBottom();
                      });
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: false,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final currentUser = SupabaseService.currentUser;
                        final isMe = message.senderId == currentUser?.id;

                        return MessageBubble(
                          message: message,
                          isMe: isMe,
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
          ),
        ],
      ),
<<<<<<< HEAD
    );
  }
=======
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
                  // Priorizar userId do widget
                  String? userId = widget.userId;

                  // Fallback: tentar pegar dos argumentos
                  if (userId == null || userId.isEmpty) {
                    final args = ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                    userId = args?['userId'] as String?;
                  }

                  print(
                      '🔍 Build StreamBuilder - userId do widget: "${widget.userId}", dos args: "${userId}"');

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
                          const SizedBox(height: 8),
                          Text(
                            'Widget userId: ${widget.userId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Cache para uso posterior
                  _cachedUserId = userId;

                  return StreamBuilder<List<Message>>(
                    stream: SupabaseService.getMessagesStream(userId),
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
    // Priorizar chatName do widget
    if (widget.chatName != null && widget.chatName!.isNotEmpty) {
      return widget.chatName!;
    }

    // Fallback: tentar pegar dos argumentos
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['chatName'] as String? ?? 'Conversa';
  }

  String _getUserId() {
    // Usar o cache se disponível
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId!;
    }

    // Caso contrário, buscar dos argumentos
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] as String? ?? '';
    print('🔑 HomeScreen - userId recebido: "$userId"');
    print('📦 HomeScreen - args completos: $args');
    return userId;
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
    // Garantir que ambas estão no fuso horário local
    final localDate1 = date1.isUtc ? date1.toLocal() : date1;
    final localDate2 = date2.isUtc ? date2.toLocal() : date2;
    
    return localDate1.year == localDate2.year &&
        localDate1.month == localDate2.month &&
        localDate1.day == localDate2.day;
  }

  String _formatDate(DateTime date) {
    // Garantir que está no fuso horário local
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
      // Formato: "Segunda-feira, 15 de Janeiro de 2024"
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
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
}
