# 📊 Guia Completo de Monitoramento em Produção

## ✅ **Sistema Implementado**

Este guia documenta o sistema completo de monitoramento de bugs e erros em produção para o app **Assistente Financeiro IA**.

---

## 🛠️ **Componentes Implementados**

### 1. **Firebase Crashlytics** 
Sistema automático de crash reporting que captura:
- ✅ Crashes fatais do app
- ✅ Erros não tratados (uncaught exceptions)
- ✅ Stack traces completos
- ✅ Informações do dispositivo e OS
- ✅ Breadcrumbs (rastro de eventos antes do crash)

### 2. **Firebase Analytics**
Rastreamento de eventos e comportamento do usuário:
- ✅ Telas visualizadas
- ✅ Eventos de autenticação
- ✅ Ações de usuário (criar gasto, categoria, meta)
- ✅ Erros de sincronização

### 3. **Logging Service**
Sistema estruturado de logs com níveis de severidade:
- 🔍 **Debug**: Apenas em desenvolvimento
- ℹ️ **Info**: Informações gerais
- ⚠️ **Warning**: Avisos importantes
- ❌ **Error**: Erros recuperáveis
- 🚨 **Critical**: Erros críticos

### 4. **Crash Reporting Service**
Serviço centralizado com métodos específicos:
- `recordError()`: Registrar erros genéricos
- `recordAuthError()`: Erros de autenticação
- `recordDatabaseError()`: Erros de banco de dados
- `recordNetworkError()`: Erros de rede/API

---

## 📱 **Como Funciona**

### Captura Automática de Erros

```dart
// Todos os erros não tratados são automaticamente capturados
runZonedGuarded<Future<void>>(
  () async {
    // Código do app
  },
  (error, stack) {
    // Automaticamente enviado para Firebase Crashlytics
    CrashReportingService.instance.recordError(
      error, 
      stack, 
      fatal: true
    );
  },
);
```

### Tracking Manual em Serviços Críticos

```dart
// Exemplo no AuthService
try {
  await _firebaseAuth.signInWithEmailAndPassword(...);
  _logger.logLogin('email'); // Analytics event
} catch (e, stack) {
  _crashReporting.recordAuthError(e, stack, authMethod: 'email');
  _logger.logAuthError('email', e.code);
  rethrow;
}
```

---

## 🔍 **Como Visualizar os Bugs em Produção**

### 1. **Firebase Console - Crashlytics**
**URL**: https://console.firebase.google.com/

**Passos**:
1. Acesse Firebase Console
2. Selecione seu projeto
3. Menu lateral: **Crashlytics**
4. Veja:
   - Dashboard com crashes recentes
   - Crashes agrupados por tipo
   - Stack traces completos
   - Dispositivos afetados
   - Versões do app com problemas

**Informações Disponíveis**:
- 📊 Número de crashes
- 📱 Dispositivos afetados (modelo, OS)
- 👥 Usuários impactados
- 📈 Tendências ao longo do tempo
- 🔍 Stack trace completo
- 📝 Logs e breadcrumbs antes do crash

### 2. **Firebase Console - Analytics**
**Menu lateral**: **Analytics** → **Events**

**Eventos Rastreados**:
- `login` - Login de usuários (parâmetro: method)
- `sign_up` - Registro de novos usuários
- `expense_created` - Gasto criado
- `category_created` - Categoria criada
- `goal_created` - Meta financeira criada
- `auth_error` - Erros de autenticação
- `sync_error` - Erros de sincronização

### 3. **Logs Personalizados**

No Crashlytics, você verá logs antes de cada crash:
```
[Auth] Tentando login com email
[Auth] Login com email realizado com sucesso
[Services] ✅ Todos os serviços inicializados
```

---

## 🚨 **Tipos de Erros Capturados**

### 1. Erros de Autenticação
```dart
// Automaticamente rastreado
await authService.signInWithEmailAndPassword(...);
await authService.signInWithGoogle();
await authService.signInWithApple();
```

**O que é capturado**:
- Método de autenticação usado
- Código de erro do Firebase
- Stack trace completo
- Email do usuário (sem senha)

### 2. Erros de Banco de Dados
```dart
_crashReporting.recordDatabaseError(
  exception,
  stackTrace,
  operation: 'create_expense',
  collection: 'expenses'
);
```

### 3. Erros de Rede/API
```dart
_crashReporting.recordNetworkError(
  exception,
  stackTrace,
  endpoint: '/api/categories',
  statusCode: 500
);
```

### 4. Crashes de UI
```dart
// Erros no Flutter (widgets, rendering) são automaticamente capturados
FlutterError.onError = (details) {
  FirebaseCrashlytics.instance.recordFlutterError(details);
};
```

---

## 👤 **Identificação de Usuários**

### Informações Rastreadas (sem dados sensíveis):
- **User ID**: UID do Firebase
- **Email**: Email do usuário (apenas para identificação)
- **Nome**: Nome de exibição
- **Plano**: Tipo de conta (free/premium)

### Como é configurado:
```dart
// Automaticamente configurado no login
await CrashReportingService.instance.setUserId(user.uid);
await CrashReportingService.instance.setUserInfo(
  email: user.email,
  name: user.displayName,
);
```

---

## 📈 **Análise de Problemas Específicos**

### Problema: App crasha ao abrir câmera no iPad
**Como investigar**:

1. Vá para **Crashlytics** → **Crashes**
2. Filtre por:
   - Device: iPad
   - Version: Versão em produção
