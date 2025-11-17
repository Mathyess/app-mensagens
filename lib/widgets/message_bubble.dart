import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/supabase_service.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onFavoriteToggled;
  final VoidCallback? onArchivedToggled;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onFavoriteToggled,
    this.onArchivedToggled,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isTogglingFavorite = false;

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      await SupabaseService.toggleFavorite(
        widget.message.id,
        widget.message.isFavorite,
      );
      
      widget.onFavoriteToggled?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.message.isFavorite
                  ? 'Removido dos favoritos'
                  : 'Adicionado aos favoritos',
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao favoritar mensagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleArchived() async {
    try {
      await SupabaseService.toggleArchived(
        widget.message.id,
        widget.message.isArchived,
      );
      
      widget.onArchivedToggled?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.message.isArchived
                  ? 'Mensagem desarquivada'
                  : 'Mensagem arquivada',
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao arquivar mensagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                widget.message.isFavorite ? Icons.star : Icons.star_outline,
                color: widget.message.isFavorite ? Colors.amber : null,
              ),
              title: Text(
                widget.message.isFavorite
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite();
              },
            ),
            ListTile(
              leading: Icon(
                widget.message.isArchived
                    ? Icons.unarchive
                    : Icons.archive_outlined,
              ),
              title: Text(
                widget.message.isArchived ? 'Desarquivar' : 'Arquivar',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleArchived();
              },
            ),
            if (widget.isMe && !widget.message.isDeleted) ...[
              if (widget.message.canBeEdited())
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Deletar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage();
                },
              ),
            ],
            if (!widget.message.isDeleted)
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: const Text('Adicionar reação'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _getColorFromName(widget.message.senderName),
                    _getColorFromName(widget.message.senderName).withOpacity(0.7),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  widget.message.senderName.isNotEmpty 
                      ? widget.message.senderName[0].toUpperCase() 
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: _showMessageOptions,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isMe
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                    bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isMe 
                          ? const Color(0xFF6366F1).withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: widget.isMe ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            widget.message.senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _getColorFromName(widget.message.senderName),
                            ),
                          ),
                        ),
                      // Mostrar imagem se existir
                      if (widget.message.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.message.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: const Icon(Icons.broken_image, size: 48),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.message.isDeleted 
                                  ? 'Esta mensagem foi deletada'
                                  : widget.message.content,
                              style: TextStyle(
                                fontSize: 15,
                                color: widget.isMe 
                                    ? (widget.message.isDeleted 
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.white)
                                    : (widget.message.isDeleted
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF374151)),
                                height: 1.4,
                                fontStyle: widget.message.isDeleted 
                                    ? FontStyle.italic 
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                          if (widget.message.isFavorite) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.amber,
                            ),
                          ],
                        ],
                      ),
                      // Mostrar reações se existirem
                      if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.message.reactions!.entries.map((entry) {
                            final emoji = entry.key;
                            final userIds = entry.value;
                            final currentUserId = SupabaseService.currentUser?.id;
                            final hasReacted = currentUserId != null && userIds.contains(currentUserId);
                            
                            return GestureDetector(
                              onTap: () => _toggleReaction(emoji),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasReacted 
                                      ? const Color(0xFF6366F1).withOpacity(0.2)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: hasReacted
                                      ? Border.all(color: const Color(0xFF6366F1), width: 1)
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(emoji, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      userIds.length.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: hasReacted 
                                            ? const Color(0xFF6366F1)
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(widget.message.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isMe 
                                  ? Colors.white.withOpacity(0.7)
                                  : const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.message.isEdited && !widget.message.isDeleted) ...[
                            const SizedBox(width: 4),
                            Text(
                              'editado',
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isMe
                                    ? Colors.white.withOpacity(0.6)
                                    : const Color(0xFF9CA3AF),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (widget.isMe) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.isMe) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFF00BFA5),
      const Color(0xFF00ACC1),
      const Color(0xFF5E35B1),
      const Color(0xFFD81B60),
      const Color(0xFFE53935),
      const Color(0xFFF4511E),
      const Color(0xFFFB8C00),
      const Color(0xFF6D4C41),
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    // Garantir que está no fuso horário local
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _toggleReaction(String emoji) async {
    try {
      await SupabaseService.toggleReaction(widget.message.id, emoji);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar reação: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReactionPicker() {
    final emojis = ['👍', '❤️', '😄', '😮', '😢', '🙏'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _toggleReaction(emoji);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editMessage() {
    final controller = TextEditingController(text: widget.message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensagem'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                try {
                  await SupabaseService.editMessage(widget.message.id, newContent);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mensagem editada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao editar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar mensagem'),
        content: const Text('Tem certeza que deseja deletar esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.deleteMessage(widget.message.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensagem deletada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao deletar: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }
}
