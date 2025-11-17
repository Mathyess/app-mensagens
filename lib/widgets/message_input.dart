import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/supabase_service.dart';

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

  @override
  void initState() {
    super.initState();
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
    _sendAnimationController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

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
      
      widget.onSendMessage(text);
      _textController.clear();
      setState(() {
        _hasText = false;
      });
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
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus 
                        ? const Color(0xFF6366F1) 
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Mensagem',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
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
            // Botão de enviar simples
            AnimatedBuilder(
              animation: _sendAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendAnimation.value,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hasText ? const Color(0xFF6366F1) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: _hasText ? Colors.white : Colors.grey.shade500,
                        size: 18,
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
