# 📊 Sistema de Logging - Assistente Financeiro IA

## 🎯 Visão Geral

O sistema de logging foi implementado para fornecer visibilidade completa sobre o funcionamento do aplicativo, permitindo:

- ✅ Identificar o que está funcionando bem
- ❌ Detectar o que não está funcionando
- ⚠️ Encontrar funcionalidades incompletas
- 🔄 Monitorar sincronização com o banco de dados
- 🧠 Entender a lógica de cada feature baseada nas interações do usuário

---

## 🏗️ Arquitetura

### Componentes Principais

```
┌─────────────────────────────────────────────────────────┐
│                     AppLogger                           │
│           (Helper estático para uso fácil)              │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  LoggingService                         │
│         (Serviço centralizado de logging)               │
├─────────────────────────────────────────────────────────┤
│  • Níveis: debug, info, warning, error, critical        │
│  • Integração Firebase Analytics                        │
│  • Integração Crash Reporting                           │
│  • Logs estruturados com tags e dados                   │
└───────────────────────┬─────────────────────────────────┘
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│  Firebase Analytics │     │ CrashReportingService│
│   (Eventos/Métricas)│     │    (Crashlytics)     │
└─────────────────────┘     └─────────────────────┘
```

### Arquivos do Sistema

| Arquivo | Localização | Função |
|---------|-------------|--------|
| `logging_service.dart` | `lib/core/services/` | Serviço principal de logging |
| `app_logger.dart` | `lib/core/services/` | Helper para uso simplificado |
| `crash_reporting_service.dart` | `lib/core/services/` | Integração com Crashlytics |

---

## 📝 Níveis de Log

| Nível | Emoji | Uso | Destino |
|-------|-------|-----|---------|
| `debug` | 🔍 | Informações detalhadas para desenvolvimento | Console (apenas debug mode) |
| `info` | ℹ️ | Eventos importantes do fluxo normal | Console + Analytics |
| `warning` | ⚠️ | Situações inesperadas mas recuperáveis | Console + Crashlytics |
| `error` | ❌ | Erros que afetam funcionalidade | Console + Crashlytics + Error Report |
| `critical` | 🚨 | Erros fatais ou de segurança | Console + Crashlytics + Fatal Report |

---

## 🎮 Uso do AppLogger

### Sintaxe Básica

```dart
import '../../../../core/services/app_logger.dart';

// Debug (apenas em desenvolvimento)
AppLogger.debug('TAG', 'Mensagem detalhada', data: {'key': 'value'});

// Info (eventos normais)
AppLogger.info('TAG', 'Operação realizada com sucesso');

// Warning (atenção necessária)
AppLogger.warning('TAG', 'Situação inesperada', data: {'context': info});

// Error (erro recuperável)
AppLogger.error('TAG', 'Falha na operação', error: e, stackTrace: stack);

// Critical (erro fatal)
AppLogger.critical('TAG', 'Erro crítico de segurança', error: e);
```

### Analytics e Eventos

```dart
// Evento customizado
await AppLogger.event('button_clicked', parameters: {'button': 'submit'});

// Tela visualizada
await AppLogger.screenView('HomePage', 'HomePage');

// Propriedades do usuário
await AppLogger.setUserProperty('plan', 'premium');
await AppLogger.setUserId('user_123');
```

---

## 📱 Features com Logging Implementado

### 1. 🔐 Autenticação (`AuthController`)

**Tag:** `AuthController`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Inicialização | info | Controller inicializado |
| Login iniciado | info | Início do processo de login |
| Formulário inválido | warning | Validação falhou |
| Login sucesso | info | Login realizado |
| Erro de autenticação | warning | Credenciais inválidas |
| Erro inesperado | error | Exceção não tratada |
| Logout | info | Usuário deslogou |
| Conta deletada | info | Conta removida |

**Exemplo de Log:**
```
ℹ️ [2024-12-17T10:30:00] [AuthController] Login com email bem-sucedido
   Dados: {email: user@email.com, method: email}
```

### 2. 💰 Despesas (`ExpenseController`)

**Tag:** `ExpenseController`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Carregamento inicial | info | Início do carregamento |
| Despesas carregadas | info | Lista atualizada |
| Despesa adicionada | info | Nova despesa criada |
| Despesa atualizada | info | Despesa modificada |
| Despesa removida | info | Despesa deletada |
| Filtros aplicados | debug | Filtros alterados |
| Erro de carregamento | error | Falha ao buscar dados |

**Métricas Automáticas:**
- Total de despesas carregadas
- Categoria da despesa
- Valor da despesa
- Método de pagamento

### 3. 🔄 Sincronização (`ExpenseHybridRepository`)

**Tag:** `ExpenseHybridRepository`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Salvar local | debug | Gravação no SQLite |
| Salvar remoto | debug | Envio ao Firestore |
| Sync background | info | Sincronização em segundo plano |
| Firestore indisponível | warning | Falha de conexão (offline mode) |
| Sync completa | info | Sincronização bem-sucedida |
| Erro crítico | error | Falha irrecuperável |

**Fluxo de Sincronização:**
```
1. Usuário adiciona despesa
2. ✅ Salva localmente (SQLite) - imediato
3. 🔄 Envia para Firestore em background
   └── ✅ Sucesso: Log info
   └── ⚠️ Timeout: Log warning, mantém offline
4. UI atualiza sem esperar Firestore
```

### 4. 🗄️ Firestore DataSource (`ExpenseFirestoreDataSource`)

