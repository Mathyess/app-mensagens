# 🧩 Componentes (Widgets)

## Visão Geral

Este documento descreve os widgets customizados do App Mensagens, seus parâmetros e como usá-los.

## 📑 Índice

1. [MessageBubble](#messagebubble)
2. [MessageInput](#messageinput)
3. [ConversationTile](#conversationtile)
4. [AppDrawer](#appdrawer)

---

## MessageBubble

### Descrição

Widget que exibe uma mensagem individual no chat. Suporta:
- Texto e imagens
- Menu de contexto (deletar, favoritar)
- Indicadores de status
- Timestamps

### Localização

`lib/widgets/message_bubble.dart`

### Parâmetros

```dart
const MessageBubble({
  required this.message,           // Message object
  required this.isSender,          // Booleano: é mensagem do usuário?
  required this.onDelete,          // Callback ao deletar
  required this.onDeleteForEveryone, // Callback ao deletar para todos
  required this.onFavorite,        // Callback ao favoritar
  required this.senderName,        // Nome do remetente
  required this.onReply,           // Callback ao responder
  required this.conversationId,    // ID da conversa
  required this.currentUserId,     // ID do usuário atual
});
```

### Exemplo de Uso

```dart
MessageBubble(
  message: message,
  isSender: message.senderId == currentUserId,
  onDelete: () {
    // Deletar mensagem
    SupabaseService.deleteMessageForMe(message.id);
  },
  onDeleteForEveryone: () {
    // Deletar para todos
    SupabaseService.deleteMessageForEveryone(message.id);
  },
  onFavorite: () {
    // Favoritar
    SupabaseService.toggleFavorite(message.id);
  },
  senderName: senderName,
  onReply: (message) {
    // Responder
  },
  conversationId: conversationId,
  currentUserId: currentUserId,
)
```

### Elementos de UI

- **Bolha de Mensagem**: Diferente cor para remetente/destinatário
- **Imagem**: Se houver `image_url`
- **Menu**: Ícone ⋮ com opções
- **Timestamp**: Data/hora da mensagem
- **Status Deletado**: Texto "Esta mensagem foi deletada"

### Comportamentos

#### Menu de Contexto

```
┌─────────────────────┐
│ ⋮                   │
├─────────────────────┤
│ 📌 Favoritar        │
│ 🔗 Responder        │
│ 🗑️ Deletar para mim │
│ 🗑️ Deletar para todos│
└─────────────────────┘
```

#### Deletar para Mim

- Remove apenas para o usuário atual
- Outro usuário continua vendo a mensagem
- Mostra "Você deletou esta mensagem"

#### Deletar para Todos

- Remove para todos os participantes
- Apenas o remetente pode fazer isso
- Mostra "Esta mensagem foi deletada"

---

## MessageInput

### Descrição

Widget de entrada de mensagens com suporte a:
- Texto
- Envio por Enter ou botão
- Seleção de imagens
- Feedback visual

### Localização

`lib/widgets/message_input.dart`

### Parâmetros

```dart
const MessageInput({
  required this.onSendMessage,  // Callback com mensagem
  required this.onSendImage,    // Callback com imagem
  required this.isLoading,      // Desabilitar durante envio?
  this.hintText = 'Digite uma mensagem...',
});
```

### Exemplo de Uso

```dart
MessageInput(
  onSendMessage: (message) async {
    await SupabaseService.sendMessage(
      conversationId: conversationId,
      content: message,
      senderId: currentUserId,
    );
  },
  onSendImage: (imageFile) async {
    await SupabaseService.sendMessageWithImage(
      conversationId: conversationId,
      content: 'Imagem',
      imageFile: imageFile,
      senderId: currentUserId,
    );
  },
  isLoading: isSending,
)
```

### Elementos de UI

```
┌──────────────────────────────┐
│ 📎 | Digite uma mensagem... | 📤 │
└──────────────────────────────┘
  ↑                          ↑
  │                          │
  Anexar arquivo         Enviar
```

### Funcionalidades

- **Enviar por Enter**: Pressionar Enter envia
- **Enviar por Botão**: Clique no ícone 📤
- **Anexar Imagem**: Clique no ícone 📎
- **Indicador de Carregamento**: Spinner durante envio

---

## ConversationTile

### Descrição

Widget que exibe um item de conversa na lista. Mostra:
- Avatar do usuário
- Nome do usuário
- Última mensagem
- Timestamp
- Indicador de não lido (futuro)

### Localização

`lib/widgets/conversation_tile.dart`

### Parâmetros

```dart
const ConversationTile({
  required this.conversation,    // Objeto Conversation
  required this.otherUserName,   // Nome do outro usuário
  required this.lastMessage,     // Última mensagem
  required this.onTap,           // Callback ao tocar
  required this.onLongPress,     // Callback ao manter pressionado
  this.isFavorite = false,       // É favorita?
  this.isArchived = false,       // Está arquivada?
});
```

### Exemplo de Uso

```dart
ConversationTile(
  conversation: conversation,
  otherUserName: otherUserName,
  lastMessage: lastMessage,
  isFavorite: conversation.isFavorite,
  isArchived: conversation.isArchived,
  onTap: () {
    Navigator.pushNamed(
      context,
      AppRoutes.home,
      arguments: {
        'userId': conversation.id,
        'chatName': otherUserName,
      },
    );
  },
  onLongPress: () {
    _showConversationOptions(context, conversation);
  },
)
```

### Elementos de UI

```
┌─────────────────────────────────────┐
│ 👤 João Silva         15 jan. 14:30 │
│ Última mensagem exibida aqui... ⭐  │
└─────────────────────────────────────┘
```

### Indicadores

- **⭐**: Conversa favorita
- **📤**: Conversa arquivada
- **Negrito**: Mensagem não lida (futuro)

---

## AppDrawer

### Descrição

Menu lateral que exibe:
- Informações do usuário
- Navegação entre telas
- Opções de configuração
- Logout

### Localização

`lib/widgets/app_drawer.dart`

### Estrutura

```
Drawer
├── UserAccountsDrawerHeader
│   ├── Avatar
│   ├── Nome
│   └── Email
├── ListTile (Conversas)
├── ListTile (Favoritos)
├── ListTile (Arquivados)
├── Divider
├── ListTile (Perfil)
├── ListTile (Configurações)
├── ListTile (Ajuda)
├── ListTile (Sobre)
├── Divider
└── ListTile (Sair)
```

### Exemplo de Uso

```dart
Scaffold(
  drawer: AppDrawer(
    currentUserId: currentUserId,
    userName: userName,
    userEmail: userEmail,
    userAvatarUrl: userAvatarUrl,
    onLogout: () {
      SupabaseService.signOut();
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    },
  ),
  body: ConversationsScreen(),
)
```

### Menu Items

| Ícone | Título | Rota |
|-------|--------|------|
| 💬 | Conversas | `/conversations` |
| ⭐ | Favoritos | `/favorites` |
| 📤 | Arquivados | `/archived` |
| 👤 | Perfil | `/profile` |
| ⚙️ | Configurações | `/settings` |
| ❓ | Ajuda | `/help` |
| ℹ️ | Sobre | `/about` |
| 🚪 | Sair | - |

---

## Boas Práticas

### 1. **Reusabilidade**

```dart
// ✅ BOM - Componente reutilizável
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const CustomButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.blue,
      ),
      child: Text(label),
    );
  }
}
```

### 2. **Separação de Responsabilidades**

```dart
// ✅ BOM - Widget apresenta, service faz lógica
class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showOptions(context); // Mostrar menu
      },
      child: Container(
        child: Text(message.content),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListTile(
        title: const Text('Deletar'),
        onTap: () {
          onDelete(message.id);
          Navigator.pop(context);
        },
      ),
    );
  }
}
```

### 3. **Estados de Carregamento**

```dart
// ✅ BOM - Indicar quando está carregando
if (isLoading) {
  return Center(
    child: CircularProgressIndicator(),
  );
} else if (messages.isEmpty) {
  return Center(
    child: Text('Nenhuma mensagem'),
  );
} else {
  return ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) => MessageBubble(
      message: messages[index],
    ),
  );
}
```

### 4. **Acessibilidade**

```dart
// ✅ BOM - Adicionar labels para acessibilidade
Semantics(
  label: 'Deletar mensagem',
  button: true,
  enabled: true,
  onTap: () => onDelete(),
  child: IconButton(
    icon: Icon(Icons.delete),
    tooltip: 'Deletar',
    onPressed: () => onDelete(),
  ),
)
```

---

## Customização

### Temas

Os widgets usam `Theme.of(context)` para cores e estilos:

```dart
// Em main.dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
    ),
  ),
)
```

### Cores Personalizadas

```dart
// Acessar tema
final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary;
final secondaryColor = theme.colorScheme.secondary;

// Usar em widgets
Container(
  color: primaryColor,
  child: Text('Texto', style: theme.textTheme.bodyLarge),
)
```

---

## Testes

### Exemplo de Widget Test

```dart
testWidgets('MessageBubble exibe conteúdo corretamente', 
  (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: Message(
            id: '1',
            content: 'Teste',
            senderId: 'user1',
          ),
          isSender: true,
          onDelete: () {},
          onDeleteForEveryone: () {},
          onFavorite: () {},
          senderName: 'Teste',
          onReply: (m) {},
          conversationId: 'conv1',
          currentUserId: 'user1',
        ),
      ),
    ),
  );

  expect(find.text('Teste'), findsOneWidget);
});
```

---

## Referências

- [Flutter Widgets Catalog](https://flutter.dev/docs/development/ui/widgets)
- [Material Design 3](https://m3.material.io/)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
