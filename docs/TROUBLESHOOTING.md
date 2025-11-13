# 🆘 Troubleshooting e FAQ

## Visão Geral

Guia rápido para resolver problemas comuns no App Mensagens.

## 🔴 Problemas Comuns

### 1. "Supabase não inicializa"

#### Sintomas
```
❌ Erro ao inicializar Supabase: ...
Aplicativo não inicia ou trava na splash screen
```

#### Possíveis Causas
- Arquivo `.env` não existe ou está vazio
- Variáveis de ambiente incorretas
- Sem conexão de internet

#### Soluções

**Passo 1**: Verificar arquivo `.env`

```bash
# Verificar se existe
ls -la | grep .env

# Conteúdo deve ser:
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua_chave_anonima_aqui
```

**Passo 2**: Verificar credenciais Supabase

1. Acesse [Supabase Console](https://app.supabase.com)
2. Vá para **Project Settings > API**
3. Copie a URL exata
4. Copie a chave anônima (não a service role key!)

**Passo 3**: Limpar cache e reconstruir

```bash
flutter clean
flutter pub get
flutter run -v
```

**Passo 4**: Verificar internet

```bash
# No Windows PowerShell
Test-NetConnection -ComputerName supabase.co -Port 443
```

---

### 2. "Erro de autenticação"

#### Sintomas
```
❌ Email ou senha incorretos
❌ CONFIRM_EMAIL
❌ User already registered
```

#### Possíveis Causas
- Email/senha errados
- Conta não existe
- Email não foi confirmado
- Rate limiting (429)

#### Soluções

**Para "Email ou senha incorretos"**
- Verifique capitalização
- Certifique-se da senha correta
- Tente criar nova conta

**Para "CONFIRM_EMAIL"**
1. Verifique sua caixa de entrada
2. Procure por email de confirmação
3. Clique no link
4. Tente fazer login novamente

**Para "User already registered"**
- Tente fazer login em vez de registrar
- Se esqueceu a senha, use recuperação

**Para Rate Limiting (429)**
- Aguarde 45 segundos
- Não tente múltiplas vezes seguidas

---

### 3. "Mensagens não aparecem em tempo real"

#### Sintomas
```
- Envio mensagem, mas não aparece imediatamente
- Precisa recarregar para ver
- Stream não está funcionando
```

#### Possíveis Causas
- Stream não inicializado
- Conexão de internet instável
- Supabase real-time não habilitado

#### Soluções

**Passo 1**: Habilitar real-time no Supabase

1. Acesse [Supabase Console](https://app.supabase.com)
2. Vá para **Database > Replication**
3. Habilite replicação para tabela `messages`

**Passo 2**: Verificar stream no código

```dart
// Em HomeScreen
@override
void initState() {
  super.initState();
  // Certifique-se que está criando o stream
  _messagesStream = SupabaseService.getMessagesStream(conversationId);
}
```

**Passo 3**: Fazer dispose correto

```dart
@override
void dispose() {
  // Limpar stream ao sair
  SupabaseService.disposeMessageStream(conversationId);
  super.dispose();
}
```

**Passo 4**: Verificar conexão

```bash
flutter run -v
# Procurar por "Connected" ou "Disconnected"
```

---

### 4. "Erro ao enviar mensagem"

#### Sintomas
```
❌ Erro ao enviar mensagem
❌ 403 Forbidden
❌ 401 Unauthorized
```

#### Possíveis Causas
- Não autenticado
- RLS bloqueando acesso
- Conversa não existe

#### Soluções

**Verificar autenticação**

```dart
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  print('Não autenticado!');
} else {
  print('Autenticado como: ${user.email}');
}
```

**Verificar se conversa existe**

```dart
// Antes de enviar mensagem
final conversation = await SupabaseService.getConversation(conversationId);
if (conversation == null) {
  print('Conversa não encontrada');
}
```

**Verificar RLS no Supabase**

1. Acesse **Database > Policies**
2. Verifique `messages` table
3. Certifique-se que política permite INSERT

```sql
-- Exemplo de política correta
CREATE POLICY "Users can insert messages in their conversations"
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

---

### 5. "Imagens não carregam"

#### Sintomas
```
- Ícone de imagem quebrado
- Imagem não aparece após envio
- Erro ao fazer upload
```

#### Possíveis Causas
- Sem permissão para fazer upload
- Storage bucket não existe
- URL expirada

#### Soluções

**Verificar Storage Bucket**

1. Acesse **Storage > Buckets**
2. Crie bucket chamado `messages-storage` se não existir
3. Configure permissões públicas

**Tester Upload Manual**

```bash
# No Supabase Console
# Storage > messages-storage > Upload File
# Teste se consegue fazer upload manualmente
```

**Verificar Código**

```dart
// Certifique-se que está usando o bucket correto
await _client.storage
  .from('messages-storage')  // Nome correto do bucket
  .upload(path, File(pickedFile.path));
```

---

### 6. "Hot Reload não funciona"

#### Sintomas
```
- Alterações no código não refletem no app
- Precisa fazer rebuild completo
- Hot Reload estava funcionando mas parou
```

#### Soluções

**Tentar Hot Reload**

```bash
# No terminal do Flutter
r  # Hot Reload

# Se não funcionar:
R  # Hot Restart
```

**Reconstruir Completamente**

```bash
flutter clean
flutter pub get
flutter run
```

**Verificar se houve mudanças de tipo**

Hot Reload não funciona com:
- Mudanças em classe (adicionar campo)
- Mudanças em função (mudar assinatura)
- Mudanças em tipos

Para esses casos, use **Hot Restart** (R) ou **rebuild completo**.

---

### 7. "Erro de conexão com Supabase"

#### Sintomas
```
❌ Network error
❌ Connection timeout
❌ Failed to resolve host
```

#### Possíveis Causas
- Sem internet
- URL Supabase incorreta
- Firewall bloqueando
- Supabase offline

#### Soluções

**Verificar Internet**

```bash
# Windows PowerShell
Test-NetConnection -ComputerName 8.8.8.8 -Port 53

# Se falhar, reconecte à internet
```

**Verificar URL Supabase**

```bash
# No arquivo .env
# URL deve ser:
# https://seu-id.supabase.co
# NÃO:
# https://seu-projeto.supabase.co (ERRADO)
# https://localhost:3000 (DEV APENAS)
```

**Testar Conexão**

```bash
# Windows PowerShell
curl -I https://seu-id.supabase.co

# Se respondeu 200, tá funcionando
```

**Verificar Status Supabase**

1. Acesse [Supabase Status](https://status.supabase.com)
2. Verifique se há incidentes
3. Se estiver down, aguarde

---

### 8. "Muita lentidão/Lag"

#### Sintomas
```
- App responde lento
- Scroll com problema
- Mensagens demoram para aparecer
```

#### Possíveis Causas
- Muitas mensagens carregadas
- Imagens grandes
- Conexão lenta

#### Soluções

**Implementar Paginação**

```dart
// Em vez de carregar todas as mensagens
// Carregar apenas as últimas 50

final messages = await _client
  .from('messages')
  .select()
  .eq('conversation_id', conversationId)
  .order('created_at', ascending: false)
  .limit(50)  // ← Adicionar LIMIT
  .then((data) => data.reversed.toList());
```

**Otimizar Imagens**

```dart
// Usar imagens menores/comprimidas
// Em vez de imagem full resolution
Image.network(
  imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)
```

**Usar ListView.builder em vez de ListView**

```dart
// ❌ RUIM - Carrega tudo
ListView(
  children: messages.map((msg) => MessageBubble(...)).toList(),
)

// ✅ BOM - Carrega sob demanda
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) => MessageBubble(
    message: messages[index],
  ),
)
```

---

## 📋 FAQ

### P: Como fazer reset completo da app?

**R:**
```bash
flutter clean
rm -r .dart_tool
rm pubspec.lock
flutter pub get
flutter run
```

### P: Como debugar requisições Supabase?

**R:**
```dart
// Em main.dart
if (kDebugMode) {
  Supabase.instance.client.enableLogging();
}

