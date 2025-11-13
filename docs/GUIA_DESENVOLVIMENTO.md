# 📖 Guia de Desenvolvimento

## Bem-vindo, Desenvolvedor! 👋

Este guia ajudará você a configurar o ambiente e começar a contribuir com o projeto App Mensagens.

## 📋 Índice

1. [Setup Inicial](#setup-inicial)
2. [Estrutura do Projeto](#estrutura-do-projeto)
3. [Padrões de Código](#padrões-de-código)
4. [Workflow de Desenvolvimento](#workflow-de-desenvolvimento)
5. [Debug e Testes](#debug-e-testes)
6. [Commits e PRs](#commits-e-prs)

## 🚀 Setup Inicial

### Pré-requisitos

```bash
# Verificar instalação
flutter --version    # 3.0 ou superior
dart --version       # 3.0 ou superior
git --version
```

### Configuração do Ambiente

1. **Clone o repositório**
```bash
git clone https://github.com/Mathyess/app-mensagens.git
cd app-mensagens
```

2. **Instale dependências**
```bash
flutter pub get
```

3. **Configure as variáveis de ambiente**
```bash
# Criar arquivo .env
cp .env.example .env

# Editar com seus dados Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua_chave_anonima
```

4. **Verifique a configuração**
```bash
flutter doctor
```

## 📂 Estrutura do Projeto

### Convenção de Pastas

```
lib/
├── config/           # Configurações globais
├── models/          # Modelos de dados
├── screens/         # Telas principais
├── services/        # Serviços (API, BD)
├── widgets/         # Widgets reutilizáveis
├── routes.dart      # Definição de rotas
└── main.dart        # Arquivo principal
```

### Nomear Arquivos

```dart
// Widgets/Screens: snake_case
conversation_screen.dart
message_bubble.dart

// Services: snake_case
supabase_service.dart

// Models: snake_case
message.dart
user.dart
```

## 📝 Padrões de Código

### Estilo de Código

Siga o guia oficial [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

```bash
# Formatar código
dart format lib/ test/

# Analisar problemas
dart analyze
```

### Convenções Dart

#### 1. **Classes e Modelos**

```dart
// ✅ BOM
class UserProfile {
  final String id;
  final String name;
  
  UserProfile({
    required this.id,
    required this.name,
  });
}

// ❌ RUIM
class userProfile {
  String id;
  String name;
}
```

#### 2. **Métodos e Funções**

```dart
// ✅ BOM - Nomes descritivos
Future<List<Message>> fetchConversationMessages(String conversationId) async {
  // implementação
}

// ❌ RUIM - Nomes genéricos
Future<List<Message>> getMessages() async {
  // implementação
}
```

#### 3. **Variáveis**

```dart
// ✅ BOM
final String userId = '123';
const int maxRetries = 3;
final List<Message> unreadMessages = [];

// ❌ RUIM
String UserID = '123';
var max_retries = 3;
List MSG = [];
```

#### 4. **Comentários**

```dart
// ✅ BOM
/// Envia mensagem para conversa específica
/// 
/// [conversationId] ID da conversa
/// [content] Conteúdo da mensagem
/// Returns: Future com mensagem enviada
Future<Message> sendMessage(String conversationId, String content) async {
  // implementação
}

// ❌ RUIM
// função para mandar msg
void send() {
  // implementação
}
```

### Tratamento de Erros

```dart
// ✅ BOM
try {
  final user = await SupabaseService.signIn(email, password);
  return user;
} on AuthException catch (e) {
  // Tratar erro de autenticação específico
  rethrow;
} catch (e) {
  // Tratar erro genérico
  rethrow;
}

// ❌ RUIM
try {
  return await SupabaseService.signIn(email, password);
} catch (e) {
  print('erro: $e');
}
```

### Null Safety

```dart
// ✅ BOM - Usar null safety
final String? optionalName;
final String requiredName;

if (optionalName != null) {
  print(optionalName.toUpperCase());
}

// ❌ RUIM - Não ignorar null safety
final String optionalName = something; // Pode ser null!
```

## 🔄 Workflow de Desenvolvimento

### 1. Crie uma Branch

```bash
# Atualize main
git checkout main
git pull origin main

# Crie nova branch com padrão consistente
git checkout -b feature/nova-funcionalidade
# ou
git checkout -b bugfix/corrigir-erro
# ou
git checkout -b doc/melhorar-documentacao
```

### 2. Faça as Alterações

```bash
# Verifique o que mudou
git status

# Veja as mudanças detalhadas
git diff
```

### 3. Teste Localmente

```bash
# Formatar e analisar código
dart format lib/
dart analyze

# Rodar a aplicação
flutter run

# Rodar testes
flutter test
```

### 4. Commit com Mensagem Clara

```bash
# ✅ BOM
git commit -m "feat: adiciona funcionalidade de deletar mensagem"
git commit -m "fix: corrige bug de atualização em tempo real"
git commit -m "docs: atualiza guia de instalação"

# ❌ RUIM
git commit -m "update"
git commit -m "fixes bug"
git commit -m "alterações variadas"
```

### 5. Push e Pull Request

```bash
# Push da branch
git push origin feature/nova-funcionalidade

# Vá para GitHub e crie um Pull Request
# Descreva o que foi feito, por quê e como testar
```

## 🧪 Debug e Testes

### Modo Debug

```bash
# Executar com logs detalhados
flutter run -v

# Habilitar framework traces
flutter run --trace-startup
```

### DevTools

```bash
# Abrir DevTools
flutter pub global activate devtools
devtools

# Conectar seu app
flutter run
```

### Testes Unitários

```dart
// test/supabase_service_test.dart
void main() {
  group('SupabaseService', () {
    test('signUp cria novo usuário', () async {
      // Arrange
      const email = 'teste@example.com';
      const password = 'senha123';
      const name = 'Teste User';
      
      // Act
      final result = await SupabaseService.signUp(email, password, name);
      
      // Assert
      expect(result.user, isNotNull);
      expect(result.user?.email, equals(email));
    });
  });
}
```

```bash
# Rodar testes
flutter test

# Rodar teste específico
flutter test test/supabase_service_test.dart

# Rodar com cobertura
flutter test --coverage
```

### Widget Tests

```dart
testWidgets('LoginScreen renderiza corretamente', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(const MyApp());
  
  // Act
  await tester.enterText(find.byType(TextField).first, 'test@example.com');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.byType(ConversationsScreen), findsOneWidget);
});
```

## 📮 Commits e PRs

### Formato de Commit

Siga o padrão [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé opcional]
```

**Tipos:**
- `feat` - Nova funcionalidade
- `fix` - Correção de bug
- `docs` - Documentação
- `style` - Formatação (sem alterar lógica)
- `refactor` - Refatoração de código
- `perf` - Melhorias de performance
- `test` - Testes

**Exemplos:**

```bash
git commit -m "feat: adiciona opção de deletar mensagem para todos"
git commit -m "fix(auth): corrige problema de logout"
git commit -m "docs: atualiza README com screenshots"
git commit -m "refactor: simplifica lógica de stream de mensagens"
```

### Pull Request

**Template sugerido:**

```markdown
## 📝 Descrição
Breve descrição do que foi implementado/corrigido

## 🎯 Tipo de Mudança
- [ ] Nova funcionalidade
- [ ] Correção de bug
- [ ] Quebra de compatibilidade
- [ ] Documentação

## ✅ Checklist
- [ ] Código formatado (dart format)
- [ ] Sem erros (dart analyze)
- [ ] Testes adicionados/atualizados
- [ ] Documentação atualizada
- [ ] Testado localmente

## 🧪 Como Testar
1. Clone esta branch
2. Execute `flutter pub get`
3. Configure as variáveis de ambiente
4. Execute com `flutter run`
5. Teste o seguinte:
   - [Descrição do teste]

## 📸 Screenshots (se aplicável)
Antes/Depois

## 🔗 Issues Relacionadas
Closes #123
```

## 🆘 Troubleshooting

### Problema: "Supabase não inicializa"
```bash
# Verifique o arquivo .env
cat .env

# Limpe e reconstrua
flutter clean
flutter pub get
flutter run
```

### Problema: "Erro de Stream"
```dart
// Certifique-se de fazer dispose
@override
void dispose() {
  SupabaseService.disposeMessageStream(conversationId);
  super.dispose();
}
```

### Problema: "Hot Reload não funciona"
```bash
# Tente hot restart
# Pressione 'R' no terminal

# Se não funcionar, reconstrua
flutter run
```

## 📚 Recursos Úteis

- [Documentação Flutter](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/flutter)
- [Material Design 3](https://m3.material.io/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## 🤝 Dúvidas?

- Abra uma [Issue](https://github.com/Mathyess/app-mensagens/issues)
- Consulte a [Documentação](./ARQUITETURA.md)
- Converse comigo no GitHub

---

**Happy Coding! 🚀**
