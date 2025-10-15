import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/app_drawer.dart';
import '../routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] as String?;
      
      if (userId == null) {
        throw Exception('Usuário não encontrado');
      }
      
      await SupabaseService.sendMessage(content, userId);
      _scrollToBottom();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
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
                  _getChatName().isNotEmpty ? _getChatName()[0].toUpperCase() : '?',
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
              child: StreamBuilder<List<Message>>(
                stream: SupabaseService.getMessagesStream(_getUserId()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    final errorMessage = snapshot.error.toString().replaceFirst('Exception: ', '');
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                errorMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Carregando mensagens...',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Seja o primeiro a enviar uma mensagem!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser?.id;
                      
                      final showDateSeparator = index == messages.length - 1 ||
                          !_isSameDay(message.createdAt, messages[index + 1].createdAt);

                      return Column(
                        children: [
                          if (showDateSeparator)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['chatName'] as String? ?? 'Conversa';
  }

  String _getUserId() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
