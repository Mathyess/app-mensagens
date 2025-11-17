import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../theme/matrix_theme.dart';
=======
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/supabase_service.dart';
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final String? recipientId;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.recipientId,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

<<<<<<< HEAD
class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _sendAnimation;
=======
class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  bool _hasText = false;
  bool _isUploading = false;
  String? _typingConversationId;
  late AnimationController _sendAnimationController;
  late AnimationController _expandAnimationController;
  late Animation<double> _sendAnimation;
  late Animation<double> _expandAnimation;
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _sendAnimation = AnimationController(
=======
    _textController.addListener(() {
      final hasTextNow = _textController.text.trim().isNotEmpty;
      if (_hasText != hasTextNow) {
        setState(() {
          _hasText = hasTextNow;
        });
        // Enviar indicador de typing
        _handleTyping(hasTextNow);
      }
    });

    _sendAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _textController.addListener(_handleTextChanged);
  }

  void _handleTyping(bool isTyping) async {
    if (widget.recipientId == null) return;
    
    try {
      // Obter conversation ID - simplificado (deveria ser passado como parâmetro)
      // Por enquanto, vamos apenas tentar enviar o typing se já tivermos o conversationId
      if (_typingConversationId != null) {
        await SupabaseService.sendTypingIndicator(_typingConversationId!, isTyping);
      }
    } catch (e) {
      // Ignorar erros de typing
      print('Erro ao enviar typing: $e');
    }
  }

  @override
  void dispose() {
    // Parar indicador de typing ao sair
    if (_typingConversationId != null) {
      SupabaseService.sendTypingIndicator(_typingConversationId!, false);
    }
    _textController.dispose();
    _focusNode.dispose();
    _sendAnimation.dispose();
    super.dispose();
  }

<<<<<<< HEAD
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
=======
  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !_isUploading) {
      // Parar indicador de typing
      if (_typingConversationId != null) {
        await SupabaseService.sendTypingIndicator(_typingConversationId!, false);
      }

      _sendAnimationController.forward().then((_) {
        _sendAnimationController.reverse();
      });
      
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
      widget.onSendMessage(text);
      _textController.clear();
      setState(() {
        _hasText = false;
      });
      _sendAnimation.reverse();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendFile(image.path, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendFile(image.path, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao tirar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndSendFile(String filePath, String fileName) async {
    if (widget.recipientId == null || widget.recipientId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID do destinatário não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Fazer upload do arquivo
      final fileUrl = await SupabaseService.uploadFile(filePath, fileName);
      
      // Enviar mensagem com o arquivo
      await SupabaseService.sendMessage(
        '',
        widget.recipientId!,
        imageUrl: fileUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo enviado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar arquivo: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
<<<<<<< HEAD
            // Campo de texto
=======
            // Botão de anexo (imagem)
            if (!_isUploading)
              IconButton(
                icon: const Icon(
                  Icons.attach_file_rounded,
                  color: Color(0xFF6366F1),
                ),
                onPressed: () {
                  _showAttachmentOptions();
                },
              ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              ),
            // Campo de texto simples
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1)),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1)),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
}
