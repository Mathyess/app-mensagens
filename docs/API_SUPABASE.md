# 📡 Integração com Supabase

## Visão Geral

Este documento descreve como o App Mensagens se integra com o Supabase para autenticação, banco de dados em tempo real e armazenamento.

## 🔑 Configuração

### Arquivo `.env`

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...sua_chave_anonima
```

### Arquivo `lib/config/supabase_config.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static final String url = dotenv.env['SUPABASE_URL'] ?? '';
  static final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static void printConfig() {
    print('🔧 Configuração Supabase:');
    print('✅ URL: $url');
    print('✅ Chave Anônima: ${anonKey.substring(0, 20)}...');
  }
}
```

## 🔐 Autenticação

### Fluxo de Login

```dart
// 1. Usuário insere email e senha
// 2. SupabaseService.signIn() é chamado
// 3. Supabase Auth valida credenciais
// 4. JWT token é retornado
// 5. Token é armazenado localmente
// 6. Usuário é redirecionado para ConversationsScreen
```

### Implementação

```dart
// lib/services/supabase_service.dart

static Future<AuthResponse> signIn(String email, String password) async {
  try {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    throw Exception(_getAuthErrorMessage(e));
  }
}
```

### Estados de Autenticação

```dart
// Obter usuário atual
final user = Supabase.instance.client.auth.currentUser;

// Verificar se está autenticado
if (user != null) {
  print('Usuário logado: ${user.email}');
} else {
  print('Não autenticado');
}
```

### Tratamento de Erros de Auth

```dart
static String _getAuthErrorMessage(dynamic error) {
  if (error is AuthException) {
    switch (error.statusCode) {
      case '429':
        return 'Por motivos de segurança, aguarde 45 segundos antes de tentar novamente.';
      case '400':
        if (error.message.contains('Invalid login credentials')) {
          return 'Email ou senha incorretos.';
        }
        return 'Dados inválidos.';
      default:
        return error.message;
    }
  }
  return 'Ocorreu um erro. Tente novamente.';
}
```

## 💾 Operações de Banco de Dados

### INSERT (Criar)

```dart
// Inserir nova mensagem
final response = await _client
  .from('messages')
  .insert({
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'created_at': DateTime.now().toIso8601String(),
  })
  .select();

final message = Message.fromJson(response.first);
```

### SELECT (Ler)

```dart
// Obter todas as conversas
final response = await _client
  .from('conversations')
  .select()
  .order('updated_at', ascending: false);

final conversations = response
  .map((json) => Conversation.fromJson(json))
  .toList();
```

### SELECT com Filtros

```dart
// Obter mensagens de uma conversa
final response = await _client
  .from('messages')
  .select()
  .eq('conversation_id', conversationId)
  .eq('is_deleted_for_everyone', false)
  .order('created_at', ascending: false)
  .limit(50);

final messages = response
  .map((json) => Message.fromJson(json))
  .toList();
