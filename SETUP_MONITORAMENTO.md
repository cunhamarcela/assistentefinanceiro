# 🚀 Setup Rápido - Sistema de Monitoramento

## ✅ O que foi implementado

Sistema completo para monitorar bugs em produção que não aparecem em simuladores:

- **Firebase Crashlytics**: Captura automática de crashes
- **Firebase Analytics**: Rastreamento de eventos e comportamento
- **Logging Service**: Logs estruturados com níveis de severidade
- **Error Tracking**: Rastreamento em serviços críticos (Auth, Database, Network)

---

## 📦 Instalação

### 1. Instalar Dependências

```bash
# Instalar packages Flutter
flutter pub get

# Atualizar pods do iOS
cd ios
pod install --repo-update
cd ..
```

### 2. Verificar Build

```bash
# Verificar que não há erros de compilação
flutter analyze

# Testar build iOS
flutter build ios --release

# Testar build Android
flutter build appbundle --release
```

---

## 🔧 Configuração no Firebase

### Passo 1: Habilitar Crashlytics

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto "Assistente Financeiro IA"
3. Menu lateral → **Crashlytics**
4. Clique em **"Habilitar Crashlytics"**
5. Aguarde o processamento (1-2 minutos)

### Passo 2: Habilitar Analytics (se ainda não estiver)

1. Menu lateral → **Analytics**
2. Clique em **"Habilitar Google Analytics"**
3. Siga o wizard de configuração

### Passo 3: Configurar Alertas (Opcional mas Recomendado)

1. **Crashlytics** → **Settings** → **Alerts**
2. Configure:
   - ✅ Novo tipo de crash
   - ✅ Aumento de taxa de crashes
   - ✅ Regressão de estabilidade
3. Adicione seu email para notificações

---

## 🧪 Teste Rápido

### 1. Teste em Desenvolvimento (Simulador)

```bash
# Rodar app em modo debug
flutter run

# Observe os logs no console:
# ℹ️ [timestamp] [App] 🔥 Firebase inicializado com sucesso!
# ℹ️ [timestamp] [Services] Inicializando StorageService...
# ℹ️ [timestamp] [Auth] Autenticação inicializada com sucesso
```

### 2. Teste em Dispositivo Real

```bash
# Build de release para iOS
flutter build ios --release
# Depois abra no Xcode e instale no dispositivo

# OU para Android
flutter build apk --release
# Instale o APK gerado no dispositivo
```

### 3. Gerar Eventos de Teste

No app rodando:

1. **Faça login** → Gera evento `login`
2. **Crie um gasto** → Gera evento `expense_created`
3. **Crie uma categoria** → Gera evento `category_created`

### 4. Verificar no Firebase Console

**Crashlytics** (5-10 minutos após crashes):
- Vá para Crashlytics Dashboard
- Veja crashes capturados

**Analytics** (pode levar até 24h):
- Vá para Analytics → Events
- Filtre por eventos: `login`, `expense_created`, etc.

---

## 📊 Como Usar no Dia a Dia

### Quando usuários reportam bugs:

1. **Acesse Firebase Console**
   - URL: https://console.firebase.google.com/

2. **Vá para Crashlytics**
   - Menu: Crashlytics → Crashes

3. **Filtre por:**
   - Versão do app
   - Tipo de dispositivo (iPad, iPhone específico)
   - Sistema operacional
   - Data/hora do problema

4. **Analise:**
   - Stack trace completo
   - Logs antes do crash
   - Quantos usuários afetados
   - Taxa de ocorrência

### Exemplo: "App crasha no iPad Air ao abrir câmera"

1. Crashlytics → Filtre:
   - Device: iPad Air
   - Version: 1.0.1
   
2. Procure crashes relacionados a:
   - `image_picker`
   - `camera`
   - `permission`

3. Veja o stack trace e logs:
   ```
   [Profile] Tentando abrir câmera
   Error: PlatformException (camera_access_denied)
   Stack trace: ...
   ```

4. Identifique a causa:
   - Falta de permissão?
   - Problema de timing?
   - Bug específico do device?

---

## 🐛 Adicionar Tracking em Novos Serviços

Quando criar novos serviços, adicione tracking:

```dart
import 'package:assistente_financeiro/core/services/crash_reporting_service.dart';
import 'package:assistente_financeiro/core/services/logging_service.dart';

class MeuServico {
  final _logger = LoggingService.instance;
  final _crashReporting = CrashReportingService.instance;
  
  Future<void> minhaOperacao() async {
    try {
      _logger.logInfo('MeuServico', 'Iniciando operação X');
      
      // Seu código aqui
      await fazerAlgo();
      
      _logger.logInfo('MeuServico', 'Operação concluída');
    } catch (e, stack) {
      _logger.logError(
        'MeuServico',
        'Erro na operação X',
        error: e,
        stackTrace: stack,
      );
      
      _crashReporting.recordError(e, stack, reason: 'Falha em operação X');
      rethrow;
    }
  }
}
```

---

## 📈 Métricas para Monitorar

### Diariamente:
- ✅ Taxa de crash-free users (meta: > 99.5%)
- ✅ Novos tipos de crashes
- ✅ Crashes frequentes

### Semanalmente:
- ✅ Comparar versões (regressões?)
- ✅ Crashes por dispositivo
- ✅ Eventos de analytics (engajamento)

### Após deploys:
- ✅ Monitorar por 24-48h
- ✅ Comparar com versão anterior
- ✅ Verificar alertas de aumento de crashes

---

## 🔒 Privacidade

### O que é enviado para Firebase:
- ✅ Stack traces de erros
- ✅ Tipo/modelo do dispositivo
- ✅ Versão do iOS/Android
- ✅ User ID (hash anônimo)
- ✅ Eventos de uso (sem dados sensíveis)

### O que NÃO é enviado:
- ❌ Senhas
- ❌ Tokens de autenticação
- ❌ Valores de transações financeiras
- ❌ Dados pessoais identificáveis

---

## 🆘 Troubleshooting

### "Não vejo crashes no Firebase"

**Motivos comuns:**
1. App ainda em modo DEBUG → Crashlytics desabilitado em debug
2. Precisa fazer build RELEASE
3. Aguardar 5-10 minutos após crash
4. Nenhum crash real aconteceu ainda

**Solução:**
```bash
# Fazer build de release
flutter build ios --release
# ou
flutter build apk --release
```

### "Analytics não mostra eventos"

**Motivos:**
1. Eventos podem levar até 24h para aparecer
2. Precisa usar build RELEASE
3. Dispositivo precisa ter conexão com internet

**Solução:**
- Aguarde até 24h
- Teste com vários eventos
- Verifique debug logs no console

---

## ✅ Checklist de Ativação

- [ ] Executei `flutter pub get`
- [ ] Executei `cd ios && pod install`
- [ ] Habilitei Crashlytics no Firebase Console
- [ ] Habilitei Analytics no Firebase Console
- [ ] Configurei alertas de email
- [ ] Testei build release em dispositivo real
- [ ] Gerei eventos de teste (login, criar gasto)
- [ ] Aguardei 24h e verifiquei dados no Firebase

---

## 📚 Documentação Completa

Para guia detalhado, veja: **GUIA_MONITORAMENTO_PRODUCAO.md**

Para troubleshooting específico, consulte:
- [Firebase Crashlytics Docs](https://firebase.google.com/docs/crashlytics)
- [Flutter Firebase Plugin](https://pub.dev/packages/firebase_crashlytics)

---

**Status**: ✅ Pronto para Deploy  
**Próximo passo**: `flutter pub get` → Build Release → Upload para TestFlight/Play Store

