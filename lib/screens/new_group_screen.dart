import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      // Get all users except the current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;
      
      final users = await GroupService.searchUsers('');
      setState(() {
        _allUsers = users.where((user) => user['id'] != currentUser.id).toList();
        _searchResults = List.from(_allUsers);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar usuários: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allUsers;
      });
    } else {
      setState(() {
        _searchResults = _allUsers.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      });
    }
  }

  void _toggleUserSelection(Map<String, dynamic> user) {
    setState(() {
      final userId = user['id'] as String;
      final index = _selectedUsers.indexWhere((u) => u['id'] == userId);
      if (index >= 0) {
        _selectedUsers.removeAt(index);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  bool _isUserSelected(String userId) {
    return _selectedUsers.any((u) => u['id'] == userId);
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para o grupo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um participante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final participantIds = _selectedUsers.map((u) => u['id'] as String).toList();
      final conversationId = await GroupService.createGroup(
        _nameController.text.trim(),
        participantIds,
        isPublic: _isPublic,
      );

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.home,
          arguments: {
            'chatName': _nameController.text.trim(),
            'conversationId': conversationId,
            'isGroup': true,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar grupo: ${e.toString().replaceFirst('Exception: ', '')}'),
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
          'Novo Grupo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text(
                'Criar',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do grupo',
                    hintText: 'Digite o nome do grupo',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF6366F1),
                    ),
                    const Expanded(
                      child: Text(
                        'Grupo público (qualquer pessoa pode encontrar e entrar)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar pessoas...',
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
              ],
            ),
          ),
          if (_selectedUsers.isNotEmpty) ...[
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          (user['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      label: Text(user['name'] ?? 'Usuário'),
                      onDeleted: () => _toggleUserSelection(user),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum usuário encontrado',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final userId = user['id'] as String;
                      final isSelected = _isUserSelected(userId);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6366F1),
                          child: Text(
                            (user['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['name'] ?? 'Usuário'),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF6366F1),
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                color: Colors.grey,
                              ),
                        onTap: () => _toggleUserSelection(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}





