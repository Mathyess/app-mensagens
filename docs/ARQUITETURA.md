# 🏗️ Arquitetura do App Mensagens

## Visão Geral

O App Mensagens segue uma arquitetura em camadas moderna, separando as responsabilidades entre apresentação, lógica de negócio e acesso a dados.

```
┌─────────────────────────────────┐
│   Camada de Apresentação        │
│  (Screens, Widgets, UI)         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│   Camada de Negócio/Lógica      │
│  (Services, Models, Routes)     │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│   Camada de Dados               │
│  (Supabase, APIs)               │
└─────────────────────────────────┘
```

## Camadas da Aplicação

### 1. **Camada de Apresentação (UI/Screens)**

Responsável por renderizar a interface do usuário e capturar interações.

**Localização**: `lib/screens/`, `lib/widgets/`

**Componentes principais:**
- `SplashScreen` - Tela de carregamento inicial
- `LoginScreen` - Autenticação do usuário
- `ConversationsScreen` - Lista de conversas
- `HomeScreen` - Tela de chat
- `ProfileScreen` - Perfil do usuário
- `SettingsScreen` - Configurações

**Responsabilidades:**
- Renderizar widgets
- Capturar eventos do usuário
- Atualizar UI com base em mudanças de estado
- Navegar entre telas

### 2. **Camada de Negócio (Services)**

Contém a lógica de negócio e comunicação com backend.

**Localização**: `lib/services/`

**Componentes principais:**
- `SupabaseService` - Operações de backend (CRUD, autenticação, real-time)

**Responsabilidades:**
- Gerenciar autenticação
- Operações em banco de dados
- Tratamento de erros
- Gerenciamento de streams em tempo real

### 3. **Camada de Dados (Models)**

Define estruturas de dados e modelos da aplicação.

**Localização**: `lib/models/`

**Componentes principais:**
- `Message` - Modelo de mensagem
- `User` - Modelo de usuário

**Responsabilidades:**
- Representar dados do aplicativo
- Serialização/Desserialização JSON
- Validações de dados

### 4. **Configuração**

**Localização**: `lib/config/`

**Componentes principais:**
- `SupabaseConfig` - Variáveis de ambiente e configuração inicial

## Fluxo de Dados

### Exemplo: Enviar Mensagem

```
User Input (HomeScreen)
    ↓
Call SupabaseService.sendMessage()
    ↓
Insert na tabela 'messages' no Supabase
    ↓
StreamController emite nova mensagem
    ↓
MessageBubble renderiza mensagem
    ↓
UI atualiza em tempo real
```

## Padrões de Design

### 1. **Service Pattern**

O `SupabaseService` encapsula toda comunicação com backend.

```dart
// Exemplo
final message = await SupabaseService.sendMessage(
  conversationId: convId,
  content: 'Olá!',
  senderId: userId,
);
```

### 2. **Stream Pattern**

Uso de `StreamController` para atualizações em tempo real.

```dart
// Exemplo
Stream<List<Message>> getMessagesStream(String conversationId) {
  return _messageStreams[conversationId]?.stream ?? Stream.empty();
}
```

### 3. **Model Pattern**

Modelos com métodos auxiliares para serialização.

```dart
// Exemplo
class Message {
  final String id;
  final String content;
  
  // Serialização
  factory Message.fromJson(Map<String, dynamic> json) => ...
  
  // Desserialização
  Map<String, dynamic> toJson() => ...
}
```

## Gerenciamento de Estado

A aplicação utiliza um modelo **reativo** com Streams para gerenciamento de estado:

1. **Estado Local**: Armazenado em widgets StatefulWidget
2. **Estado Global**: Gerenciado via Streams do Supabase
3. **Estado de Autenticação**: Gerenciado pelo `SupabaseService`

## Fluxo de Autenticação

```
SplashScreen
    ↓
Verificar se usuário está autenticado
    ↓
    ├─ SIM → ConversationsScreen
    └─ NÃO → LoginScreen
             ↓
          SignUp/SignIn
             ↓
          Salvar dados de sessão
             ↓
          ConversationsScreen
```

## Estrutura do Banco de Dados

### Tabelas Principais

#### 1. **profiles**
```sql
id (UUID) - Chave primária, referência a auth.users
name (TEXT)
email (TEXT)
avatar_url (TEXT)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### 2. **conversations**
```sql
id (UUID) - Chave primária
user1_id (UUID) - Referência a profiles
user2_id (UUID) - Referência a profiles
is_archived (BOOLEAN)
is_favorite (BOOLEAN)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### 3. **messages**
```sql
id (UUID) - Chave primária
conversation_id (UUID) - Referência a conversations
sender_id (UUID) - Referência a profiles
content (TEXT)
image_url (TEXT)
is_favorite (BOOLEAN)
is_deleted_for_everyone (BOOLEAN)
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

## Rotas e Navegação

A navegação é definida em `lib/routes.dart` utilizando `MaterialPageRoute`.

**Rotas disponíveis:**
- `/splash` - Tela inicial
- `/login` - Login
- `/conversations` - Lista de conversas
- `/new-conversation` - Nova conversa
- `/home` - Tela de chat
- `/profile` - Perfil
- `/settings` - Configurações
- `/favorites` - Favoritos
- `/archived` - Arquivados
- `/help` - Ajuda
- `/about` - Sobre

## Segurança

### Row Level Security (RLS)

O banco de dados implementa RLS para garantir que:
- Usuários veem apenas suas conversas
- Mensagens são acessíveis apenas aos participantes
- Dados de perfil são protegidos

### Autenticação

- JWT (JSON Web Token) via Supabase Auth
- Senhas com hash seguro
- Confirmação de email (opcional)

## Performance

### Otimizações Implementadas

1. **Índices no Banco de Dados**
   - Índices em conversas por usuário
   - Índices em mensagens por conversa
   - Índices em campos timestamp

2. **Gerenciamento de Streams**
   - `StreamController` para controlar fluxo de dados
   - Limpeza de streams quando não usados
   - Evitar múltiplas subscrições

3. **Lazy Loading**
   - Mensagens carregadas sob demanda
   - Paginação em conversas (futuro)

## Tratamento de Erros

### Estratégias

1. **Try-Catch Blocks**: Capturação de exceções
2. **Error Messages**: Mensagens amigáveis ao usuário
3. **Retry Logic**: Repetição automática em caso de falha temporária

### Exemplo

```dart
try {
  await SupabaseService.signIn(email, password);
} catch (e) {
  _showErrorDialog(_getErrorMessage(e));
}
```

## Futuras Melhorias Arquiteturais

- [ ] Implementar Provider para gerenciamento de estado
- [ ] Adicionar Repository Pattern
- [ ] Implementar Clean Architecture
- [ ] Adicionar unit tests e integration tests
- [ ] Implementar cache local com Hive/Drift
- [ ] Adicionar offline support

## Referências

- [Flutter Architecture Samples](https://github.com/google/app-architecture)
- [Clean Architecture in Flutter](https://resocoder.com/clean-architecture)
- [Supabase Best Practices](https://supabase.com/docs/guides/auth)
