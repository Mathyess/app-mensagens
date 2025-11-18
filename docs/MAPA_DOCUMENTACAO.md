# 📚 Mapa de Documentação Visual

## 🗺️ Estrutura da Documentação

```
App Mensagens - Documentação Completa
│
├─ 📖 README.md (Raiz)
│  └─ Visão geral, instalação, configuração
│
├─ 📂 docs/
│  │
│  ├─ 📘 README.md (Índice)
│  │  └─ Central de navegação para todos os docs
│  │
│  ├─ 🏗️ ARQUITETURA.md
│  │  ├─ Camadas da aplicação
│  │  ├─ Fluxo de dados
│  │  ├─ Padrões de design
│  │  ├─ Banco de dados
│  │  └─ Segurança (RLS)
│  │
│  ├─ 👨‍💻 GUIA_DESENVOLVIMENTO.md
│  │  ├─ Setup ambiente
│  │  ├─ Estrutura de projeto
│  │  ├─ Padrões de código
│  │  ├─ Workflow Git
│  │  ├─ Testes
│  │  └─ Commits/PRs
│  │
│  ├─ 🗄️ BANCO_DADOS.md
│  │  ├─ Esquema (profiles, conversations, messages)
│  │  ├─ Índices
│  │  ├─ RLS Policies
│  │  ├─ Operações CRUD
│  │  └─ Migrations
│  │
│  ├─ 📡 API_SUPABASE.md
│  │  ├─ Autenticação
│  │  ├─ CRUD Operations
│  │  ├─ Real-time (Streams)
│  │  ├─ Storage (Imagens)
│  │  ├─ Tratamento de Erros
│  │  └─ Debug
│  │
│  ├─ 🧩 COMPONENTES.md
│  │  ├─ MessageBubble
│  │  ├─ MessageInput
│  │  ├─ ConversationTile
│  │  ├─ AppDrawer
│  │  ├─ Boas práticas
│  │  └─ Testes
│  │
│  └─ 🆘 TROUBLESHOOTING.md
│     ├─ Problemas comuns
│     ├─ Soluções passo a passo
│     ├─ FAQ
│     └─ Comandos úteis
│
└─ 🔗 Arquivos Relacionados
   ├─ pubspec.yaml (Dependências)
   ├─ analysis_options.yaml (Linting)
   ├─ IMPLEMENTACAO_CHAT.md (Changelog)
   └─ LICENSE
```

---

## 🎯 Fluxo de Navegação por Tipo de Usuário

### 👶 Novo Desenvolvedor

```
START
  ↓
README.md (Instalação)
  ↓
docs/GUIA_DESENVOLVIMENTO.md (Setup)
  ↓
docs/ARQUITETURA.md (Entender estrutura)
  ↓
Explorar código em lib/
  ↓
docs/COMPONENTES.md (Entender widgets)
  ↓
Pronto para contribuir! ✅
```

### 🏗️ Arquiteto de Projeto

```
START
  ↓
docs/ARQUITETURA.md (Design geral)
  ↓
docs/BANCO_DADOS.md (Schema)
  ↓
docs/API_SUPABASE.md (Integração)
  ↓
Design review ✅
```

### 🐛 Desenvolvedor em Bug Fix

```
START
  ↓
Erro encontrado
  ↓
docs/TROUBLESHOOTING.md
  ↓
Encontrou solução? → Implementar → Teste
  ↓
NÃO? → GitHub Issues
```

### 👥 Code Reviewer

```
START
  ↓
docs/GUIA_DESENVOLVIMENTO.md (Padrões)
  ↓
Revisar código
  ↓
Feedback + Aprovação ✅
```

---

## 📊 Mapa de Componentes

```
lib/
│
├─ main.dart ← Comece aqui
│  └─ Inicializa Supabase
│  └─ Define tema
│  └─ Define rotas
│
├─ routes.dart
│  └─ Define todas as rotas da app
│  └─ Ver em: docs/ARQUITETURA.md
│
├─ config/
│  └─ supabase_config.dart
│     └─ Configuração centralizada
│     └─ Ver em: README.md
│
├─ models/
│  ├─ message.dart ← Data model
│  └─ user.dart
│  └─ Ver em: docs/BANCO_DADOS.md
│
├─ services/
│  └─ supabase_service.dart ← Business Logic
│     ├─ Autenticação
│     ├─ Mensagens
│     ├─ Conversas
│     ├─ Streams
│     └─ Ver em: docs/API_SUPABASE.md
│
├─ screens/ ← UI Layers
│  ├─ splash_screen.dart
│  ├─ login_screen.dart
│  ├─ conversations_screen.dart
│  ├─ home_screen.dart
│  ├─ profile_screen.dart
│  ├─ settings_screen.dart
│  ├─ favorites_screen.dart
│  ├─ archived_screen.dart
│  ├─ help_screen.dart
│  └─ about_screen.dart
│
└─ widgets/ ← Reusable Components
   ├─ message_bubble.dart
   ├─ message_input.dart
   ├─ conversation_tile.dart
   ├─ app_drawer.dart
   └─ Ver em: docs/COMPONENTES.md

Ver em: docs/ARQUITETURA.md para detalhes
```

---

## 🔄 Fluxo de Dados

```
┌─────────────────┐
│  User Interaction│
│  (Telas/Widgets)│
└────────┬────────┘
         │ Chamada de método
         ▼
┌────────────────────────┐
│  SupabaseService       │
│  (Business Logic)      │
└────────┬───────────────┘
         │ API Call
         ▼
┌────────────────────────┐
│  Supabase Backend      │
│  (PostgreSQL + Auth)   │
└────────┬───────────────┘
         │ Response
         ▼
┌────────────────────────┐
│  Message/Stream        │
│  Renderização UI       │
└────────────────────────┘

Ver em: docs/ARQUITETURA.md → Fluxo de Dados
```

