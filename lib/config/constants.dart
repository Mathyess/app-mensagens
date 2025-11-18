/// Constantes globais do aplicativo
class AppConstants {
  // Limites
  static const int maxFileSize = 20 * 1024 * 1024; // 20 MB em bytes
  static const int messageEditTimeLimit = 15; // minutos
  static const int messageRetentionDays = 365; // 12 meses
  
  // Timeouts
  static const int messageDeliveryTimeout = 2; // segundos
  static const int typingIndicatorTimeout = 3; // segundos
  
  // Cache
  static const int cacheExpirationHours = 24;
  static const int maxCachedMessages = 1000;
  
  // UI
  static const double maxMessageWidth = 0.7; // 70% da largura da tela
  static const int maxMessageLines = 10;
  
  // Formatos de arquivo suportados
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  
  static const List<String> supportedFileFormats = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'xls',
    'xlsx'
  ];
  
  // Mensagens de erro
  static const String errorNetwork = 'Erro de conexão. Verifique sua internet.';
  static const String errorAuth = 'Erro de autenticação. Faça login novamente.';
  static const String errorGeneric = 'Ocorreu um erro. Tente novamente.';
  static const String errorFileSize = 'Arquivo muito grande. Tamanho máximo: 20MB';
  static const String errorFileFormat = 'Formato de arquivo não suportado.';
  
  // Mensagens de sucesso
  static const String successMessageSent = 'Mensagem enviada!';
  static const String successFileSent = 'Arquivo enviado com sucesso!';
  static const String successProfileUpdated = 'Perfil atualizado!';
  static const String successGroupCreated = 'Grupo criado com sucesso!';
}
