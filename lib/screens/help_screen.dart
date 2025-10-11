import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Central de Ajuda'),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHelpSection(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Como enviar mensagens?',
            description:
                'Digite sua mensagem no campo de texto na parte inferior da tela e toque no botão de enviar. Suas mensagens aparecerão em verde à direita.',
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            context,
            icon: Icons.star_outline,
            title: 'Como favoritar mensagens?',
            description:
                'Pressione e segure qualquer mensagem para abrir o menu de opções. Selecione "Adicionar aos favoritos" para salvar mensagens importantes.',
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            context,
            icon: Icons.archive_outlined,
            title: 'Como arquivar mensagens?',
            description:
                'Pressione e segure uma mensagem e selecione "Arquivar" no menu. Mensagens arquivadas podem ser acessadas através do menu lateral.',
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            context,
            icon: Icons.person_outline,
            title: 'Como editar meu perfil?',
            description:
                'Toque no seu avatar no menu lateral ou acesse Configurações > Perfil para editar seu nome e foto de perfil.',
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            context,
            icon: Icons.notifications_outlined,
            title: 'Como gerenciar notificações?',
            description:
                'Acesse Configurações > Notificações para ativar ou desativar notificações, sons e vibrações.',
          ),
          const SizedBox(height: 16),
          _buildHelpSection(
            context,
            icon: Icons.security_outlined,
            title: 'Meus dados estão seguros?',
            description:
                'Sim! Utilizamos criptografia de ponta a ponta e políticas de segurança rigorosas para proteger suas informações e mensagens.',
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 48,
                    color: const Color(0xFF075E54),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ainda precisa de ajuda?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre em contato conosco através do email:\nsuporte@appmensagens.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: const Color(0xFF075E54),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}