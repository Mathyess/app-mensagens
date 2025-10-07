import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../routes.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _notificationsEnabled = true;

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
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
        child: Column(
          children: [
            // User Profile Header
            FutureBuilder(
              future: SupabaseService.getCurrentUserProfile(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final userName = user?.name ?? 'Usuário';
                final userEmail = user?.email ?? '';
                final avatarUrl = user?.avatarUrl;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF00A884),
                              const Color(0xFF00796B),
                            ]
                          : [
                              const Color(0xFF075E54),
                              const Color(0xFF128C7E),
                            ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed(AppRoutes.profile);
                        },
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: isDark
                                      ? const Color(0xFF00A884)
                                      : const Color(0xFF075E54),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.person,
                    title: 'Meu Perfil',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.profile);
                    },
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Nova Conversa',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.group,
                    title: 'Novo Grupo',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.archive_outlined,
                    title: 'Conversas Arquivadas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.archived);
                    },
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.star_outline,
                    title: 'Mensagens Favoritas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.favorites);
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.settings);
                    },
                    isDark: isDark,
                  ),
                  _buildSwitchMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Modo Escuro',
                    value: isDark,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    isDark: isDark,
                  ),
                  _buildSwitchMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Notificações ativadas'
                                : 'Notificações desativadas',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Ajuda',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.help);
                    },
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'Sobre',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.about);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: _buildMenuItem(
                icon: Icons.logout,
                title: 'Sair',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showLogoutConfirmation(context);
                  if (confirm == true) {
                    await _handleLogout();
                  }
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? Colors.grey[400] : Colors.grey[700]),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? (isDark ? Colors.grey[200] : Colors.grey[800]),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.grey[200] : Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: isDark ? const Color(0xFF00A884) : const Color(0xFF075E54),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair do aplicativo'),
        content: Text('Tem certeza que deseja sair?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {}

  Widget _buildHelpItem(String text) {
    return Container();
  }

  void _showAboutDialog(BuildContext context) {}
}