---

## 📡 Fluxo de Autenticação

```
┌──────────────────┐
│  LoginScreen     │
│  email + password│
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│ SupabaseService.signIn() │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│ Supabase Auth                    │
│ - Validate email/password        │
│ - Generate JWT Token            │
└────────┬─────────────────────────┘
         │
    ┌────┴────┐
    │          │
   SUCCESS   ERROR
    │          │
    ▼          ▼
ConversationsScreen   ErrorDialog
    │
    ├─ Salvar token
    ├─ Redirecionado
    ▼
 Ready to Chat! ✅

Ver em: docs/API_SUPABASE.md → Autenticação
```

---

## 📚 Matriz de Referência Rápida

| Dúvida | Doc | Seção |
|--------|-----|-------|
| Como instalar? | README.md | Instalação |
| Como configurar .env? | README.md | Configuração |
| Qual é a arquitetura? | ARQUITETURA.md | Visão Geral |
| Como contribuir? | GUIA_DESENVOLVIMENTO.md | Padrões de Código |
| Como fazer branch? | GUIA_DESENVOLVIMENTO.md | Workflow |
| Qual é o schema BD? | BANCO_DADOS.md | Tabelas |
| Como fazer RLS? | BANCO_DADOS.md | Row Level Security |
| Como fazer auth? | API_SUPABASE.md | Autenticação |
| Como fazer real-time? | API_SUPABASE.md | Real-time |
| O que é MessageBubble? | COMPONENTES.md | MessageBubble |
| Erro de Supabase? | TROUBLESHOOTING.md | Problema 1 |
| Mensagens não aparecem? | TROUBLESHOOTING.md | Problema 3 |

---

## 🎓 Roteiro de Aprendizado

### Semana 1: Fundação
```
📖 Dia 1-2: Leia README.md
📖 Dia 3-4: Leia ARQUITETURA.md
📖 Dia 5-7: Explore código em lib/
```

### Semana 2: Desenvolvimento
```
📖 Dia 1-2: GUIA_DESENVOLVIMENTO.md
📖 Dia 3-4: BANCO_DADOS.md
📖 Dia 5-7: Tente fazer uma feature
```

### Semana 3: Profundo
```
📖 Dia 1-2: API_SUPABASE.md
📖 Dia 3-4: COMPONENTES.md
📖 Dia 5-7: Code review e contribuições
```

### Semana 4: Expert
```
📖 Dia 1-3: Resolver issues
📖 Dia 4-5: Melhorias
📖 Dia 6-7: Otimizações e testes
```

---

## 🔗 Cross-References

### De ARQUITETURA.md
- → BANCO_DADOS.md (Estrutura BD)
- → API_SUPABASE.md (Integração)
- → COMPONENTES.md (Widgets)

### De GUIA_DESENVOLVIMENTO.md
- → ARQUITETURA.md (Design)
- → API_SUPABASE.md (APIs)
- → BANCO_DADOS.md (BD)

### De API_SUPABASE.md
- → BANCO_DADOS.md (Schema)
- → ARQUITETURA.md (Design)
- → TROUBLESHOOTING.md (Erros)

### De TROUBLESHOOTING.md
- → README.md (Setup)
- → GUIA_DESENVOLVIMENTO.md (Ambiente)
- → API_SUPABASE.md (Integração)

---

## 📈 Crescimento do Projeto

```
Versão 1.0
├─ Autenticação
├─ Chat básico
├─ Mensagens
└─ Perfil

V1.1
├─ Deletar mensagens
├─ Favoritar
└─ Arquivar

V2.0 (Planejado)
├─ Grupos
├─ Mídia
├─ Reações
└─ Busca avançada

V3.0 (Futuro)
├─ Videochamada
├─ VoIP
├─ Criptografia
└─ Offline-first
```

---

## 💡 Tips & Tricks

### Atalhos Úteis

```bash
# Format code
dart format lib/

# Analyze
dart analyze

# Test
flutter test

# Run verbose
flutter run -v

# Hot reload
r  # Em desenvolvimento
R  # Hot restart
```

### Debugging

```dart
// Adicionar logs
print('Debug: $variable');

// Usar debugPrint
debugPrint('Info: $value');

// Breakpoints em VS Code
// F5 ou use "Debug" na IDE
```

---

## 🚀 Próximos Passos

```
1. ✅ Ler README.md
2. ✅ Ler GUIA_DESENVOLVIMENTO.md
3. ⏳ Clonar repositório
4. ⏳ Configurar .env
5. ⏳ Executar flutter run
6. ⏳ Explorar código
7. ⏳ Fazer primeira contribuição
```

---

## 📞 Obter Ajuda

```
Dúvida rápida?
  └─ Veja FAQ em TROUBLESHOOTING.md

Bug encontrado?
  └─ Verifique TROUBLESHOOTING.md
  └─ Se não resolver, abra GitHub Issue

Quer contribuir?
  └─ Leia GUIA_DESENVOLVIMENTO.md
  └─ Siga o padrão de commits

Precisa de mais info?
  └─ Consulte todos os docs
  └─ Verifique links úteis em cada doc
```

---

<div align="center">

## 🎉 Parabéns!

Você tem acesso à documentação completa do App Mensagens!

**Comece pelo** [README.md](../README.md) **e navegue conforme necessário.**

[↑ Voltar ao Índice](./README.md)

</div>
