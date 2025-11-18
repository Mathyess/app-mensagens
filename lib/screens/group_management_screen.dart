import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';
import '../routes.dart';

class GroupManagementScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final bool isAdmin;

  const GroupManagementScreen({
    Key? key,
    required this.conversationId,
    required this.groupName,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isPublic = false;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _participants = [];
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final _currentUser = SupabaseService.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.groupName;
    _isAdmin = widget.isAdmin;
    _loadGroupData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load group info
      final groupData = await SupabaseService.getGroupInfo(widget.conversationId);
      setState(() {
        _isPublic = groupData['is_public'] ?? false;
        _participants = List<Map<String, dynamic>>.from(groupData['participants'] ?? []);
      });
      
      // Check if current user is admin
      if (_currentUser != null) {
        final isAdmin = _participants.any((p) => 
          p['user_id'] == _currentUser!.id && p['is_admin'] == true);
        setState(() => _isAdmin = isAdmin);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados do grupo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateGroupInfo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      
      await SupabaseService.updateGroupInfo(
        widget.conversationId,
        name: _nameController.text.trim(),
        isPublic: _isPublic,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações do grupo atualizadas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar grupo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Participantes'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar usuários',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _searchUsers(value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(child: Text('Nenhum usuário encontrado'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              final isParticipant = _participants.any((p) => p['user_id'] == user['id']);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user['avatar_url'] != null
                                      ? NetworkImage(user['avatar_url'])
                                      : null,
                                  child: user['avatar_url'] == null
                                      ? Text(user['name'][0].toUpperCase())
                                      : null,
                                ),
                                title: Text(user['name'] ?? 'Usuário'),
                                subtitle: Text(user['email'] ?? ''),
                                trailing: isParticipant
                                    ? const Text('Já está no grupo')
                                    : IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () => _addParticipant(user['id']),
                                      ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await SupabaseService.searchUsers(query);
      setState(() {
        _searchResults = results.where((user) {
          return !_participants.any((p) => p['user_id'] == user['id']);
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar usuários: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _addParticipant(String userId) async {
    try {
      await SupabaseService.addGroupParticipants(
        widget.conversationId,
        [userId],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participante adicionado com sucesso!')),
        );
        await _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar participante: $e')),
        );
      }
    }
  }

  Future<void> _removeParticipant(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover participante'),
        content: const Text('Tem certeza que deseja remover este participante do grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.removeGroupParticipant(
        widget.conversationId,
        userId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participante removido com sucesso!')),
        );
        await _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover participante: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do grupo'),
        content: const Text('Tem certeza que deseja sair deste grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.leaveGroup(widget.conversationId);
      
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair do grupo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Grupo'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateGroupInfo,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Group Info Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações do Grupo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Grupo',
                              border: OutlineInputBorder(),
                            ),
                            enabled: _isAdmin,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, insira um nome para o grupo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Grupo Público'),
                            subtitle: const Text(
                              'Grupos públicos podem ser encontrados por outros usuários',
                            ),
                            value: _isPublic,
                            onChanged: _isAdmin
                                ? (value) => setState(() => _isPublic = value)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Participants Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Participantes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isAdmin)
                                TextButton.icon(
                                  onPressed: _showAddParticipantsDialog,
                                  icon: const Icon(Icons.person_add, size: 20),
                                  label: const Text('Adicionar'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._buildParticipantsList(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Danger Zone
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zona de Perigo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Leave Group Button
                          ListTile(
                            leading: const Icon(Icons.exit_to_app, color: Colors.red),
                            title: const Text(
                              'Sair do Grupo',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: _leaveGroup,
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          // Delete Group Button (Admin only)
                          if (_isAdmin) ...[  
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.delete_forever, color: Colors.red),
                              title: const Text(
                                'Excluir Grupo',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                // TODO: Implement delete group functionality
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildParticipantsList() {
    return _participants.map((participant) {
      final isCurrentUser = participant['user_id'] == _currentUser?.id;
      final isAdmin = participant['is_admin'] == true;
      
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: participant['avatar_url'] != null
              ? NetworkImage(participant['avatar_url'])
              : null,
          child: participant['avatar_url'] == null
              ? Text(participant['name'][0].toUpperCase())
              : null,
        ),
        title: Text(participant['name'] ?? 'Usuário'),
        subtitle: isAdmin ? const Text('Administrador') : null,
        trailing: isCurrentUser
            ? const Text('Você')
            : _isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.star, color: Colors.amber),
                          onPressed: () {
                            // TODO: Implement remove admin
                          },
                          tooltip: 'Remover administrador',
                        ),
                      IconButton(
                        icon: const Icon(Icons.person_remove, color: Colors.red),
                        onPressed: () => _removeParticipant(participant['user_id']),
                        tooltip: 'Remover do grupo',
                      ),
                    ],
                  )
                : null,
      );
    }).toList();
  }
}
