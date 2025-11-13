# 🗄️ Banco de Dados

## Visão Geral

O App Mensagens utiliza **Supabase** (PostgreSQL) como banco de dados. Este documento descreve o esquema, relacionamentos e melhores práticas.

## 📊 Diagrama do Esquema

```
┌──────────────┐
│   profiles   │
├──────────────┤
│ id (PK)      │◄─────────┐
│ name         │          │
│ email        │          │
│ avatar_url   │          │
│ created_at   │          │
│ updated_at   │          │
└──────────────┘          │
                          │
                    (FK References)
         ┌────────────────┴────────────────┐
         │                                 │
┌──────────────────────────┐    ┌──────────────────────────┐
│   conversations          │    │   messages               │
├──────────────────────────┤    ├──────────────────────────┤
│ id (PK)                  │◄───│ conversation_id (FK)     │
│ user1_id (FK)            │    │ sender_id (FK)           │
│ user2_id (FK)            │    │ id (PK)                  │
│ is_archived              │    │ content                  │
│ is_favorite              │    │ image_url                │
│ created_at               │    │ is_favorite              │
│ updated_at               │    │ is_deleted_for_everyone  │
└──────────────────────────┘    │ created_at               │
                                │ updated_at               │
                                └──────────────────────────┘
```

## 📋 Tabelas

### 1. **profiles**

Armazena informações de usuários.

#### Schema

```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Campos

| Campo | Tipo | Restrições | Descrição |
|-------|------|-----------|-----------|
| `id` | UUID | PK, FK | Referencia auth.users |
| `name` | TEXT | NOT NULL | Nome do usuário |
| `email` | TEXT | UNIQUE, NOT NULL | Email do usuário |
| `avatar_url` | TEXT | NULL | URL do avatar |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Data de criação |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Última atualização |

#### Exemplos de Dados

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "João Silva",
  "email": "joao@example.com",
  "avatar_url": "https://supabase.../avatar.jpg",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-20T15:45:00Z"
}
```

---

### 2. **conversations**

Armazena conversas entre dois usuários.

#### Schema

```sql
CREATE TABLE conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES profiles(id) NOT NULL,
  user2_id UUID REFERENCES profiles(id) NOT NULL,
  is_archived BOOLEAN DEFAULT FALSE,
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);
```

#### Campos

| Campo | Tipo | Restrições | Descrição |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Identificador único |
| `user1_id` | UUID | FK, NOT NULL | Primeiro usuário |
| `user2_id` | UUID | FK, NOT NULL | Segundo usuário |
| `is_archived` | BOOLEAN | DEFAULT FALSE | Conversa arquivada? |
| `is_favorite` | BOOLEAN | DEFAULT FALSE | Conversa favorita? |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Data de criação |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Última atualização |

#### Restrições

- **UNIQUE(user1_id, user2_id)**: Garante apenas uma conversa entre dois usuários
- **Foreign Keys**: Ambos os usuários devem existir em `profiles`

#### Exemplos de Dados

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440111",
  "user1_id": "550e8400-e29b-41d4-a716-446655440000",
  "user2_id": "550e8400-e29b-41d4-a716-446655440001",
  "is_archived": false,
  "is_favorite": true,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-20T15:45:00Z"
}
```

---

### 3. **messages**

Armazena mensagens dentro de conversas.

#### Schema

```sql
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) NOT NULL,
  sender_id UUID REFERENCES profiles(id) NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_deleted_for_everyone BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Campos

| Campo | Tipo | Restrições | Descrição |
|-------|------|-----------|-----------|
| `id` | UUID | PK | Identificador único |
| `conversation_id` | UUID | FK, NOT NULL | Conversa associada |
| `sender_id` | UUID | FK, NOT NULL | Quem enviou |
| `content` | TEXT | NOT NULL | Conteúdo da mensagem |
| `image_url` | TEXT | NULL | URL de imagem (se houver) |
| `is_favorite` | BOOLEAN | DEFAULT FALSE | Mensagem favoritada? |
| `is_deleted_for_everyone` | BOOLEAN | DEFAULT FALSE | Deletada para todos? |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Data de envio |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Última edição |

#### Exemplos de Dados

```json
{
  "id": "770e8400-e29b-41d4-a716-446655440222",
  "conversation_id": "660e8400-e29b-41d4-a716-446655440111",
  "sender_id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "Olá! Como vai?",
  "image_url": null,
  "is_favorite": false,
  "is_deleted_for_everyone": false,
  "created_at": "2024-01-20T15:45:00Z",
  "updated_at": "2024-01-20T15:45:00Z"
}
```

## 🔑 Índices

Índices melhoram performance de queries frequentes.

```sql
-- Índice para buscar conversas por usuário
CREATE INDEX idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX idx_conversations_user2 ON conversations(user2_id);

-- Índice para buscar mensagens por conversa
CREATE INDEX idx_messages_conversation ON messages(conversation_id);

-- Índice para ordenar mensagens por data
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Índice para filtrar mensagens deletadas
CREATE INDEX idx_messages_deleted_for_everyone ON messages(is_deleted_for_everyone);
```

