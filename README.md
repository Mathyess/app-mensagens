# App Mensagens

Um aplicativo de mensagens em tempo real construído com Flutter e Supabase.

## Configuração

### 1. Instalar dependências

```bash
flutter pub get
```

### 2. Configurar Supabase

1. Crie um projeto no [Supabase](https://supabase.com)
2. Copie a URL e a chave anônima do seu projeto
3. Crie um arquivo `.env` na raiz do projeto com o seguinte conteúdo:

```
SUPABASE_URL=sua_url_do_supabase
SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
```

### 3. Configurar banco de dados

Execute os seguintes comandos SQL no editor SQL do Supabase:

```sql
-- Criar tabela de perfis
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de conversas
CREATE TABLE conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES auth.users(id) NOT NULL,
  user2_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);

-- Criar tabela de mensagens
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) NOT NULL,
  sender_id UUID REFERENCES auth.users(id) NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para melhor performance
CREATE INDEX idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX idx_conversations_user2 ON conversations(user2_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Habilitar RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para perfis
CREATE POLICY "Perfis são visíveis para todos" ON profiles FOR SELECT USING (true);
CREATE POLICY "Usuários podem inserir seu próprio perfil" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Políticas de segurança para conversas
CREATE POLICY "Usuários podem ver suas conversas" ON conversations FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Usuários podem criar conversas" ON conversations FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Políticas de segurança para mensagens
CREATE POLICY "Usuários podem ver mensagens de suas conversas" ON messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversations 
    WHERE conversations.id = messages.conversation_id 
    AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
  )
);
CREATE POLICY "Usuários autenticados podem inserir mensagens" ON messages FOR INSERT WITH CHECK (
  auth.role() = 'authenticated' 
  AND EXISTS (
    SELECT 1 FROM conversations 
    WHERE conversations.id = messages.conversation_id 
    AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
  )
);
CREATE POLICY "Usuários podem atualizar suas próprias mensagens" ON messages FOR UPDATE USING (auth.uid() = sender_id);
CREATE POLICY "Usuários podem deletar suas próprias mensagens" ON messages FOR DELETE USING (auth.uid() = sender_id);
```

### 4. Executar o aplicativo

```bash
flutter run
```

## Estrutura do Projeto

```
lib/
├── models/          # Modelos de dados
│   ├── message.dart
│   └── user.dart
├── services/        # Serviços e integrações
│   └── supabase_service.dart
├── screens/         # Telas do aplicativo
│   ├── home_screen.dart
│   └── login_screen.dart
├── widgets/         # Componentes reutilizáveis
│   ├── message_bubble.dart
│   └── message_input.dart
├── routes.dart      # Configuração de rotas
└── main.dart        # Ponto de entrada
```

## Funcionalidades

- ✅ Autenticação de usuários (login/registro)
- ✅ Conversas individuais por usuário
- ✅ Histórico de mensagens separado por conversa
- ✅ Envio de mensagens em tempo real
- ✅ Adicionar contatos por email
- ✅ Interface responsiva e moderna
- ✅ Integração com Supabase
- ✅ Gerenciamento de estado
- ✅ Navegação entre telas
- ✅ Sistema de conversas individuais

## Próximos Passos

- [ ] Upload de imagens
- [ ] Notificações push
- [ ] Grupos de conversa
- [ ] Busca de mensagens
- [ ] Mensagens de voz
- [ ] Compartilhamento de arquivos