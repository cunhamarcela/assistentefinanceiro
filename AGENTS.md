# 🤖 AGENTS.md - Configuração do Codex para Assistente Financeiro

## 🎯 Objetivo Geral
Este documento define as instruções para que a IA trabalhe eficientemente no projeto **Assistente Financeiro IA**, um aplicativo Flutter com Firebase que utiliza inteligência artificial para gerenciamento financeiro pessoal.

## 📁 Estrutura do Projeto

### Tecnologias Detectadas
- **Framework Principal**: Flutter 3.16+ / Dart 3.2+
- **Arquitetura**: Clean Architecture + GetX Pattern
- **Backend**: Firebase (Auth, Firestore)
- **Gerenciamento de Estado**: GetX (get: ^4.6.6)
- **UI Framework**: Material Design + Custom Design System
- **Banco Local**: SQLite (sqflite)
- **Autenticação**: Firebase Auth + Google Sign-In + Apple Sign-In
- **Armazenamento**: SharedPreferences + FlutterSecureStorage
- **Networking**: Dio + Pretty Logger
- **Gráficos**: FL Chart
- **Localização**: Intl (pt_BR)

### Estrutura de Diretórios
```
lib/
├── core/                    # Configurações centrais
│   ├── constants/          # Constantes da aplicação
│   ├── routes/             # Roteamento (GetX)
│   ├── storage/            # Serviços de armazenamento
│   ├── theme/              # Design System (cores, tipografia, espaçamento)
│   └── utils/              # Utilitários (formatadores)
├── features/               # Funcionalidades por domínio
│   ├── auth/               # Autenticação e usuários
│   ├── expenses/           # Gestão de gastos e categorias
│   ├── profile/            # Perfil do usuário
│   ├── onboarding/         # Introdução ao app
│   └── chat/               # Chat IA (em desenvolvimento)
├── shared/                 # Componentes compartilhados
│   └── widgets/            # Widgets reutilizáveis
└── firebase_options.dart   # Configuração Firebase
```

### Padrões de Arquitetura
- **Clean Architecture**: Separação em camadas (data, domain, presentation)
- **Repository Pattern**: Abstração de fontes de dados
- **GetX Pattern**: Controllers, Bindings, Pages
- **Hybrid Storage**: Firebase + SQLite para offline-first

## 🔧 Regras de Codificação

### Dart/Flutter
- **Lint**: Seguir `package:flutter_lints/flutter.yaml`
- **Nomenclatura**: snake_case para arquivos, camelCase para variáveis
- **Imports**: Organizar em grupos (dart, flutter, packages, relative)
- **Widgets**: Preferir StatelessWidget quando possível
- **Responsividade**: Usar ScreenUtil para dimensões

### Estrutura de Features
Cada feature deve seguir:
```
feature_name/
├── data/
│   ├── datasources/        # APIs, local storage
│   ├── models/             # DTOs com JSON serialization
│   └── repositories/       # Implementação dos repositórios
├── domain/
│   ├── entities/           # Modelos de negócio
│   ├── repositories/       # Contratos abstratos
│   └── usecases/           # Casos de uso
└── presentation/
    ├── bindings/           # Injeção de dependência GetX
    ├── controllers/        # Lógica de apresentação
    ├── pages/              # Telas
    └── widgets/            # Componentes específicos
```

### Design System
- **Cores**: Usar `AppColors` — **OBRIGATÓRIO consultar `docs/DESIGN_SYSTEM_COLORS.md`**
- **Tipografia**: Usar `AppTextStyles` (hierarquia definida)
- **Componentes**: Usar widgets do `/shared/widgets/`
- **Espaçamento**: Usar `AppSpacing` para consistência
- **Regras de Cor**: Ver `.cursorrules` para regras detalhadas

## 🔄 Fluxo de Trabalho

### 1. Análise de Tarefas
- Identificar feature afetada
- Verificar dependências entre camadas
- Considerar impacto no offline-first
- Avaliar necessidade de testes

### 2. Implementação
- Começar pela camada domain (entities, repositories)
- Implementar data layer (models, datasources)
- Finalizar com presentation (controllers, pages)
- Atualizar bindings e rotas se necessário

### 3. Validação
- Verificar lints (`flutter analyze`)
- Testar funcionalidade
- Validar responsividade
- Confirmar funcionamento offline

### 4. Documentação
- Atualizar comentários em código complexo
- Documentar novos casos de uso
- Atualizar este arquivo se necessário

