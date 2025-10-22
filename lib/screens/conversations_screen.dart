import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../routes.dart';
import '../theme/matrix_theme.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await SupabaseService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
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
            content: Text('Erro ao carregar conversas: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseService.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Usuário';

    return Scaffold(
      backgroundColor: MatrixTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: MatrixTheme.darkBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mensagens',
              style: TextStyle(
                color: MatrixTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                color: MatrixTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: MatrixTheme.textPrimary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: MatrixTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                hintStyle: const TextStyle(color: MatrixTheme.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: MatrixTheme.textTertiary),
                filled: true,
                fillColor: MatrixTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Lista de conversas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(MatrixTheme.primaryPurple),
                    ),
                  )
                : _conversations.isEmpty
                    ? Center(
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
                                Icons.forum_outlined,
                                size: 40,
                                color: MatrixTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Nenhuma conversa',
                              style: TextStyle(
                                color: MatrixTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Toque no + para começar uma conversa',
                              style: TextStyle(
                                color: MatrixTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationTile(conversation);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.newConversation);
        },
        backgroundColor: MatrixTheme.primaryPurple,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: MatrixTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getColorFromName(conversation['name']),
                _getColorFromName(conversation['name']).withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              (conversation['name'] as String)[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation['name'] as String,
                style: const TextStyle(
                  color: MatrixTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              conversation['time'] as String,
              style: const TextStyle(
                color: MatrixTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation['lastMessage'] as String,
                style: TextStyle(
                  color: (conversation['hasUnread'] as bool)
                      ? MatrixTheme.textSecondary
                      : MatrixTheme.textTertiary,
                  fontSize: 14,
                  fontWeight: (conversation['hasUnread'] as bool)
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if ((conversation['hasUnread'] as bool) && (conversation['unreadCount'] as int) > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MatrixTheme.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (conversation['unreadCount'] as int).toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          final otherUserId = conversation['otherUserId'];
          
          if (otherUserId != null && otherUserId.toString().isNotEmpty) {
            Navigator.pushNamed(
              context,
              AppRoutes.home,
              arguments: {
                'chatName': conversation['name'],
                'userId': otherUserId,
              },
            );
          }
        },
        onLongPress: () {
          _showDeleteDialog(conversation);
        },
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colors = [
      MatrixTheme.primaryPurple,
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  void _showDeleteDialog(Map<String, dynamic> conversation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MatrixTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Remover Conversa',
            style: TextStyle(color: MatrixTheme.textPrimary),
          ),
          content: Text(
            'Tem certeza que deseja remover a conversa com ${conversation['name']}?',
            style: const TextStyle(
              fontSize: 16,
              color: MatrixTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: MatrixTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeConversation(conversation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeConversation(Map<String, dynamic> conversation) async {
    try {
      await SupabaseService.removeConversation(conversation['id']);
      
      setState(() {
        _conversations.removeWhere((conv) => conv['id'] == conversation['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversa com ${conversation['name']} removida'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover conversa: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