```

### UPDATE (Atualizar)

```dart
// Favoritar mensagem
final response = await _client
  .from('messages')
  .update({
    'is_favorite': true,
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', messageId)
  .select();
```

### DELETE (Deletar)

```dart
// Deletar mensagem para todos
final response = await _client
  .from('messages')
  .update({
    'is_deleted_for_everyone': true,
    'updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', messageId)
  .eq('sender_id', currentUserId)
  .select();
```

## 📡 Real-time (Streams)

### Subscribing a Mudanças

```dart
// Escutar mudanças em tempo real
final subscription = _client
  .from('messages')
  .on(RealtimeListenTypes.postgresChanges,
      ({'action', 'record'}) {
        if (action == 'INSERT') {
          final newMessage = Message.fromJson(record);
          // Processar nova mensagem
        }
      })
  .eq('conversation_id', conversationId)
  .subscribe();
```

### Usar StreamController

```dart
final _messageStream = StreamController<List<Message>>();

Stream<List<Message>> getMessagesStream(String conversationId) {
  if (_messageStreams[conversationId] != null) {
    return _messageStreams[conversationId]!.stream;
  }

  final controller = StreamController<List<Message>>();
  _messageStreams[conversationId] = controller;

  // Implementar real-time listening
  return controller.stream;
}
```

### Limpar Streams

```dart
void disposeMessageStream(String conversationId) {
  _messageStreams[conversationId]?.close();
  _messageStreams.remove(conversationId);
}
```

## 🖼️ Armazenamento (Storage)

### Upload de Imagem

```dart
// Selecionar imagem
final picker = ImagePicker();
final pickedFile = await picker.pickImage(source: ImageSource.gallery);

// Upload para Supabase Storage
if (pickedFile != null) {
  final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final path = 'avatars/$userId/$fileName';
  
  await _client.storage
    .from('messages-storage')
    .upload(
      path,
      File(pickedFile.path),
      fileOptions: const FileOptions(cacheControl: '3600'),
    );
  
  // Obter URL pública
  final imageUrl = _client.storage
    .from('messages-storage')
    .getPublicUrl(path);
}
```

### Download de Imagem

```dart
// Obter URL pública da imagem
final imageUrl = _client.storage
  .from('messages-storage')
  .getPublicUrl(imagePath);

// Usar em Image widget
Image.network(imageUrl);
```

## 🔔 Notificações em Tempo Real

### Exemplo de Implementação

```dart
// Escutar novas mensagens
_client
  .from('messages')
  .on(RealtimeListenTypes.postgresChanges, (payload) {
    if (payload.eventType == 'INSERT') {
      final newMessage = Message.fromJson(payload.newRecord);
      _showNotification(newMessage);
    }
  })
  .eq('conversation_id', conversationId)
  .subscribe();

void _showNotification(Message message) {
  // Mostrar notificação local
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nova Mensagem'),
      content: Text(message.content),
    ),
  );
}
```

## 🐛 Debug

### Habilitar Logs

```dart
// No main.dart
if (kDebugMode) {
  Supabase.instance.client.enableLogging();
}
```

### Monitorar Requisições

```dart
// Ver requisições no DevTools
final response = await _client.from('messages').select();
print('Status: ${response.statusCode}');
print('Response: ${response.data}');
```

## 🚨 Tratamento de Erros

### Try-Catch

```dart
try {
  final response = await _client
    .from('messages')
    .insert({'content': content});
} on PostgrestException catch (error) {
  print('Erro Postgrest: ${error.message}');
} on PlatformException catch (error) {
  print('Erro Platform: ${error.message}');
} catch (error) {
  print('Erro desconhecido: $error');
}
```

### Tipos de Erro Comuns

| Erro | Causa | Solução |
|------|-------|--------|
| `401 Unauthorized` | JWT inválido | Re-login do usuário |
| `403 Forbidden` | RLS bloqueando | Verificar permissões |
| `404 Not Found` | Tabela/registro não existe | Verificar nome da tabela |
| `500 Internal Server` | Erro no servidor | Aguardar e tentar novamente |

## 📊 Limites de Taxa (Rate Limiting)

### Limites Padrão Supabase

- **Free Plan**: 50,000 requisições/dia
- **Pro Plan**: Baseado em uso

### Implementar Retry Logic

```dart
Future<T> _retryOperation<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i < maxRetries - 1) {
        await Future.delayed(delay * (i + 1));
      } else {
        rethrow;
      }
    }
  }
  throw Exception('Max retries reached');
}
```

## 🔐 Segurança

### Row Level Security (RLS)

O RLS garante que:
- Usuários veem apenas suas conversas
- Mensagens acessíveis apenas aos participantes
- Dados de perfil protegidos

### Usar JWT Seguro

```dart
// O token é gerenciado automaticamente pelo Supabase
// Nunca compartilhe o SUPABASE_ANON_KEY em produção
```

## 📚 Referências

- [Supabase Flutter Docs](https://supabase.com/docs/reference/flutter)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Supabase Database](https://supabase.com/docs/guides/database)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Real-time](https://supabase.com/docs/guides/realtime)
