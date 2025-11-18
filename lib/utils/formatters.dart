class Formatters {
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'ano' : 'anos'} atrás';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mês' : 'meses'} atrás';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
  
  static String formatTime(DateTime dateTime) {
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  static String formatFullDate(DateTime dateTime) {
    final localDate = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    
    final weekdays = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado'
    ];
    
    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    
    final weekday = weekdays[localDate.weekday % 7];
    final month = months[localDate.month - 1];
    
    return '$weekday, ${localDate.day} de $month de ${localDate.year}';
  }
  
  static String formatDateSeparator(DateTime dateTime) {
    final localDate = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localDate.year, localDate.month, localDate.day);
    
    if (messageDate == today) {
      return 'HOJE';
    } else if (messageDate == yesterday) {
      return 'ONTEM';
    } else if (now.difference(messageDate).inDays < 7) {
      final weekdays = [
        'Domingo',
        'Segunda-feira',
        'Terça-feira',
        'Quarta-feira',
        'Quinta-feira',
        'Sexta-feira',
        'Sábado'
      ];
      return weekdays[localDate.weekday % 7].toUpperCase();
    } else {
      return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
    }
  }
  
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  static String formatParticipantCount(int count) {
    if (count == 0) {
      return 'Nenhum participante';
    } else if (count == 1) {
      return '1 participante';
    } else {
      return '$count participantes';
    }
  }
  
  static String formatUnreadCount(int count) {
    if (count > 99) {
      return '99+';
    } else {
      return count.toString();
    }
  }
}
