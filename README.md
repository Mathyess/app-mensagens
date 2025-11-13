# 💬 App Mensagens

> Um aplicativo de mensagens em tempo real moderno construído com **Flutter** e **Supabase**, oferecendo uma experiência de chat fluida e responsiva.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green)](#license)

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Funcionalidades](#funcionalidades)
- [Documentação Técnica](#documentação-técnica)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

## 🎯 Visão Geral

O **App Mensagens** é uma aplicação de chat em tempo real que permite que usuários se comuniquem de forma segura e instantânea. Com autenticação robusta, gerenciamento de conversas e suporte a mídia, oferece uma experiência de mensageria completa.

### Principais Características:
- ✨ Chat em tempo real com WebSocket
- 🔐 Autenticação segura com Supabase Auth
- 📱 Interface responsiva com Material Design 3
- 🖼️ Suporte a imagens e mídia
- 🎯 Conversas privadas entre usuários
- 🗑️ Gestão de mensagens (deletar para você ou para todos)
- ⭐ Favoritar conversas
- 📤 Arquivar conversas
- 👤 Perfis de usuário personalizáveis
- 🔔 Notificações em tempo real

## 📦 Requisitos

Antes de começar, certifique-se que você tem:

- **Flutter** 3.0 ou superior
- **Dart** 3.0 ou superior
- **Git**
- Uma conta no [Supabase](https://supabase.com) (gratuito)
- Um editor (VS Code, Android Studio ou IntelliJ)

### Verificar a instalação:

```bash
flutter --version
dart --version
```

## 🚀 Instalação

### 1. Clonar o repositório

```bash
git clone https://github.com/Mathyess/app-mensagens.git
cd app-mensagens
```

### 2. Instalar dependências

```bash
flutter pub get
```

### 3. Executar geradores de código (se necessário)

```bash
flutter pub run build_runner build
```

## ⚙️ Configuração

### 1. Configurar Supabase

1. Acesse [Supabase](https://supabase.com) e crie uma nova conta
2. Crie um novo projeto
3. Vá para a seção **Settings > API** para obter:
   - **Project URL** (SUPABASE_URL)
   - **Anon Key** (SUPABASE_ANON_KEY)

### 2. Criar arquivo de configuração

Crie um arquivo `.env` na raiz do projeto:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua_chave_anonima_super_secreta_aqui
```

⚠️ **NUNCA** faça commit do arquivo `.env` com dados reais. Adicione-o ao `.gitignore`.

### 3. Configurar banco de dados

Abra o **SQL Editor** no painel do Supabase e execute o script:

```sql
-- Tabela de Perfis de Usuários
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Conversas
CREATE TABLE IF NOT EXISTS conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES auth.users(id) NOT NULL,
  user2_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE,
  is_favorite BOOLEAN DEFAULT FALSE,
  UNIQUE(user1_id, user2_id)
);

-- Tabela de Mensagens
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID REFERENCES conversations(id) NOT NULL,
  sender_id UUID REFERENCES auth.users(id) NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  is_deleted_for_everyone BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_conversations_user1 ON conversations(user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2 ON conversations(user2_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_deleted_for_everyone ON messages(is_deleted_for_everyone);

-- Habilitar RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
```

### 4. Executar a aplicação

#### No Android/iOS:
```bash
flutter run
```

#### Na Web:
```bash
flutter run -d chrome
```

#### No Windows/macOS/Linux:
```bash
flutter run -d windows   # ou macos, linux
```

## 📂 Estrutura do Projeto

```
app-mensagens/
├── lib/
│   ├── main.dart                 # Arquivo principal da aplicação
│   ├── routes.dart               # Definição de rotas
│   ├── config/
│   │   └── supabase_config.dart  # Configuração do Supabase
│   ├── models/
│   │   ├── message.dart          # Modelo de mensagem
│   │   └── user.dart             # Modelo de usuário
│   ├── screens/
│   │   ├── splash_screen.dart    # Tela inicial
│   │   ├── login_screen.dart     # Tela de login
│   │   ├── conversations_screen.dart # Tela de conversas
│   │   ├── home_screen.dart      # Tela de chat
│   │   ├── profile_screen.dart   # Tela de perfil
│   │   ├── settings_screen.dart  # Tela de configurações
│   │   ├── favorites_screen.dart # Tela de favoritos
│   │   ├── archived_screen.dart  # Tela de conversas arquivadas
│   │   ├── help_screen.dart      # Tela de ajuda
│   │   └── about_screen.dart     # Tela sobre o app
│   ├── services/
│   │   └── supabase_service.dart # Serviço Supabase
│   └── widgets/
│       ├── app_drawer.dart       # Gaveta de navegação
│       ├── conversation_tile.dart # Item de conversa
│       ├── message_bubble.dart   # Bolha de mensagem
│       └── message_input.dart    # Input de mensagem
├── test/
│   └── widget_test.dart          # Testes
├── pubspec.yaml                  # Dependências
├── .env                          # Variáveis de ambiente
└── README.md                     # Este arquivo
```

## ✨ Funcionalidades

### 🔐 Autenticação
- Registro de novo usuário
- Login com email e senha
- Logout seguro
- Recuperação de senha
- Confirmação de email

### 💬 Mensageria
- Envio de mensagens em tempo real
- Suporte a imagens
- Deletar mensagens para você ou para todos
- Editar mensagens (futuro)
- Reações em mensagens (futuro)

### 👥 Conversas
- Criar novas conversas
- Listar conversas ativas
- Favoritar conversas
- Arquivar conversas
- Buscar conversas

### 👤 Perfil
- Visualizar perfil pessoal
- Editar informações de perfil
- Alterar avatar
- Visualizar perfis de outros usuários

### ⚙️ Configurações
- Notificações
- Privacidade
- Tema (claro/escuro)
- Idioma (futuro)

## 📚 Documentação Técnica

Para documentação mais detalhada, consulte:

- [🔧 ARQUITETURA.md](./docs/ARQUITETURA.md) - Arquitetura e padrões de design
- [📖 GUIA_DESENVOLVIMENTO.md](./docs/GUIA_DESENVOLVIMENTO.md) - Guia para contribuidores
- [🗄️ BANCO_DADOS.md](./docs/BANCO_DADOS.md) - Esquema do banco de dados
- [📡 API_SUPABASE.md](./docs/API_SUPABASE.md) - Integração com Supabase
- [🧩 COMPONENTES.md](./docs/COMPONENTES.md) - Documentação dos widgets

## 🔧 Tecnologias Utilizadas

### Frontend
- **Flutter** 3.0+ - Framework UI multiplataforma
- **Dart** 3.0+ - Linguagem de programação
- **Material Design 3** - Design system

### Backend
- **Supabase** - Backend as a Service (BaaS)
- **PostgreSQL** - Banco de dados relacional
- **PostgREST** - API REST automática
- **GoTrue** - Autenticação JWT

### Pacotes Flutter
- `supabase_flutter` - Cliente Supabase oficial
- `flutter_dotenv` - Gerenciamento de variáveis de ambiente
- `image_picker` - Seleção de imagens
- `package_info_plus` - Informações do app

## 🧪 Testes

Executar testes:

```bash
flutter test
```

Executar testes com cobertura:

```bash
flutter test --coverage
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Siga estes passos:

1. **Fork** o repositório
2. Crie uma **branch** para sua feature (`git checkout -b feature/MinhaFeature`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. **Push** para a branch (`git push origin feature/MinhaFeature`)
5. Abra um **Pull Request**

### Padrões de Código

- Use `dart format` para formatar código
- Use `dart analyze` para verificar issues
- Escreva commits descritivos em português ou inglês
- Adicione testes para novas funcionalidades

## 📝 Changelog

Veja o arquivo [CHANGELOG.md](./CHANGELOG.md) para histórico de versões.

## 🐛 Reportar Bugs

Encontrou um bug? Abra uma [Issue](https://github.com/Mathyess/app-mensagens/issues) com:

- Descrição clara do problema
- Passos para reproduzir
- Comportamento esperado
- Screenshots (se aplicável)
- Versão do Flutter e SO

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](./LICENSE) para mais detalhes.

## 📞 Contato

- **GitHub**: [@Mathyess](https://github.com/Mathyess)
- **Issues**: [GitHub Issues](https://github.com/Mathyess/app-mensagens/issues)

---

<div align="center">

**Feito com ❤️ por [Mathyess](https://github.com/Mathyess)**

⭐ Se este projeto foi útil, considere dar uma estrela!

</div>
````

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