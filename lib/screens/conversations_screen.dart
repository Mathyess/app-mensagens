import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/app_drawer.dart';
import '../services/supabase_service.dart';
import '../routes.dart';

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
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;
  StreamSubscription? _messagesSubscription;
  Timer? _debounceTimer;

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
    _setupRealtimeListener();
    
    // Adicionar listener para busca
    _searchController.addListener(_filterConversations);
    
    // Atualizar status online quando entrar
    _updateOnlineStatus(true);
  }
  
  void _setupRealtimeListener() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    print('🔔 Configurando listener de realtime para conversas');

    _getConversationIds().then((conversationIds) {
      if (conversationIds.isEmpty) {
        print('⚠️ Nenhuma conversa encontrada para escutar');
        return;
      }

      print('📡 Escutando ${conversationIds.length} conversas');

      _messagesSubscription = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .inFilter('conversation_id', conversationIds)
          .listen((data) {
            print('📨 Nova mensagem detectada, atualizando lista...');
            
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                _loadConversations();
              }
            });
          });
    });
  }

  Future<List<String>> _getConversationIds() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return [];

      final result = await Supabase.instance.client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', user.id)
          .filter('left_at', 'is', null);

      return result.map((item) => item['conversation_id'] as String).toList();
    } catch (e) {
      print('❌ Erro ao buscar IDs de conversas: $e');
      return [];
    }
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
        final filtered = _conversations.where((conv) {
          final name = (conv['name'] as String? ?? '').toLowerCase();
          final lastMessage = (conv['lastMessage'] as String? ?? '').toLowerCase();
          return name.contains(query) || lastMessage.contains(query);
        }).toList();
        
        // Garantir que as conversas filtradas também estejam ordenadas
        filtered.sort((a, b) {
          final dateA = a['lastMessageDate'] as DateTime?;
          final dateB = b['lastMessageDate'] as DateTime?;
          
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          
          return dateB.compareTo(dateA); // Ordem decrescente: mais recente primeiro
        });
        
        _filteredConversations = filtered;
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      print('🔄 Carregando conversas...');
      final conversations = await SupabaseService.getConversations();
      if (mounted) {
        final sortedConversations = List<Map<String, dynamic>>.from(conversations);
        sortedConversations.sort((a, b) {
          final dateA = a['lastMessageDate'] as DateTime?;
          final dateB = b['lastMessageDate'] as DateTime?;
          
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          
          return dateB.compareTo(dateA);
        });
        
        setState(() {
          _conversations = sortedConversations;
          _filteredConversations = sortedConversations;
          _isLoading = false;
        });
        print('✅ ${sortedConversations.length} conversas carregadas e ordenadas');
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
    _loadConversations();
  }

  @override
  void dispose() {
    _updateOnlineStatus(false);
    _messagesSubscription?.cancel();
    _debounceTimer?.cancel();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Chats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF374151),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de busca simples
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
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
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
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
          const Divider(height: 1),
          // Lista de conversas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  )
                : _filteredConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _filteredConversations[index];
                          return _buildSimpleConversationTile(conversation);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "newGroup",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.newGroup);
            },
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            elevation: 0,
            mini: true,
            child: const Icon(Icons.group_add_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "newConversation",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.newConversation);
            },
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            child: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleConversationTile(Map<String, dynamic> conversation) {
    final isOnline = conversation['isOnline'] ?? false;
    final avatarUrl = conversation['avatarUrl'] as String?;
    
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
            avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      avatarUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
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
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Erro ao carregar avatar: $error');
                        print('URL: $avatarUrl');
                        return Container(
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
                              ((conversation['name'] as String?) ?? 'C')[0].toUpperCase(),
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
                        ((conversation['name'] as String?) ?? 'C')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (conversation['name'] as String?) ?? 'Conversa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: (conversation['hasUnread'] as bool?) ?? false
                      ? FontWeight.w600 
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              (conversation['time'] as String?) ?? '',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: (conversation['hasUnread'] as bool?) ?? false
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF9CA3AF),
                fontWeight: (conversation['hasUnread'] as bool?) ?? false
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
                (conversation['lastMessage'] as String?) ?? 'Nova conversa',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (conversation['hasUnread'] as bool?) ?? false
                      ? const Color(0xFF374151)
                      : const Color(0xFF6B7280),
                  fontWeight: (conversation['hasUnread'] as bool?) ?? false
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if ((conversation['hasUnread'] as bool?) ?? false && ((conversation['unreadCount'] as int?) ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ((conversation['unreadCount'] as int?) ?? 0).toString(),
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
          final conversationId = (conversation['id'] as String?) ?? '';
          final conversationType = conversation['type'] as String?;
          final isGroup = conversationType == 'group';
          
          if (isGroup) {
            Navigator.pushNamed(
              context,
              AppRoutes.home,
              arguments: {
                'chatName': (conversation['name'] as String?) ?? 'Conversa',
                'conversationId': conversationId,
                'isGroup': true,
              },
            );
          } else {
            final otherUserId = conversation['otherUserId'];
            
            if (otherUserId != null && otherUserId.toString().isNotEmpty) {
              Navigator.pushNamed(
                context,
                AppRoutes.home,
                arguments: {
                  'chatName': (conversation['name'] as String?) ?? 'Conversa',
                  'userId': otherUserId,
                },
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Não foi possível abrir a conversa - ID do usuário inválido'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onLongPress: () {
          _showDeleteDialog(conversation);
        },
      ),
    );
  }

  Color _getColorFromName(String? name) {
    final nameStr = name ?? 'Conversa';
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
    
    final hash = nameStr.hashCode.abs();
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
            'Tem certeza que deseja remover a conversa com ${(conversation['name'] as String?) ?? 'Conversa'}? Esta ação não pode ser desfeita.',
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
      
      // Atualizar a lista local e manter ordenação
      setState(() {
        _conversations.removeWhere((conv) => conv['id'] == conversation['id']);
        _filteredConversations.removeWhere((conv) => conv['id'] == conversation['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Conversa com ${(conversation['name'] as String?) ?? 'Conversa'} removida'),
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
