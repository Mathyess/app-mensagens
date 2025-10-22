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

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _sendAnimationController;
  late AnimationController _expandAnimationController;
  late Animation<double> _sendAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });

    _sendAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _sendAnimationController,
      curve: Curves.easeInOut,
    ));

    _expandAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendAnimationController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _sendAnimationController.forward().then((_) {
        _sendAnimationController.reverse();
      });
      
      widget.onSendMessage(text);
      _textController.clear();
      setState(() {
        _hasText = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MatrixTheme.matrixBlack,
        border: Border(
          top: BorderSide(color: MatrixTheme.matrixGreen, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: MatrixTheme.matrixGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto Matrix
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MatrixTheme.matrixGray,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _focusNode.hasFocus 
                        ? MatrixTheme.matrixGreen
                        : MatrixTheme.matrixDimGreen,
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: MatrixTheme.matrixGreen,
                    fontFamily: 'Courier',
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: '> Digite_sua_mensagem...',
                    hintStyle: TextStyle(
                      color: MatrixTheme.matrixDimGreen,
                      fontFamily: 'Courier',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botão de enviar Matrix
            AnimatedBuilder(
              animation: _sendAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendAnimation.value,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hasText ? MatrixTheme.matrixGreen : MatrixTheme.matrixGray,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _hasText ? MatrixTheme.matrixGreen : MatrixTheme.matrixDimGreen,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.play_arrow,
                        color: _hasText ? MatrixTheme.matrixBlack : MatrixTheme.matrixDimGreen,
                        size: 20,
                      ),
                      onPressed: _hasText ? _sendMessage : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
