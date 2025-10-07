import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _readReceipts = true;
  bool _onlineStatus = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
        elevation: 1,
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Conta', isDark),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'Editar nome e foto',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
            isDark: isDark,
          ),
          _buildListTile(
            icon: Icons.key_outlined,
            title: 'Privacidade',
            subtitle: 'Configurações de privacidade',
            onTap: () {
              _showPrivacySettings(context, isDark);
            },
            isDark: isDark,
          ),
          _buildListTile(
            icon: Icons.security_outlined,
            title: 'Segurança',
            subtitle: 'Autenticação e segurança',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Appearance Section
          _buildSectionHeader('Aparência', isDark),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Modo Escuro',
            subtitle: isDark ? 'Ativado' : 'Desativado',
            value: isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            isDark: isDark,
          ),
          _buildListTile(
            icon: Icons.wallpaper_outlined,
            title: 'Papel de Parede',
            subtitle: 'Personalizar fundo do chat',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Notifications Section
          _buildSectionHeader('Notificações', isDark),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: _notificationsEnabled ? 'Ativadas' : 'Desativadas',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            isDark: isDark,
          ),
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Sons',
            subtitle: _soundEnabled ? 'Ativado' : 'Desativado',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
            isDark: isDark,
          ),
          _buildSwitchTile(
            icon: Icons.vibration_outlined,
            title: 'Vibração',
            subtitle: _vibrationEnabled ? 'Ativada' : 'Desativada',
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Data and Storage Section
          _buildSectionHeader('Dados e Armazenamento', isDark),
          _buildListTile(
            icon: Icons.storage_outlined,
            title: 'Uso de Dados',
            subtitle: 'Gerenciar uso de dados',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
            isDark: isDark,
          ),
          _buildListTile(
            icon: Icons.download_outlined,
            title: 'Download Automático',
            subtitle: 'Configurar downloads',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Help Section
          _buildSectionHeader('Ajuda', isDark),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Central de Ajuda',
            subtitle: 'Perguntas frequentes',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.help);
            },
            isDark: isDark,
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Sobre',
            subtitle: 'Informações do app',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.about);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF00A884) : const Color(0xFF075E54),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[200] : Colors.grey[900],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[200] : Colors.grey[900],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: isDark ? const Color(0xFF00A884) : const Color(0xFF075E54),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  void _showPrivacySettings(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações de Privacidade',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: Text('Confirmação de Leitura'),
                subtitle: Text('Enviar e receber confirmações'),
                value: _readReceipts,
                onChanged: (value) {
                  setModalState(() {
                    setState(() {
                      _readReceipts = value;
                    });
                  });
                },
                activeColor: isDark
                    ? const Color(0xFF00A884)
                    : const Color(0xFF075E54),
              ),
              SwitchListTile(
                title: Text('Status Online'),
                subtitle: Text('Mostrar quando estou online'),
                value: _onlineStatus,
                onChanged: (value) {
                  setModalState(() {
                    setState(() {
                      _onlineStatus = value;
                    });
                  });
                },
                activeColor: isDark
                    ? const Color(0xFF00A884)
                    : const Color(0xFF075E54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF00A884)
                        : const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
