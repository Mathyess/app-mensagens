import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/supabase_service.dart';
import '../theme/matrix_theme.dart';

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
                border: Border.all(color: MatrixTheme.matrixGreen, width: 2),
                color: MatrixTheme.matrixBlack,
              ),
              child: Center(
                child: Text(
                  widget.message.senderName.isNotEmpty 
                      ? widget.message.senderName[0].toUpperCase() 
                      : '?',
                  style: const TextStyle(
                    color: MatrixTheme.matrixGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
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
                  color: widget.isMe ? MatrixTheme.matrixDarkGreen : MatrixTheme.matrixGray,
                  border: Border.all(
                    color: widget.isMe ? MatrixTheme.matrixGreen : MatrixTheme.matrixDimGreen,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(2),
                    topRight: const Radius.circular(2),
                    bottomLeft: Radius.circular(widget.isMe ? 2 : 0),
                    bottomRight: Radius.circular(widget.isMe ? 0 : 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MatrixTheme.matrixGreen.withOpacity(0.2),
                      blurRadius: 8,
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
                            '> ${widget.message.senderName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: MatrixTheme.matrixLightGreen,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.message.content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: MatrixTheme.matrixGreen,
                                height: 1.4,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                          if (widget.message.isFavorite) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: MatrixTheme.matrixLightGreen,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '[${_formatTime(widget.message.createdAt)}]',
                            style: const TextStyle(
                              fontSize: 10,
                              color: MatrixTheme.matrixDimGreen,
                              fontFamily: 'Courier',
                            ),
                          ),
                          if (widget.isMe) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '✓✓',
                              style: TextStyle(
                                fontSize: 12,
                                color: MatrixTheme.matrixGreen,
                                fontFamily: 'Courier',
                              ),
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
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