## 🚫 Restrições

### Não Permitido Automaticamente
- **Instalação de Packages**: Requer aprovação para novos packages
- **Alteração de Configurações Firebase**: Não modificar `firebase.json` ou `firebase_options.dart`
- **Mudanças em Build Scripts**: Android/iOS build configs requerem aprovação
- **Alteração de Dependências Core**: GetX, Firebase, ScreenUtil são críticos
- **Modificação de Entitlements**: iOS/macOS entitlements são sensíveis

### Cuidados Especiais
- **Migrações de Banco**: SQLite schemas devem ser versionados
- **Autenticação**: Não expor tokens ou credenciais
- **Armazenamento Seguro**: Usar SecureStorage para dados sensíveis
- **Offline-First**: Sempre considerar funcionamento sem internet

## 📝 Estilo de Saída

### Diffs e Alterações
- Mostrar apenas linhas modificadas com contexto mínimo
- Explicar o motivo de cada alteração
- Destacar impactos em outras partes do código
- Incluir instruções de teste quando relevante

### Explicações
- Usar linguagem técnica mas acessível
- Referenciar padrões da arquitetura
- Explicar decisões de design
- Sugerir melhorias quando apropriado

### Formato de Resposta
```markdown
## 🔧 Alterações Realizadas

### Arquivo: `lib/features/expenses/data/models/expense_model.dart`
**Motivo**: Adicionar campo para categorização automática

**Diff**:
```dart
// Linha 25-30
+ @JsonKey(name: 'auto_category')
+ final String? autoCategory;
+ 
+ @JsonKey(name: 'confidence_score')
+ final double? confidenceScore;
```

**Impacto**: Requer atualização do ExpenseRepository e casos de uso relacionados.
```

## 🔒 Segurança

### Dados Sensíveis
- **Nunca expor**: API keys, tokens, senhas
- **Logs**: Não logar informações pessoais ou financeiras
- **Armazenamento**: Usar SecureStorage para dados críticos
- **Validação**: Sempre validar inputs do usuário

### Configurações Locais
- Respeitar `local.properties` (Android)
- Não modificar certificados ou provisioning profiles
- Manter configurações de desenvolvimento separadas

### Firebase
- Não alterar regras de segurança do Firestore
- Respeitar estrutura de coleções existente
- Usar autenticação para todas as operações

## 🎨 Design System

### Componentes Disponíveis
- **AppButton**: Botões com variações (primary, secondary, outline)
- **AppTextField**: Campos de texto especializados (email, senha, moeda)
- **AppCard**: Cards padronizados (HomeCard, ExpenseCard, SummaryCard)
- **CategoryCard**: Card para exibição de categorias
- **ExpenseCard**: Card para exibição de gastos

### Padrões Visuais
- **Paleta Oficial**: Navy (#0A1931, #1A3D63), Blue (#4A7FA7, #B3CFE5), Accent (#3CB371)
- **Gradientes**: Usar apenas os 2 gradientes oficiais (ver `DESIGN_SYSTEM_COLORS.md`)
- **Bordas**: Radius padrão 12px, cards 16px
- **Sombras**: Elevation sutil, evitar sombras pesadas
- **Ícones**: Cupertino Icons como padrão
- **⚠️ PROIBIDO**: Cores hardcoded (HEX/RGB direto no código)

## 📱 Funcionalidades Implementadas

### ✅ Completas
- Sistema de autenticação (email, Google, Apple)
- Gerenciamento de gastos com categorização
- Perfil completo com configurações
- Onboarding interativo
- Design system completo
- Armazenamento híbrido (online/offline)

### 🚧 Em Desenvolvimento
- Chat com IA financeira
- Relatórios avançados
- Sincronização bancária
- Notificações push

### 📋 Roadmap
- Metas financeiras
- Análise preditiva
- Compartilhamento de relatórios
- Modo família

---

## 📚 Documentação de Referência

| Documento | Caminho | Propósito |
|-----------|---------|-----------|
| Design System Cores | `docs/DESIGN_SYSTEM_COLORS.md` | Fonte de verdade para cores |
| Cursor Rules | `.cursorrules` | Regras automáticas para IA |
| Implementação Cores | `lib/core/theme/app_colors.dart` | Tokens de cor |
| Tema Global | `lib/core/theme/app_theme.dart` | ThemeData Flutter |

---

**Versão**: 1.1.0  
**Última Atualização**: Dezembro 2024  
**Mantenedor**: Assistente Financeiro IA Team

