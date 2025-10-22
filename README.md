# WeTalk 💜

Um aplicativo de mensagens em tempo real moderno e elegante, construído com Flutter e Supabase.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 📖 Sobre

WeTalk é um aplicativo de mensagens instantâneas moderno, desenvolvido com Flutter e Supabase, que oferece comunicação em tempo real com uma interface elegante e intuitiva. Com foco na simplicidade e performance, o WeTalk permite que você converse com seus contatos de forma rápida e segura.

### 🌟 Destaques

- **💬 Mensagens em Tempo Real**: Receba e envie mensagens instantaneamente
- **🎨 Design Moderno**: Interface elegante com tema roxo e experiência fluida
- **🔒 Segurança**: Autenticação robusta e políticas de segurança no banco de dados
- **⚡ Performance**: Atualização otimizada de mensagens com streams eficientes
- **📱 Multiplataforma**: Funciona em web, mobile e desktop

## ⚙️ Configuração

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

## ✨ Funcionalidades

### 🔐 Autenticação
- ✅ Login e cadastro de usuários
- ✅ Confirmação de email com mensagem amigável
- ✅ Gerenciamento seguro de sessão

### 💬 Mensagens
- ✅ Envio e recebimento de mensagens em tempo real
- ✅ Atualização instantânea do histórico de mensagens
- ✅ Ordenação correta das mensagens (mais antigas em cima, mais recentes em baixo)
- ✅ Scroll automático para mensagens novas
- ✅ Indicador visual de mensagens enviadas/recebidas
- ✅ Formatação de hora das mensagens

### 👥 Conversas
- ✅ Lista de conversas com preview da última mensagem
- ✅ Busca de conversas
- ✅ Adicionar novos contatos por email
- ✅ Avatar com gradiente personalizado para cada usuário
- ✅ Sistema de conversas individuais

### 🎨 Interface
- ✅ Design moderno com tema roxo elegante
- ✅ Interface responsiva e fluida
- ✅ Animações suaves
- ✅ Tela de perfil simplificada
- ✅ Campo de mensagem minimalista (apenas texto e enviar)

### 🔧 Técnico
- ✅ Integração completa com Supabase
- ✅ Real-time subscriptions para atualizações instantâneas
- ✅ Row Level Security (RLS) configurado
- ✅ Gerenciamento eficiente de estado
- ✅ Suporte para web e mobile

## 🚀 Próximos Passos

- [ ] Implementar upload de imagens nas mensagens
- [ ] Adicionar notificações push
- [ ] Criar grupos de conversa
- [ ] Sistema de busca de mensagens
- [ ] Mensagens de voz
- [ ] Compartilhamento de arquivos
- [ ] Status online/offline dos usuários
- [ ] Indicador de "digitando..."
- [ ] Confirmação de leitura de mensagens
- [ ] Temas personalizáveis

## 🎨 Design

O WeTalk possui um design moderno e elegante com as seguintes características:

- **Paleta de cores**: Roxo como cor primária (#8B5CF6), com tons escuros para o fundo
- **Tipografia**: Sans-serif moderna e legível
- **Componentes**: Cards arredondados, botões com feedback visual, inputs com foco destacado
- **Experiência**: Interface limpa e minimalista, focada na comunicação

## 📱 Plataformas Suportadas

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Android (em desenvolvimento)
- ✅ iOS (em desenvolvimento)
- ✅ Windows (em desenvolvimento)

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e pull requests.

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Autor

Desenvolvido com 💜 por [Mathyes](https://github.com/Mathyess)