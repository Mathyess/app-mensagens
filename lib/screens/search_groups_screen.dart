import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../routes.dart';

class SearchGroupsScreen extends StatefulWidget {
  const SearchGroupsScreen({super.key});

  @override
  State<SearchGroupsScreen> createState() => _SearchGroupsScreenState();
}

class _SearchGroupsScreenState extends State<SearchGroupsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await GroupService.searchPublicGroups(_searchController.text.trim());
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar grupos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _joinGroup(String conversationId, String groupName) async {
    try {
      await GroupService.addGroupParticipants(conversationId, [GroupService._client.auth.currentUser!.id]);
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(
          AppRoutes.home,
          arguments: {
            'chatName': groupName,
            'conversationId': conversationId,
            'isGroup': true,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Text(
          'Buscar Grupos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar grupos públicos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_groups.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum grupo encontrado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8B5CF6),
                      child: const Icon(Icons.group, color: Colors.white),
                    ),
                    title: Text(group['name'] ?? 'Grupo'),
                    subtitle: Text(
                      '${group['participant_count'] ?? 0} membros • ${group['is_public'] ? 'Público' : 'Privado'}',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: group['is_member'] == true
                        ? const Text('Já é membro', style: TextStyle(color: Colors.green))
                        : ElevatedButton(
                            onPressed: () => _joinGroup(
                              group['id'] as String,
                              group['name'] as String,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Entrar'),
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}





