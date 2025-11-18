# Connect

Aplicativo de mensagens em tempo real construído com Flutter e Supabase, oferecendo uma experiência moderna e fluida de comunicação.

## 📋 Sobre o Projeto

Connect é uma plataforma de mensagens instantâneas que permite conversas diretas e em grupo, com recursos avançados como indicadores de digitação, favoritos, arquivamento de mensagens e muito mais. Desenvolvido com Flutter para garantir performance nativa em múltiplas plataformas e Supabase como backend escalável.

## ✨ Funcionalidades

### Implementadas
- ✅ Autenticação segura de usuários (login/registro)
- ✅ Conversas diretas entre usuários
- ✅ Grupos de conversa públicos e privados
- ✅ Mensagens em tempo real
- ✅ Indicadores de digitação
- ✅ Favoritar mensagens importantes
- ✅ Arquivar conversas
- ✅ Edição e exclusão de mensagens
- ✅ Busca de grupos públicos
- ✅ Gerenciamento de perfil de usuário
- ✅ Interface responsiva e moderna
- ✅ Suporte offline com cache local (SQLite)
- ✅ Detecção de conectividade

### Em Desenvolvimento
- 🔄 Upload e compartilhamento de imagens
- 🔄 Notificações push
- 🔄 Busca avançada de mensagens
- 🔄 Mensagens de voz
- 🔄 Compartilhamento de arquivos
- 🔄 Reações a mensagens

## 🚀 Começando

### Pré-requisitos

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Conta no [Supabase](https://supabase.com)
- Editor de código (VS Code, Android Studio, etc.)

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/connect.git
cd connect
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure as variáveis de ambiente:

Crie um arquivo `.env` na raiz do projeto:
```env
SUPABASE_URL=sua_url_do_supabase
SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
```

4. Configure o banco de dados no Supabase (veja seção abaixo)

5. Execute o aplicativo:
```bash
flutter run
```

## 🗄️ Configuração do Banco de Dados

Acesse o editor SQL do seu projeto no Supabase e execute o script completo abaixo:

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
  name TEXT,
  type TEXT DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  is_public BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id),
  user1_id UUID REFERENCES auth.users(id),
  user2_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user1_id, user2_id)
);

-- Criar tabela de participantes de conversas
CREATE TABLE conversation_participants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  left_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(conversation_id, user_id)
);

-- Criar tabela de mensagens
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) NOT NULL,
  sender_id UUID REFERENCES auth.users(id) NOT NULL,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  file_url TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE,
  is_edited BOOLEAN DEFAULT FALSE,
  edited_at TIMESTAMP WITH TIME ZONE,
  reactions JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de indicadores de digitação
CREATE TABLE typing_indicators (
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

-- Criar índices para otimização de performance
CREATE INDEX idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX idx_conversations_user2 ON conversations(user2_id);
CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversation_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_conversation_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Habilitar Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para perfis
CREATE POLICY "Perfis são visíveis para todos" ON profiles FOR SELECT USING (true);
CREATE POLICY "Usuários podem inserir seu próprio perfil" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Políticas de segurança para conversas
CREATE POLICY "Usuários podem ver conversas diretas" ON conversations FOR SELECT 
  USING (type = 'direct' AND (auth.uid() = user1_id OR auth.uid() = user2_id));
CREATE POLICY "Usuários podem ver grupos públicos" ON conversations FOR SELECT 
  USING (type = 'group' AND is_public = true);
CREATE POLICY "Usuários podem ver grupos que participam" ON conversations FOR SELECT 
  USING (
    type = 'group' AND EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_participants.conversation_id = conversations.id 
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.left_at IS NULL
    )
  );
CREATE POLICY "Usuários podem criar conversas diretas" ON conversations FOR INSERT 
  WITH CHECK (type = 'direct' AND (auth.uid() = user1_id OR auth.uid() = user2_id));
CREATE POLICY "Usuários podem criar grupos" ON conversations FOR INSERT 
  WITH CHECK (type = 'group' AND auth.uid() = created_by);

-- Políticas de segurança para participantes
CREATE POLICY "Usuários podem ver participantes de suas conversas" ON conversation_participants FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversations 
      WHERE conversations.id = conversation_participants.conversation_id 
      AND (
        (conversations.type = 'direct' AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid()))
        OR (
          conversations.type = 'group' AND EXISTS (
            SELECT 1 FROM conversation_participants cp
            WHERE cp.conversation_id = conversations.id
            AND cp.user_id = auth.uid()
            AND cp.left_at IS NULL
          )
        )
      )
    )
  );
CREATE POLICY "Usuários podem adicionar participantes" ON conversation_participants FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM conversations 
      WHERE conversations.id = conversation_participants.conversation_id 
      AND conversations.type = 'group'
      AND (
        conversations.created_by = auth.uid()
        OR conversations.is_public = true
      )
    )
  );

-- Políticas de segurança para mensagens
CREATE POLICY "Usuários podem ver mensagens de suas conversas" ON messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = messages.conversation_id 
    AND conversation_participants.user_id = auth.uid()
    AND conversation_participants.left_at IS NULL
  )
);
CREATE POLICY "Usuários autenticados podem inserir mensagens" ON messages FOR INSERT WITH CHECK (
  auth.role() = 'authenticated' 
  AND auth.uid() = sender_id
  AND EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = messages.conversation_id 
    AND conversation_participants.user_id = auth.uid()
    AND conversation_participants.left_at IS NULL
  )
);
CREATE POLICY "Usuários podem atualizar suas próprias mensagens" ON messages FOR UPDATE USING (auth.uid() = sender_id);
CREATE POLICY "Usuários podem deletar suas próprias mensagens" ON messages FOR DELETE USING (auth.uid() = sender_id);

