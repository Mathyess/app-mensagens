import 'package:flutter/material.dart';
import '../theme/matrix_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;

  const MessageInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _sendAnimation;

  @override
  void initState() {
    super.initState();
    _sendAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendAnimation.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
      if (hasText) {
        _sendAnimation.forward();
      } else {
        _sendAnimation.reverse();
      }
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
      setState(() {
        _hasText = false;
      });
      _sendAnimation.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MatrixTheme.darkBackground,
        border: Border(
          top: BorderSide(
            color: MatrixTheme.cardBackground,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MatrixTheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: MatrixTheme.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          hintStyle: TextStyle(
                            color: MatrixTheme.textTertiary,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão de enviar
            AnimatedScale(
              scale: _hasText ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hasText
                        ? [
                            MatrixTheme.primaryPurple,
                            MatrixTheme.darkPurple,
                          ]
                        : [
                            MatrixTheme.cardBackground,
                            MatrixTheme.cardBackground,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: MatrixTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  icon: Icon(
                    _hasText ? Icons.send_rounded : Icons.mic_rounded,
                    color: _hasText ? Colors.white : MatrixTheme.textTertiary,
                    size: 22,
                  ),
                  onPressed: _hasText ? _sendMessage : () {
                    // Implementar gravação de áudio
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
