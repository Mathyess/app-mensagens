import 'package:flutter_test/flutter_test.dart';
import 'package:app_mensagens/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('deve retornar null para email válido', () {
        expect(Validators.validateEmail('teste@teste.com'), null);
        expect(Validators.validateEmail('user.name@example.co.uk'), null);
      });

      test('deve retornar erro para email vazio', () {
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail(null), isNotNull);
      });

      test('deve retornar erro para email inválido', () {
        expect(Validators.validateEmail('invalido'), isNotNull);
        expect(Validators.validateEmail('invalido@'), isNotNull);
        expect(Validators.validateEmail('@invalido.com'), isNotNull);
      });
    });

    group('validatePassword', () {
      test('deve retornar null para senha válida', () {
        expect(Validators.validatePassword('123456'), null);
        expect(Validators.validatePassword('senhaforte123'), null);
      });

      test('deve retornar erro para senha vazia', () {
        expect(Validators.validatePassword(''), isNotNull);
        expect(Validators.validatePassword(null), isNotNull);
      });

      test('deve retornar erro para senha curta', () {
        expect(Validators.validatePassword('12345'), isNotNull);
      });
    });

    group('validateName', () {
      test('deve retornar null para nome válido', () {
        expect(Validators.validateName('João'), null);
        expect(Validators.validateName('Maria Silva'), null);
      });

      test('deve retornar erro para nome vazio', () {
        expect(Validators.validateName(''), isNotNull);
        expect(Validators.validateName(null), isNotNull);
      });

      test('deve retornar erro para nome muito curto', () {
        expect(Validators.validateName('A'), isNotNull);
      });

      test('deve retornar erro para nome muito longo', () {
        expect(Validators.validateName('A' * 51), isNotNull);
      });
    });

    group('validateGroupName', () {
      test('deve retornar null para nome de grupo válido', () {
        expect(Validators.validateGroupName('Grupo Teste'), null);
        expect(Validators.validateGroupName('Família'), null);
      });

      test('deve retornar erro para nome vazio', () {
        expect(Validators.validateGroupName(''), isNotNull);
        expect(Validators.validateGroupName(null), isNotNull);
      });

      test('deve retornar erro para nome muito curto', () {
        expect(Validators.validateGroupName('AB'), isNotNull);
      });

      test('deve retornar erro para nome muito longo', () {
        expect(Validators.validateGroupName('A' * 101), isNotNull);
      });
    });

    group('validateFileSize', () {
      test('deve retornar null para tamanho válido', () {
        expect(Validators.validateFileSize(1024), null); // 1 KB
        expect(Validators.validateFileSize(10 * 1024 * 1024), null); // 10 MB
      });

      test('deve retornar erro para arquivo muito grande', () {
        expect(Validators.validateFileSize(21 * 1024 * 1024), isNotNull); // 21 MB
      });
    });
  });
}