// Agora todas requisições serão logadas
```

### P: Como adicionar nova tabela ao Supabase?

**R:**
1. Acesse Supabase Console
2. Vá para **SQL Editor**
3. Cole o script CREATE TABLE
4. Execute

Exemplo:
```sql
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  message TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### P: Como resetar senha?

**R:**
1. Na tela de login, clique "Esqueci a senha"
2. Digite seu email
3. Verifique caixa de entrada
4. Clique no link
5. Digite nova senha

### P: Como mudar password do Supabase?

**R:**
```dart
await Supabase.instance.client.auth.updateUser(
  UserAttributes(password: 'nova_senha'),
);
```

### P: Como exportar dados do Supabase?

**R:**
1. Acesse Supabase Console
2. **Database > Backups**
3. Clique "Request a backup"
4. Aguarde conclusão
5. Download

### P: Posso usar Supabase offline?

**R:**
Não diretamente. Mas você pode:
1. Implementar cache local com Hive/Drift
2. Sincronizar quando conectar
3. Ver exemplo em `docs/ARQUITETURA.md`

### P: Como fazer deploy do app?

**R:**
Depende da plataforma:

**Android:**
```bash
flutter build apk
flutter build appbundle
```

**iOS:**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

**Windows/macOS/Linux:**
```bash
flutter build windows
flutter build macos
flutter build linux
```

---

## 🔧 Comandos Úteis

```bash
# Verificar saúde
flutter doctor

# Limpar tudo
flutter clean

# Obter dependências
flutter pub get

# Formatar código
dart format lib/

# Analisar código
dart analyze

# Rodar testes
flutter test

# Rodar com logs
flutter run -v

# Rodar em dispositivo específico
flutter run -d <device-id>

# Listar dispositivos
flutter devices

# Ver versão
flutter --version
```

---

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/Mathyess/app-mensagens/issues)
- **Email**: Contato via GitHub
- **Documentação**: `docs/` folder

---

## 📚 Próximos Passos

Se os passos acima não resolveram seu problema:

1. Verifique a [Documentação Completa](./ARQUITETURA.md)
2. Procure por issue similar no GitHub
3. Abra uma nova issue com:
   - Descrição clara do problema
   - Passos para reproduzir
   - Logs completos (flutter run -v)
   - Screenshots se aplicável
   - Versão do Flutter

---

**Boa sorte! 🍀**
