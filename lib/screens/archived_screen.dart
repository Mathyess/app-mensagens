import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';

class ArchivedScreen extends StatefulWidget {
  const ArchivedScreen({super.key});

  @override
  State<ArchivedScreen> createState() => _ArchivedScreenState();
}

class _ArchivedScreenState extends State<ArchivedScreen> {
  List<Message> _archived = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchived();
  }

  Future<void> _loadArchived() async {
    try {
      final archived = await SupabaseService.getArchivedMessages();
      if (mounted) {
        setState(() {
          _archived = archived;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar mensagens arquivadas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = SupabaseService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mensagens Arquivadas'),
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _archived.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 80,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma mensagem arquivada',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pressione e segure uma mensagem\npara arquivá-la',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        isDark
                            ? 'assets/chat_bg_dark.png'
                            : 'assets/chat_bg.png',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.1,
                    ),
                  ),
                  child: ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _archived.length,
                    itemBuilder: (context, index) {
                      final message = _archived[index];
                      final isMe = message.senderId == currentUserId;

                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        onArchivedToggled: _loadArchived,
                      );
                    },
                  ),
                ),
    );
  }
}
