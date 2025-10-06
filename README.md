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
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela de mensagens
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT NOT NULL,
  sender_id UUID REFERENCES auth.users(id) NOT NULL,
  sender_name TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Perfis são visíveis para todos" ON profiles FOR SELECT USING (true);
CREATE POLICY "Usuários podem inserir seu próprio perfil" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Mensagens são visíveis para todos" ON messages FOR SELECT USING (true);
CREATE POLICY "Usuários autenticados podem inserir mensagens" ON messages FOR INSERT WITH CHECK (auth.role() = 'authenticated');
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
- ✅ Envio de mensagens em tempo real
- ✅ Interface responsiva e moderna
- ✅ Integração com Supabase
- ✅ Gerenciamento de estado
- ✅ Navegação entre telas

## Próximos Passos

- [ ] Upload de imagens
- [ ] Notificações push
- [ ] Grupos de conversa
- [ ] Status online/offline
- [ ] Busca de mensagens