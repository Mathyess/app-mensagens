import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';
import '../routes.dart';
import '../theme/matrix_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  AppUser? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile?.name ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Erro ao carregar perfil: ${e.toString()}');
      }
    }
  }

<<<<<<< HEAD
=======
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAvatar(image.path);
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: ${e.toString()}');
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAvatar(image.path);
      }
    } catch (e) {
      _showError('Erro ao tirar foto: ${e.toString()}');
    }
  }
  
  Future<void> _uploadAvatar(String filePath) async {
    if (filePath.isEmpty) return;
    
    try {
      setState(() {
        _isLoading = true;
        _imageFile = File(filePath);
      });
      
      final fileName = 'avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final avatarUrl = await SupabaseService.uploadFile(filePath, fileName);
      
      await SupabaseService.updateProfile(avatarUrl: avatarUrl);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_userProfile != null) {
            _userProfile = _userProfile!.copyWith(avatarUrl: avatarUrl);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Avatar atualizado com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Erro ao fazer upload: ${e.toString()}');
      }
    }
  }

>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Implementar atualização de nome no SupabaseService
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nome atualizado com sucesso!'),
            backgroundColor: MatrixTheme.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao salvar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MatrixTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Sair da conta',
          style: TextStyle(color: MatrixTheme.textPrimary),
        ),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: TextStyle(color: MatrixTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: MatrixTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } catch (e) {
        _showError('Erro ao sair: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _showImageSourceDialog() {
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
            if (_userProfile?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remover avatar', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    setState(() {
                      _isLoading = true;
                    });
                    await SupabaseService.updateProfile(avatarUrl: null);
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _userProfile = _userProfile?.copyWith(avatarUrl: null);
                        _imageFile = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Text('Avatar removido com sucesso!'),
                            ],
                          ),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                      _showError('Erro ao remover avatar: ${e.toString()}');
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MatrixTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: MatrixTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MatrixTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: MatrixTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(MatrixTheme.primaryPurple),
              ),
            )
          : SingleChildScrollView(
<<<<<<< HEAD
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar grande
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            MatrixTheme.primaryPurple,
                            MatrixTheme.lightPurple,
=======
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF075E54),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_userProfile?.avatarUrl != null
                                      ? NetworkImage(_userProfile!.avatarUrl!)
                                      : null) as ImageProvider?,
                              child: _imageFile == null && _userProfile?.avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: const Color(0xFF075E54),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  onPressed: () => _showImageSourceDialog(),
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ),
>>>>>>> 4b00f9be3bc32c16c5cfc51e22d379bba8d48a59
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: MatrixTheme.primaryPurple.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _userProfile?.name.isNotEmpty == true
                              ? _userProfile!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Email
                    Text(
                      _userProfile?.email ?? '',
                      style: const TextStyle(
                        color: MatrixTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Campo de nome
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: MatrixTheme.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        labelStyle: const TextStyle(
                          color: MatrixTheme.textSecondary,
                          fontSize: 14,
                        ),
                        hintText: 'Digite seu nome',
                        hintStyle: const TextStyle(color: MatrixTheme.textTertiary),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: MatrixTheme.primaryPurple,
                        ),
                        filled: true,
                        fillColor: MatrixTheme.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: MatrixTheme.primaryPurple,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Botão salvar nome
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MatrixTheme.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Salvar Alterações',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Botão sair
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Sair da Conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
