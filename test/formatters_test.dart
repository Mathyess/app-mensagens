import 'package:flutter_test/flutter_test.dart';
import 'package:app_mensagens/utils/formatters.dart';

void main() {
  group('Formatters', () {
    group('formatRelativeTime', () {
      test('deve formatar tempo recente', () {
        final now = DateTime.now();
        expect(Formatters.formatRelativeTime(now), 'Agora');
        
        final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
        expect(Formatters.formatRelativeTime(oneMinuteAgo), '1min atrás');
        
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        expect(Formatters.formatRelativeTime(oneHourAgo), '1h atrás');
      });

      test('deve formatar dias', () {
        final now = DateTime.now();
        final oneDayAgo = now.subtract(const Duration(days: 1));
        expect(Formatters.formatRelativeTime(oneDayAgo), '1 dia atrás');
        
        final twoDaysAgo = now.subtract(const Duration(days: 2));
        expect(Formatters.formatRelativeTime(twoDaysAgo), '2 dias atrás');
      });
    });

    group('formatTime', () {
      test('deve formatar hora corretamente', () {
        final dateTime = DateTime(2025, 11, 17, 14, 30);
        expect(Formatters.formatTime(dateTime), '14:30');
      });

      test('deve adicionar zero à esquerda', () {
        final dateTime = DateTime(2025, 11, 17, 9, 5);
        expect(Formatters.formatTime(dateTime), '09:05');
      });
    });

    group('formatDateSeparator', () {
      test('deve retornar HOJE para data de hoje', () {
        final today = DateTime.now();
        expect(Formatters.formatDateSeparator(today), 'HOJE');
      });

      test('deve retornar ONTEM para data de ontem', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(Formatters.formatDateSeparator(yesterday), 'ONTEM');
      });
    });

    group('formatFileSize', () {
      test('deve formatar bytes', () {
        expect(Formatters.formatFileSize(500), '500 B');
      });

      test('deve formatar kilobytes', () {
        expect(Formatters.formatFileSize(1024), '1.0 KB');
        expect(Formatters.formatFileSize(2048), '2.0 KB');
      });

      test('deve formatar megabytes', () {
        expect(Formatters.formatFileSize(1024 * 1024), '1.0 MB');
        expect(Formatters.formatFileSize(5 * 1024 * 1024), '5.0 MB');
      });
    });

    group('formatParticipantCount', () {
      test('deve formatar contagem de participantes', () {
        expect(Formatters.formatParticipantCount(0), 'Nenhum participante');
        expect(Formatters.formatParticipantCount(1), '1 participante');
        expect(Formatters.formatParticipantCount(5), '5 participantes');
      });
    });

    group('formatUnreadCount', () {
      test('deve formatar contagem de não lidas', () {
        expect(Formatters.formatUnreadCount(5), '5');
        expect(Formatters.formatUnreadCount(99), '99');
        expect(Formatters.formatUnreadCount(100), '99+');
        expect(Formatters.formatUnreadCount(150), '99+');
      });
    });
  });
}
