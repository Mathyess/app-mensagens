class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu email';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, insira um email válido';
    }
    
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira sua senha';
    }
    
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    
    return null;
  }
  
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu nome';
    }
    
    if (value.length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres';
    }
    
    if (value.length > 50) {
      return 'O nome deve ter no máximo 50 caracteres';
    }
    
    return null;
  }
  
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o nome do grupo';
    }
    
    if (value.length < 3) {
      return 'O nome do grupo deve ter pelo menos 3 caracteres';
    }
    
    if (value.length > 100) {
      return 'O nome do grupo deve ter no máximo 100 caracteres';
    }
    
    return null;
  }
  
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'A mensagem não pode estar vazia';
    }
    
    if (value.length > 5000) {
      return 'A mensagem é muito longa (máximo 5000 caracteres)';
    }
    
    return null;
  }
  
  static String? validateFileSize(int bytes) {
    const maxSize = 20 * 1024 * 1024; // 20 MB
    
    if (bytes > maxSize) {
      return 'Arquivo muito grande. Tamanho máximo: 20MB';
    }
    
    return null;
  }
  
  static String? validateFileFormat(String extension, List<String> allowedFormats) {
    if (!allowedFormats.contains(extension.toLowerCase())) {
      return 'Formato de arquivo não suportado';
    }
    
    return null;
  }
}
