import 'package:flutter/material.dart';
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
          'Configurações',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionHeader('Conta'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Perfil',
            subtitle: 'Editar nome e foto',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
          ),
          _buildListTile(
            icon: Icons.key_outlined,
            title: 'Privacidade',
            subtitle: 'Configurações de privacidade',
            onTap: () {
              _showPrivacySettings(context);
            },
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
          ),
          _buildDivider(),

          _buildSectionHeader('Notificações'),
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
          ),
          _buildDivider(),

          _buildSectionHeader('Dados e Armazenamento'),
          _buildListTile(
            icon: Icons.storage_outlined,
            title: 'Uso de Dados',
            subtitle: 'Gerenciar uso de dados',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Funcionalidade em desenvolvimento')),
              );
            },
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
          ),
          _buildDivider(),

          _buildSectionHeader('Ajuda'),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Central de Ajuda',
            subtitle: 'Perguntas frequentes',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.help);
            },
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Sobre',
            subtitle: 'Informações do app',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.about);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[900],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
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
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[900],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
    );
  }

  void _showPrivacySettings(BuildContext context) {
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
                activeColor: const Color(0xFF6366F1),
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
                activeColor: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
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