**Tag:** `ExpenseFirestoreDataSource`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Inicialização | info | DataSource pronto |
| Tentativa de salvamento | debug | Início da operação |
| Timeout | warning | Operação demorou demais |
| Salvamento sucesso | info | Dados gravados |
| Erro de rede | error | Falha de conexão |
| Todas tentativas falharam | critical | Retry exausto |

**Configuração de Retry:**
- `saveExpense`: 1 tentativa, timeout 1.5s
- `syncLocalDataToFirestore`: 1 tentativa, timeout 5s

### 5. 💬 Chat IA (`ChatController`)

**Tag:** `ChatController`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Chat inicializado | info | Controller pronto |
| Mensagem enviada | info | Usuário enviou mensagem |
| Resposta IA gerada | info | Assistente respondeu |
| Despesa extraída | info | Parser identificou gasto |
| Erro de parsing | warning | Falha ao interpretar |
| Erro na API | error | Falha na OpenAI |

### 6. 🎯 Metas Financeiras (`FinancialGoalsController`)

**Tag:** `FinancialGoalsController`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Dados carregados | info | Perfil e metas prontos |
| Meta criada | info | Nova meta adicionada |
| Template aplicado | info | Perfil pré-definido |
| Progresso atualizado | debug | Cálculo de progresso |
| Erro de salvamento | error | Falha ao gravar meta |

### 7. 👤 Perfil (`ProfileController`)

**Tag:** `ProfileController`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Perfil carregado | info | Dados do usuário prontos |
| Configurações salvas | info | Preferências atualizadas |
| Logout realizado | info | Usuário saiu |
| Conta deletada | info | Conta removida |

### 8. 💵 Receitas (`IncomeController`)

**Tag:** `IncomeController`

| Evento | Nível | Descrição |
|--------|-------|-----------|
| Receitas carregadas | info | Lista atualizada |
| Receita adicionada | info | Nova receita criada |
| Totais calculados | debug | Soma recalculada |
| Erro de carregamento | error | Falha ao buscar |

---

## 🔍 Filtrando Logs no Console

### Por Tag
```
# Buscar logs de autenticação
grep "AuthController" logs.txt

# Buscar logs de sincronização
grep "ExpenseHybridRepository\|ExpenseFirestoreDataSource" logs.txt
```

### Por Nível
```
# Apenas warnings e erros
grep "⚠️\|❌\|🚨" logs.txt

# Apenas erros críticos
grep "🚨" logs.txt
```

### Por Funcionalidade
```
# Fluxo de despesas
grep "Expense" logs.txt

# Fluxo de autenticação
grep "Auth" logs.txt
```

---

## 📊 Eventos de Analytics

Os seguintes eventos são enviados automaticamente para o Firebase Analytics:

| Evento | Parâmetros | Descrição |
|--------|------------|-----------|
| `login` | method | Login realizado |
| `sign_up` | method | Cadastro realizado |
| `expense_created` | amount, category, payment_method | Despesa criada |
| `category_created` | category_name | Categoria criada |
| `goal_created` | goal_name, target_amount, category | Meta criada |
| `auth_error` | method, error_code | Erro de autenticação |
| `sync_error` | operation, error_type | Erro de sincronização |

---

## 🚨 Alertas de Crash Reporting

Erros são automaticamente enviados para o Firebase Crashlytics quando:

1. **Error Level**: Erros recuperáveis com stack trace
2. **Critical Level**: Erros fatais (marcados como `fatal: true`)

**Informações incluídas:**
- Stack trace completo
- Tag do componente
- Mensagem de contexto
- Dados adicionais (custom keys)

---

## 🔧 Configuração

### Inicialização (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar LoggingService
  final loggingService = LoggingService.instance;
  await loggingService.initialize();
  Get.put(loggingService);
  
  runApp(MyApp());
}
```

### Uso em Controllers/Services

```dart
import '../../../../core/services/app_logger.dart';

class MeuController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    AppLogger.info('MeuController', 'Controller inicializado');
  }
  
  Future<void> minhaOperacao() async {
    AppLogger.debug('MeuController', 'Iniciando operação');
    try {
      // ... operação
      AppLogger.info('MeuController', 'Operação concluída');
    } catch (e, stack) {
      AppLogger.error('MeuController', 'Erro na operação', 
        error: e, stackTrace: stack);
    }
  }
}
```

---

## 📋 Checklist de Implementação

### ✅ Implementado
- [x] LoggingService com níveis de severidade
- [x] AppLogger helper para uso simplificado
- [x] Integração com Firebase Analytics
- [x] Integração com Crashlytics
- [x] AuthController com logs completos
- [x] ExpenseController com logs completos
- [x] ExpenseHybridRepository com logs de sync
- [x] ExpenseFirestoreDataSource com logs de operações
- [x] ChatController com logs de interação
- [x] FinancialGoalsController com logs
- [x] ProfileController com logs
- [x] IncomeController com logs

### 🔄 Próximos Passos (Opcional)
- [ ] Adicionar logs ao CategoryController
- [ ] Converter `print` statements restantes para AppLogger
- [ ] Dashboard de métricas em tempo real
- [ ] Alertas automáticos para erros críticos
- [ ] Rotação de logs locais

---

## 📈 Benefícios

1. **Debugging Eficiente**: Logs estruturados facilitam identificação de problemas
2. **Monitoramento Proativo**: Analytics permitem identificar padrões de uso
3. **Crash Analysis**: Stack traces completos no Crashlytics
4. **Offline Visibility**: Logs de sincronização mostram estado offline/online
5. **User Journey**: Tracking de fluxos do usuário
6. **Performance Insights**: Identificação de operações lentas

---

**Versão**: 1.0.0  
**Data**: Dezembro 2024  
**Responsável**: Sistema Automatizado




