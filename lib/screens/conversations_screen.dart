import 'package:flutter/material.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/app_drawer.dart';
import '../services/supabase_service.dart';
import '../routes.dart';
import '../theme/matrix_theme.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _searchAnimation;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabAnimationController.forward();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      print('🔄 Carregando conversas...');
      final conversations = await SupabaseService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
        print('✅ ${conversations.length} conversas carregadas');
      }
    } catch (e) {
      print('❌ Erro ao carregar conversas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar conversas: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar conversas ao voltar para esta tela
    _loadConversations();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
      }
    });
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
                const Icon(Icons.error_outline, color: Colors.white),
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
              borderRadius: BorderRadius.circular(12),
            ),
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
        title: const Text(
          '>> MATRIX_CHAT_SYSTEM_',
          style: TextStyle(
            color: MatrixTheme.matrixGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Courier',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: MatrixTheme.matrixGreen,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de busca Matrix
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(
                color: MatrixTheme.matrixGreen,
                fontFamily: 'Courier',
              ),
              decoration: InputDecoration(
                hintText: '> search_connections...',
                hintStyle: const TextStyle(
                  color: MatrixTheme.matrixDimGreen,
                  fontFamily: 'Courier',
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: MatrixTheme.matrixGreen,
                  size: 20,
                ),
                filled: true,
                fillColor: MatrixTheme.matrixGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: MatrixTheme.matrixDimGreen),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: MatrixTheme.matrixDimGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: MatrixTheme.matrixGreen,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: MatrixTheme.matrixGreen.withOpacity(0.3)),
          // Lista de conversas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(MatrixTheme.matrixGreen),
                    ),
                  )
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.terminal,
                              size: 64,
                              color: MatrixTheme.matrixGreen,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '> NO_CONNECTIONS_FOUND',
                              style: TextStyle(
                                color: MatrixTheme.matrixGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toque no botão + para iniciar uma conversa',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildSimpleConversationTile(conversation);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.newConversation);
        },
        backgroundColor: MatrixTheme.matrixGreen,
        foregroundColor: MatrixTheme.matrixBlack,
        elevation: 0,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildSimpleConversationTile(Map<String, dynamic> conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColorFromName(conversation['name']),
                    _getColorFromName(conversation['name']).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
              child: Text(
                (conversation['name'] as String)[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ),
            ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                conversation['name'] as String,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: (conversation['hasUnread'] as bool) 
                      ? FontWeight.w600 
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              conversation['time'] as String,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: (conversation['hasUnread'] as bool)
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF9CA3AF),
                fontWeight: (conversation['hasUnread'] as bool)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation['lastMessage'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (conversation['hasUnread'] as bool)
                      ? const Color(0xFF374151)
                      : const Color(0xFF6B7280),
                  fontWeight: (conversation['hasUnread'] as bool)
                      ? FontWeight.w500
                      : FontWeight.w400,
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
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (conversation['unreadCount'] as int).toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Verificar se temos o ID do outro usuário
          final otherUserId = conversation['otherUserId'];
          
          if (otherUserId != null && otherUserId.toString().isNotEmpty) {
            print('🚀 Abrindo conversa com userId: $otherUserId');
            
            // Abrir conversa individual
            Navigator.pushNamed(
              context,
              AppRoutes.home,
              arguments: {
                'chatName': conversation['name'],
                'userId': otherUserId,
              },
            );
          } else {
            print('❌ otherUserId vazio ou nulo: $otherUserId');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não foi possível abrir a conversa - ID do usuário inválido'),
                backgroundColor: Colors.red,
              ),
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

  void _showDeleteDialog(Map<String, dynamic> conversation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('Remover Conversa'),
            ],
          ),
          content: Text(
            'Tem certeza que deseja remover a conversa com ${conversation['name']}? Esta ação não pode ser desfeita.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeConversation(conversation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Remover',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeConversation(Map<String, dynamic> conversation) async {
    try {
      await SupabaseService.removeConversation(conversation['id']);
      
      // Atualizar a lista local
      setState(() {
        _conversations.removeWhere((conv) => conv['id'] == conversation['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Conversa com ${conversation['name']} removida'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
                    'Erro ao remover conversa: ${e.toString().replaceFirst('Exception: ', '')}',
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

}