## 🔐 Row Level Security (RLS)

RLS garante que usuários veem apenas dados que podem acessar.

### Políticas para `profiles`

```sql
-- Usuários veem seu próprio perfil
CREATE POLICY "Users can view their own profile"
  ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Usuários podem atualizar seu próprio perfil
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);
```

### Políticas para `conversations`

```sql
-- Usuários veem apenas suas conversas
CREATE POLICY "Users can see their conversations"
  ON conversations
  FOR SELECT
  USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Apenas os dois participantes podem inserir
CREATE POLICY "Only conversation participants can insert"
  ON conversations
  FOR INSERT
  WITH CHECK (auth.uid() IN (user1_id, user2_id));
```

### Políticas para `messages`

```sql
-- Usuários veem mensagens de suas conversas
CREATE POLICY "Users can view messages from their conversations"
  ON messages
  FOR SELECT
  USING (
    conversation_id IN (
      SELECT id FROM conversations 
      WHERE auth.uid() IN (user1_id, user2_id)
    )
  );

-- Usuários podem inserir mensagens em suas conversas
CREATE POLICY "Users can send messages in their conversations"
  ON messages
  FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    conversation_id IN (
      SELECT id FROM conversations 
      WHERE auth.uid() IN (user1_id, user2_id)
    )
  );
```

## 📝 Operações Comuns

### 1. Criar Nova Conversa

```sql
INSERT INTO conversations (user1_id, user2_id)
VALUES (
  'user1-uuid',
  'user2-uuid'
)
ON CONFLICT (user1_id, user2_id) DO NOTHING;
```

### 2. Enviar Mensagem

```sql
INSERT INTO messages (conversation_id, sender_id, content)
VALUES (
  'conversation-uuid',
  'sender-uuid',
  'Olá!'
);
```

### 3. Deletar Mensagem para Todos

```sql
UPDATE messages
SET is_deleted_for_everyone = TRUE,
    updated_at = NOW()
WHERE id = 'message-uuid'
  AND sender_id = 'current-user-uuid';
```

### 4. Favoritar Conversa

```sql
UPDATE conversations
SET is_favorite = TRUE,
    updated_at = NOW()
WHERE id = 'conversation-uuid'
  AND (user1_id = 'current-user-uuid' OR user2_id = 'current-user-uuid');
```

### 5. Arquivar Conversa

```sql
UPDATE conversations
SET is_archived = TRUE,
    updated_at = NOW()
WHERE id = 'conversation-uuid'
  AND (user1_id = 'current-user-uuid' OR user2_id = 'current-user-uuid');
```

### 6. Obter Todas as Conversas de um Usuário

```sql
SELECT * FROM conversations
WHERE user1_id = 'user-uuid' OR user2_id = 'user-uuid'
ORDER BY updated_at DESC;
```

### 7. Obter Mensagens de uma Conversa

```sql
SELECT * FROM messages
WHERE conversation_id = 'conversation-uuid'
  AND is_deleted_for_everyone = FALSE
ORDER BY created_at DESC
LIMIT 50;
```

## 🔄 Relacionamentos

### Um para Muitos: Profile → Conversations
- Um usuário pode ter várias conversas
- Cada conversa tem exatamente dois usuários

### Um para Muitos: Conversation → Messages
- Uma conversa pode ter várias mensagens
- Cada mensagem pertence a uma conversa

### Um para Muitos: Profile → Messages
- Um usuário pode enviar várias mensagens
- Cada mensagem é enviada por um usuário

## 🔧 Migrations

### Criar Nova Coluna

```sql
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS is_deleted_for_everyone BOOLEAN DEFAULT FALSE;
```

### Remover Coluna

```sql
ALTER TABLE messages
DROP COLUMN IF EXISTS old_column;
```

### Renomear Coluna

```sql
ALTER TABLE messages
RENAME COLUMN old_name TO new_name;
```

### Criar Índice

```sql
CREATE INDEX idx_nome ON tabela(coluna);
```

### Deletar Índice

```sql
DROP INDEX IF EXISTS idx_nome;
```

## 📊 Performance

### Dicas de Otimização

1. **Use Índices**: Criei índices nas colunas mais consultadas
2. **Limite Resultados**: Use LIMIT em queries grandes
3. **Selecione Apenas Colunas Necessárias**: Evite SELECT *
4. **Paginação**: Implemente paginação para listas grandes

### Query Exemplo Otimizada

```sql
SELECT id, sender_id, content, created_at
FROM messages
WHERE conversation_id = $1
  AND is_deleted_for_everyone = FALSE
ORDER BY created_at DESC
LIMIT 50
OFFSET 0;
```

## 🚨 Segurança

1. **Sempre Use RLS**: Nunca confia em JWT do cliente
2. **Validar Input**: Sanitize dados antes de inserir
3. **Usar Tipos Corretos**: UUID para IDs, TEXT para strings
4. **Senhas**: Nunca armazene senhas (use auth.users)

## 📚 Referências

- [Supabase PostgreSQL Docs](https://supabase.com/docs/guides/database)
- [PostgreSQL Official Docs](https://www.postgresql.org/docs/)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
