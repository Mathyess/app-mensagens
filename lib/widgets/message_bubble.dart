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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: _showMessageOptions,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6))
                      : (isDark ? const Color(0xFF1F2C34) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(widget.isMe ? 12 : 0),
                    bottomRight: Radius.circular(widget.isMe ? 0 : 12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          widget.message.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _getColorFromName(widget.message.senderName),
                          ),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (widget.message.isFavorite) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(widget.message.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: Colors.blue[400],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isMe) const SizedBox(width: 8),
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
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
