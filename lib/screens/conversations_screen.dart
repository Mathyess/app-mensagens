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
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    
    // Adicionar listener para busca
    _searchController.addListener(_filterConversations);
    
    // Atualizar status online quando entrar
    _updateOnlineStatus(true);
  }
  
  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      await SupabaseService.updateOnlineStatus(isOnline);
    } catch (e) {
      print('Erro ao atualizar status online: $e');
    }
  }
  
  void _filterConversations() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredConversations = _conversations;
      });
    } else {
      setState(() {
        _filteredConversations = _conversations.where((conv) {
          final name = (conv['name'] as String? ?? '').toLowerCase();
          final lastMessage = (conv['lastMessage'] as String? ?? '').toLowerCase();
          return name.contains(query) || lastMessage.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await SupabaseService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filteredConversations = conversations;
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
<<<<<<< HEAD
=======
    // Atualizar status offline quando sair
    _updateOnlineStatus(false);
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
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
<<<<<<< HEAD
              style: const TextStyle(color: MatrixTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                hintStyle: const TextStyle(color: MatrixTheme.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: MatrixTheme.textTertiary),
=======
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        color: const Color(0xFF9CA3AF),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
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
                : _filteredConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
<<<<<<< HEAD
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
=======
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Nenhuma conversa encontrada'
                                  : 'Nenhuma conversa ainda',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Tente buscar por outro termo'
                                  : 'Toque no botão + para iniciar uma conversa',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF9CA3AF),
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
<<<<<<< HEAD
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationTile(conversation);
=======
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _filteredConversations[index];
                          return _buildSimpleConversationTile(conversation);
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
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

<<<<<<< HEAD
  Widget _buildConversationTile(Map<String, dynamic> conversation) {
=======
  Widget _buildSimpleConversationTile(Map<String, dynamic> conversation) {
    final isOnline = conversation['isOnline'] ?? false;
    
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
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
<<<<<<< HEAD
          ),
=======
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
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

