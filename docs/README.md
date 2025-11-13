# 📚 Índice de Documentação

## Bem-vindo à Documentação do App Mensagens! 👋

Você encontrará aqui toda a documentação técnica, guias de desenvolvimento e referências do projeto.

## 🗂️ Estrutura de Documentação

### 📖 Documentação Geral

1. **[README.md](../README.md)** 
   - ℹ️ Visão geral do projeto
   - 🚀 Instruções de instalação
   - ⚙️ Configuração inicial
   - 📦 Tecnologias utilizadas

### 🏗️ Arquitetura e Design

2. **[ARQUITETURA.md](./ARQUITETURA.md)** 
   - 🎯 Padrão de arquitetura em camadas
   - 📊 Fluxo de dados
   - 🔄 Padrões de design utilizados
   - 🗄️ Estrutura do banco de dados
   - 🛡️ Segurança

### 👨‍💻 Desenvolvimento

3. **[GUIA_DESENVOLVIMENTO.md](./GUIA_DESENVOLVIMENTO.md)**
   - 🔧 Setup do ambiente
   - 📋 Padrões de código
   - 🔄 Workflow de desenvolvimento
   - 🧪 Testes e debug
   - 📮 Commits e Pull Requests

### 🗄️ Banco de Dados

4. **[BANCO_DADOS.md](./BANCO_DADOS.md)**
   - 📊 Esquema do banco de dados
   - 🔑 Relacionamentos entre tabelas
   - 📋 CRUD operations
   - 🔐 Row Level Security (RLS)
   - 🔧 Migrations

### 📡 APIs e Integração

5. **[API_SUPABASE.md](./API_SUPABASE.md)**
   - 🔑 Autenticação
   - 💾 Operações de banco de dados
   - 📡 Real-time (Streams)
   - 🖼️ Armazenamento (Storage)
   - 🐛 Debug e tratamento de erros

### 🧩 Componentes

6. **[COMPONENTES.md](./COMPONENTES.md)**
   - 🧩 Widgets customizados
   - 📝 MessageBubble
   - ⌨️ MessageInput
   - 👥 ConversationTile
   - 🎯 AppDrawer

### 🆘 Troubleshooting

7. **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**
   - 🔴 Problemas comuns
   - ✅ Soluções passo a passo
   - 📋 FAQ
   - 🔧 Comandos úteis

---

## 🎯 Por Onde Começar?

### Sou Novo no Projeto

```
1. Leia: README.md
2. Leia: GUIA_DESENVOLVIMENTO.md (seção Setup)
3. Comece: Explore o código em lib/
```

### Preciso Entender a Arquitetura

```
1. Leia: ARQUITETURA.md
2. Leia: BANCO_DADOS.md
3. Consulte: Arquivos em lib/
```

### Estou Desenvolvendo uma Funcionalidade

```
1. Consulte: GUIA_DESENVOLVIMENTO.md
2. Consulte: COMPONENTES.md (se for UI)
3. Consulte: API_SUPABASE.md (se for backend)
4. Se tiver dúvida: TROUBLESHOOTING.md
```

### Encontrei um Bug

```
1. Verifique: TROUBLESHOOTING.md
2. Se persistir: Abra uma Issue no GitHub
```

---

## 📂 Estrutura de Pastas de Documentação

```
docs/
├── README.md (Este arquivo)
├── ARQUITETURA.md
├── GUIA_DESENVOLVIMENTO.md
├── BANCO_DADOS.md
├── API_SUPABASE.md
├── COMPONENTES.md
└── TROUBLESHOOTING.md
```

---

## 🔍 Guias Rápidos

### Instalar Projeto

```bash
git clone https://github.com/Mathyess/app-mensagens.git
cd app-mensagens
flutter pub get
# Configure .env
flutter run
```

### Criar Nova Feature

```bash
git checkout -b feature/minha-feature
# Fazer alterações
flutter test
dart format lib/
git commit -m "feat: descrição"
git push origin feature/minha-feature
# Abrir Pull Request
```

### Verificar Estilo de Código

```bash
dart format lib/
dart analyze
flutter test
```

### Debugar Aplicação

```bash
flutter run -v
# Ou usar DevTools
devtools
```

---

## 🏆 Convenções do Projeto

### Nomes de Arquivo

- **Screens**: `*_screen.dart` → `login_screen.dart`
- **Widgets**: `*_widget.dart` ou `*.dart` → `message_bubble.dart`
- **Models**: `*.dart` → `message.dart`
- **Services**: `*_service.dart` → `supabase_service.dart`

### Nomes de Variáveis

- **Classes**: `PascalCase` → `class UserProfile {}`
- **Functions**: `camelCase` → `void getUserData() {}`
- **Const/Final**: `camelCase` → `final String userName = '';`
- **Private**: Prefixo `_` → `_privateVariable`

### Commits

- `feat:` Novas funcionalidades
- `fix:` Correções de bugs
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `perf:` Performance
- `test:` Testes

### Branches

- `main` - Produção
- `feature/` - Novas features
- `bugfix/` - Correções
- `doc/` - Documentação

---

## 🔗 Links Úteis

### Documentação Oficial

- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Supabase Docs](https://supabase.com/docs)
- [Material Design 3](https://m3.material.io/)

### Ferramentas

- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Android Studio](https://developer.android.com/studio)
- [VS Code](https://code.visualstudio.com/)

### Comunidade

- [Flutter Community](https://flutter.dev/community)
- [Dart Community](https://dart.dev/community)
- [Supabase Community](https://supabase.com/community)

---

## 📊 Estatísticas do Projeto

```
Linguagem: Dart
Framework: Flutter
Backend: Supabase
Banco: PostgreSQL
Plataformas: Android, iOS, Web, Windows, macOS, Linux
```

---

## 🤝 Contribuindo

Este é um projeto open-source! Contribuições são bem-vindas.

**Como contribuir:**

1. Fork o repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

**Padrões:**
- Siga as convenções de código
- Escreva testes
- Atualize documentação
- Commits claros

Veja [GUIA_DESENVOLVIMENTO.md](./GUIA_DESENVOLVIMENTO.md) para detalhes.

---

## 📝 Changelog

Veja as mudanças recentes em [IMPLEMENTACAO_CHAT.md](../IMPLEMENTACAO_CHAT.md)

---

## 📞 Suporte

- **GitHub Issues**: [Abrir Issue](https://github.com/Mathyess/app-mensagens/issues)
- **Discussões**: [GitHub Discussions](https://github.com/Mathyess/app-mensagens/discussions)
- **Email**: Contato via GitHub

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](../LICENSE) para detalhes.

---

## 👨‍💻 Autor

**Mathyess** - [@Mathyess](https://github.com/Mathyess)

---

## 🙏 Agradecimentos

- Flutter Team
- Supabase Team
- Comunidade Open Source
- Contribuidores

---

<div align="center">

**Última atualização**: Novembro 2024

⭐ Se este projeto foi útil, considere dar uma estrela!

[GitHub](https://github.com/Mathyess/app-mensagens) • [Documentação](./README.md)

</div>