3. Procure crashes relacionados a `image_picker` ou `camera`
4. Veja o stack trace completo
5. Verifique logs antes do crash:
   ```
   [Profile] Tentando abrir câmera
   [Profile] Erro ao abrir câmera: permission denied
   ```

### Problema: Login falha em dispositivos específicos
**Como investigar**:

1. **Analytics** → **Events** → Filtre `auth_error`
2. Veja parâmetros:
   - `method`: google/email/apple
   - `error_code`: código específico do erro
3. **Crashlytics** → Filtre por dispositivo/OS
4. Compare com dispositivos onde funciona

### Problema: Sincronização falha silenciosamente
**Como investigar**:

1. **Analytics** → **Events** → `sync_error`
2. Parâmetros:
   - `operation`: sync_expenses/sync_categories
   - `error_type`: network/auth/permission
3. **Crashlytics** → Procure erros de `firestore` ou `network`

---

## 🔧 **Configuração de Alertas**

### No Firebase Console:

1. **Crashlytics** → **Settings** → **Alerts**
2. Configure alertas para:
   - ⚠️ Novo tipo de crash detectado
   - 📊 Aumento súbito de crashes
   - 👥 X% de usuários afetados
3. Configure notificações via:
   - Email
   - Slack
   - Jira

---

## 📊 **Métricas Importantes**

### Dashboards para Monitorar:

1. **Crash-free Users**
   - Meta: > 99.5%
   - Localização: Crashlytics Dashboard

2. **Crashes por Versão**
   - Comparar versões antigas vs nova
   - Identificar regressões

3. **Crashes por Dispositivo**
   - Identificar problemas específicos de hardware
   - iPad vs iPhone, etc.

4. **Crashes por OS Version**
   - iOS 15 vs 16 vs 17
   - Problemas de compatibilidade

---

## 🧪 **Testando o Sistema**

### 1. Testar Crash Reporting (APENAS EM DEBUG)

```dart
// Adicione temporariamente em algum botão
if (kDebugMode) {
  CrashReportingService.instance.testCrash();
}
```

### 2. Testar Logging

```dart
// Logs aparecem no Firebase Console após alguns minutos
LoggingService.instance.logInfo('Test', 'Sistema de logging funcionando');
```

### 3. Testar Analytics

```dart
// Eventos aparecem no Firebase Analytics (pode levar até 24h)
LoggingService.instance.logEvent('test_event', parameters: {
  'teste': 'funcionando'
});
```

---

## 🔒 **Privacidade e Segurança**

### O que NÃO é enviado:
- ❌ Senhas
- ❌ Tokens de autenticação
- ❌ Dados financeiros sensíveis (valores de transações)
- ❌ Informações de cartão de crédito

### O que É enviado:
- ✅ Stack traces de erros
- ✅ Informações do dispositivo (modelo, OS)
- ✅ User ID (hash anônimo)
- ✅ Logs de eventos (sem dados sensíveis)
- ✅ Métricas de performance

### Configuração de Privacidade:
```dart
// Crashlytics está DESABILITADO em debug
await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
```

---

## 📝 **Adicionando Tracking em Novos Serviços**

### Template para novos serviços:

```dart
import 'package:assistente_financeiro/core/services/crash_reporting_service.dart';
import 'package:assistente_financeiro/core/services/logging_service.dart';

class MeuNovoServico {
  final _crashReporting = CrashReportingService.instance;
  final _logger = LoggingService.instance;
  
  Future<void> minhaFuncao() async {
    try {
      _logger.logInfo('MeuServico', 'Iniciando operação');
      
      // Seu código aqui
      
      _logger.logInfo('MeuServico', 'Operação concluída com sucesso');
    } catch (e, stack) {
      _logger.logError(
        'MeuServico',
        'Erro na operação',
        error: e,
        stackTrace: stack,
      );
      
      _crashReporting.recordError(
        e,
        stack,
        reason: 'Erro em minhaFuncao',
      );
      
      rethrow;
    }
  }
}
```

---

## 🚀 **Próximos Passos**

### Para ativar o sistema:

1. **Instalar dependências**:
   ```bash
   flutter pub get
   cd ios && pod install --repo-update
   ```

2. **Build e teste**:
   ```bash
   # iOS
   flutter build ios
   
   # Android
   flutter build appbundle
   ```

3. **Deploy para TestFlight/Play Store**:
   - Upload da build
   - Aguardar processamento
   - Dados aparecem no Firebase após primeiros usos

4. **Monitorar**:
   - Acesse Firebase Console diariamente
   - Configure alertas de email
   - Revise métricas semanalmente

---

## 📞 **Troubleshooting**

### Não vejo crashes no Firebase Console

**Possíveis causas**:
1. Ainda em modo DEBUG (Crashlytics desabilitado)
2. App não foi enviado para produção ainda
3. Firebase não configurado corretamente
4. Nenhum crash real ocorreu ainda

**Solução**:
- Verifique que está rodando build RELEASE
- Aguarde 5-10 minutos após um crash
- Verifique configuração do Firebase
- Force um crash de teste (apenas em debug)

### Logs não aparecem

**Solução**:
- Logs podem levar até 24h para aparecer
- Verifique que `setCrashlyticsCollectionEnabled(true)` em release
- Force envio: `sendUnsentReports()`

---

## 📚 **Recursos Adicionais**

- [Firebase Crashlytics Docs](https://firebase.google.com/docs/crashlytics)
- [Firebase Analytics Docs](https://firebase.google.com/docs/analytics)
- [Flutter Crashlytics Plugin](https://pub.dev/packages/firebase_crashlytics)

---

**Versão**: 1.0.0  
**Data**: Outubro 2025  
**Status**: ✅ Implementado e Funcional

