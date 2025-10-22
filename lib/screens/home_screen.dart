import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/app_drawer.dart';
import '../routes.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Priorizar userId do widget
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _cachedUserId = widget.userId;
      print('💾 Cache userId do widget: "$_cachedUserId"');
      return;
    }

    // Fallback: tentar pegar dos argumentos da rota
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final newUserId = args?['userId'] as String?;

    if (newUserId != null && newUserId.isNotEmpty) {
      _cachedUserId = newUserId;
      print('💾 Cache userId dos args: "$_cachedUserId"');
    } else {
      print(
          '⚠️ Nenhum userId encontrado (widget: ${widget.userId}, args: $newUserId)');
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
    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;

      print('📨 Enviando mensagem...');
      print('📦 Args: $args');
      print('🔑 UserId extraído: "$userId"');

      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não encontrado ou ID inválido');
      }

      await SupabaseService.sendMessage(content, userId);
      
      // Aguardar um pouco para garantir que o stream receba a nova mensagem
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Scroll para o final após enviar
      if (mounted) {
        _scrollToBottom();
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
      backgroundColor: MatrixTheme.matrixBlack,
      appBar: AppBar(
        backgroundColor: MatrixTheme.matrixBlack,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: MatrixTheme.matrixGreen,
            size: 24,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: MatrixTheme.matrixGreen, width: 2),
                color: MatrixTheme.matrixDarkGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getChatName().isNotEmpty
                      ? _getChatName()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: MatrixTheme.matrixGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '> ${_getChatName()}',
                style: const TextStyle(
                  color: MatrixTheme.matrixGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.terminal,
              color: MatrixTheme.matrixGreen,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('>> CONNECTION: ${_getChatName()}'),
                  backgroundColor: MatrixTheme.matrixDarkGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: MatrixTheme.matrixBlack,
          image: DecorationImage(
            image: NetworkImage('https://www.transparenttextures.com/patterns/45-degree-fabric-dark.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
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
                                  border: Border.all(color: MatrixTheme.matrixGreen, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      MatrixTheme.matrixGreen),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '>> LOADING_DATA...',
                                style: TextStyle(
                                  color: MatrixTheme.matrixGreen,
                                  fontSize: 14,
                                  fontFamily: 'Courier',
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
                                  border: Border.all(color: MatrixTheme.matrixGreen, width: 2),
                                  color: MatrixTheme.matrixDarkGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.code,
                                  size: 40,
                                  color: MatrixTheme.matrixGreen,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                '> NO_MESSAGES_FOUND',
                                style: TextStyle(
                                  color: MatrixTheme.matrixGreen,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '>> Inicie a transmissão...',
                                style: TextStyle(
                                  color: MatrixTheme.matrixDimGreen,
                                  fontSize: 14,
                                  fontFamily: 'Courier',
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
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'HOJE';
    } else if (messageDate == yesterday) {
      return 'ONTEM';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
