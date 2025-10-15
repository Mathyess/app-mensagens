import 'package:flutter/material.dart';
import '../routes.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _searchQuery = '';
  bool _showEmailInput = false;

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAvailableUsers() {
    // Mock de usuários disponíveis - em produção viria do Supabase
    final allUsers = [
      {
        'id': 'ana_silva',
        'name': 'Ana Silva',
        'email': 'ana@email.com',
        'avatar': null,
      },
      {
        'id': 'carlos_santos',
        'name': 'Carlos Santos',
        'email': 'carlos@email.com',
        'avatar': null,
      },
      {
        'id': 'maria_oliveira',
        'name': 'Maria Oliveira',
        'email': 'maria@email.com',
        'avatar': null,
      },
      {
        'id': 'joao_costa',
        'name': 'João Costa',
        'email': 'joao@email.com',
        'avatar': null,
      },
      {
        'id': 'pedro_lima',
        'name': 'Pedro Lima',
        'email': 'pedro@email.com',
        'avatar': null,
      },
    ];

    if (_searchQuery.isEmpty) {
      return allUsers;
    }

    return allUsers.where((user) {
      return (user['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (user['email'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _startConversation(Map<String, dynamic> user) {
    // Em produção, criaria uma nova conversa no Supabase
    Navigator.pushNamed(
      context,
      AppRoutes.home,
      arguments: {
        'chatName': user['name'],
        'userId': user['id'],
      },
    );
  }

  void _addUserByEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite um email válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite um email válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simular busca de usuário por email
    final user = _findUserByEmail(email);
    if (user != null) {
      _startConversation(user);
    } else {
      // Se não encontrar, criar um usuário temporário
      final newUser = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'name': email.split('@')[0], // Usar parte antes do @ como nome
        'email': email,
        'avatar': null,
      };
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário não encontrado. Iniciando conversa com $email'),
          backgroundColor: Colors.orange,
        ),
      );
      
      _startConversation(newUser);
    }

    // Limpar e esconder o campo de email
    _emailController.clear();
    setState(() {
      _showEmailInput = false;
    });
  }

  Map<String, dynamic>? _findUserByEmail(String email) {
    final allUsers = _getAvailableUsers();
    try {
      return allUsers.firstWhere((user) => 
        (user['email'] as String).toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _getAvailableUsers();

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
          'Nova Conversa',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showEmailInput ? Icons.close : Icons.person_add_rounded,
              color: const Color(0xFF374151),
            ),
            onPressed: () {
              setState(() {
                _showEmailInput = !_showEmailInput;
                if (!_showEmailInput) {
                  _emailController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de busca ou email
          Container(
            padding: const EdgeInsets.all(16),
            child: _showEmailInput ? _buildEmailInput() : _buildSearchInput(),
          ),
          const Divider(height: 1),
          // Lista de usuários
          Expanded(
            child: _showEmailInput
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Adicionar por Email',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Digite o email do usuário acima',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                : users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum usuário encontrado',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tente buscar por nome ou email',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserTile(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
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
                    _getColorFromName(user['name']),
                    _getColorFromName(user['name']).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
              child: Text(
                (user['name'] as String)[0].toUpperCase(),
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
        title: Text(
          user['name'] as String,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          user['email'] as String,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Conversar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _startConversation(user),
      ),
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar pessoas...',
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFF9CA3AF),
          size: 20,
        ),
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
    );
  }

  Widget _buildEmailInput() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Digite o email do usuário...',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(
              Icons.email_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addUserByEmail,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Adicionar por Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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
}