-- Políticas de segurança para indicadores de digitação
CREATE POLICY "Usuários podem ver typing indicators de suas conversas" ON typing_indicators FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants 
      WHERE conversation_participants.conversation_id = typing_indicators.conversation_id 
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.left_at IS NULL
    )
  );
CREATE POLICY "Usuários podem atualizar seus typing indicators" ON typing_indicators FOR ALL 
  USING (auth.uid() = user_id);

-- Função para criar conversa direta
CREATE OR REPLACE FUNCTION create_direct_conversation(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
  conv_id UUID;
BEGIN
  -- Tentar encontrar conversa existente
  SELECT id INTO conv_id
  FROM conversations
  WHERE type = 'direct'
    AND ((conversations.user1_id = user1_id AND conversations.user2_id = user2_id)
         OR (conversations.user1_id = user2_id AND conversations.user2_id = user1_id))
  LIMIT 1;

  -- Se não existir, criar nova
  IF conv_id IS NULL THEN
    INSERT INTO conversations (user1_id, user2_id, type)
    VALUES (user1_id, user2_id, 'direct')
    RETURNING id INTO conv_id;

    -- Adicionar participantes
    INSERT INTO conversation_participants (conversation_id, user_id)
    VALUES (conv_id, user1_id), (conv_id, user2_id);
  END IF;

  RETURN conv_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 📁 Estrutura do Projeto

```
lib/
├── config/                    # Configurações
│   └── supabase_config.dart
├── models/                    # Modelos de dados
│   ├── message.dart
│   └── user.dart
├── screens/                   # Telas do aplicativo
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── conversations_screen.dart
│   ├── new_conversation_screen.dart
│   ├── new_group_screen.dart
│   ├── search_groups_screen.dart
│   ├── group_management_screen.dart
│   ├── profile_screen.dart
│   ├── simple_profile_screen.dart
│   ├── favorites_screen.dart
│   ├── archived_screen.dart
│   ├── settings_screen.dart
│   ├── help_screen.dart
│   └── about_screen.dart
├── services/                  # Serviços e lógica de negócio
│   ├── supabase_service.dart
│   ├── local_storage_service.dart
│   └── connectivity_service.dart
├── widgets/                   # Componentes reutilizáveis
│   ├── message_bubble.dart
│   ├── message_input.dart
│   └── typing_indicator.dart
├── routes.dart               # Configuração de rotas
└── main.dart                 # Ponto de entrada
```

## 🛠️ Tecnologias Utilizadas

- **Flutter** - Framework UI multiplataforma
- **Dart** - Linguagem de programação
- **Supabase** - Backend as a Service (BaaS)
  - Autenticação
  - Banco de dados PostgreSQL
  - Realtime subscriptions
  - Row Level Security (RLS)
- **SQLite** - Cache local e suporte offline
- **flutter_dotenv** - Gerenciamento de variáveis de ambiente
- **image_picker** - Seleção de imagens
- **connectivity_plus** - Detecção de conectividade

## 🔒 Segurança

O projeto implementa diversas camadas de segurança:

- Row Level Security (RLS) no Supabase
- Autenticação JWT
- Políticas de acesso granulares
- Validação de dados no backend
- Variáveis de ambiente para credenciais sensíveis

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e pull requests.

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença especificada no arquivo [LICENSE](LICENSE).

## 🐛 Troubleshooting

### Problema: "Building with plugins requires symlink support"
**Solução:**
1. Abra as Configurações do Windows (Win + I)
2. Vá em "Privacidade e Segurança" > "Para Desenvolvedores"
3. Ative "Modo de Desenvolvedor"
4. Reinicie o terminal

### Problema: Erro ao fazer upload de imagens
**Solução:**
1. Verifique se o bucket 'messages' foi criado no Supabase Storage
2. Verifique se as políticas de Storage estão configuradas
3. Teste com uma imagem pequena primeiro (< 1MB)

### Problema: Mensagens não aparecem em tempo real
**Solução:**
1. Verifique se o Realtime está habilitado no Supabase
2. Verifique se as políticas RLS estão corretas
3. Verifique a conexão com a internet

### Problema: Erro "relation does not exist"
**Solução:**
1. Execute o script SQL completo no Supabase
2. Verifique se todas as tabelas foram criadas
3. Verifique se as funções SQL foram criadas

### Problema: Usuário não consegue fazer login
**Solução:**
1. Verifique se o email foi confirmado
2. Verifique se a senha está correta (mínimo 6 caracteres)
3. Verifique se o perfil foi criado automaticamente

### Problema: Dependências desatualizadas
**Solução:**
```bash
flutter pub upgrade
flutter pub get
```

### Problema: Erro de compilação no Windows
**Solução:**
1. Instale o Visual Studio com "Desktop development with C++"
2. Execute: `flutter doctor` para verificar problemas
3. Siga as instruções do flutter doctor

## 📧 Contato

Para dúvidas, sugestões ou feedback, entre em contato através das issues do projeto.

---

Desenvolvido com ❤️ usando Flutter e Supabase
