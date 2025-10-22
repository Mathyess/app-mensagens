import 'package:flutter/material.dart';
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
    );
  }
}
