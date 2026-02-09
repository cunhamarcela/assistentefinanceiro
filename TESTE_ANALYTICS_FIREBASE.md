# 🧪 Como Testar Firebase Analytics

## 📊 Status da Configuração

### ✅ TUDO CORRETO NO CÓDIGO:

1. ✅ Firebase inicializado no `main.dart`
2. ✅ `firebase_options.dart` configurado com iOS bundle ID: `com.assistentefinanceiro.assistenteFinanceiro`
3. ✅ `AnalyticsService` implementado e registrado
4. ✅ `FirebaseAnalyticsObserver` rastreando navegação automaticamente
5. ✅ Eventos customizados configurados (chat, ads, relatórios, etc.)

---

## ⏱️ Por que o Google Analytics está "Verificando"?

O Analytics está aguardando receber **o primeiro evento** do seu app iOS para confirmar que tudo está funcionando.

**Isso é NORMAL e esperado** quando:
- É a primeira vez configurando
- Você ainda não rodou o app após adicionar ao Analytics
- Aguardando dados chegarem (pode levar minutos a horas)

---

## 🚀 SOLUÇÃO: Testar o App Agora

### Opção 1: Executar no Simulador iOS (RÁPIDO)

```bash
cd /Users/marcelacunha/meus_apps/assistente_financeiro

# Executar no simulador iOS
flutter run -d "iPhone 15 Pro" --debug
```

**O que vai acontecer:**
1. App vai inicializar o Firebase
2. AnalyticsService vai enviar evento `app_first_open`
3. Cada tela navegada envia um evento automático
4. Google Analytics receberá os eventos

---

### Opção 2: Executar em Dispositivo iOS Real (MELHOR)

```bash
# Listar dispositivos conectados
flutter devices

# Executar no seu iPhone
flutter run -d "SEU_IPHONE" --debug
```

---

### Opção 3: Build de Release (PRODUÇÃO)

```bash
# Build para TestFlight/App Store
flutter build ios --release

# Depois execute via Xcode ou TestFlight
```

---

## 📲 Eventos que Serão Enviados Automaticamente

Assim que o app rodar, estes eventos serão enviados ao Firebase Analytics:

### 1. **Eventos Automáticos** (Firebase envia sozinho):
- `app_first_open` - Primeira vez que o app abre
- `screen_view` - Cada tela navegada
- `session_start` - Início da sessão
- `user_engagement` - Engajamento do usuário

### 2. **Eventos Customizados** (seu código envia):
- `chat_prompt_sent` - Quando envia mensagem no chat
- `report_viewed` - Quando visualiza relatórios
- `ad_impression` - Quando anúncio é exibido
- `limit_reached` - Quando atinge limite de uso
- `feature_unlock` - Quando desbloqueia feature

---

## 🔍 Como Verificar se Está Funcionando

### Método 1: DebugView do Firebase (TEMPO REAL)

1. Acesse: https://console.firebase.google.com/
2. Selecione seu projeto: **assistente-financeiro-ai**
3. Vá em **Analytics** → **DebugView**
4. Execute o app em modo **debug**
5. Você verá eventos aparecendo **EM TEMPO REAL** 🎉

**IMPORTANTE**: DebugView só funciona em modo DEBUG

```bash
# Para ativar debug view:
flutter run --debug
```

---

### Método 2: Console de Debug do Flutter

Quando rodar o app, você verá logs como:

```
📊 AnalyticsService inicializado com Firebase Analytics
📊 Evento Firebase: app_first_open
   Params: {install_date: 2026-01-14T...}
📊 Screen view: OnboardingScreen
📊 Evento Firebase: session_start
   Params: {timestamp: 2026-01-14T...}
```

Isso confirma que os eventos estão sendo enviados.

---

### Método 3: Google Analytics Console (24-48h)

Depois de enviar eventos:

1. Acesse: https://analytics.google.com/
2. Selecione sua propriedade do app
3. Vá em **Relatórios** → **Tempo real**
4. Você verá usuários ativos e eventos

**OBS**: Pode levar de **minutos a 24 horas** para dados aparecerem fora do DebugView.

---

## 🧪 Teste Passo a Passo

### Passo 1: Executar o App

```bash
cd /Users/marcelacunha/meus_apps/assistente_financeiro
flutter run --debug
```

### Passo 2: Abrir DebugView

1. Abra em outra aba: https://console.firebase.google.com/project/assistente-financeiro-ai/analytics/debugview
2. Deixe aberto enquanto usa o app

### Passo 3: Interagir com o App

Faça estas ações no app:
- ✅ Abrir o app (envia `app_first_open`)
- ✅ Navegar para Home (envia `screen_view`)
- ✅ Enviar uma mensagem no chat (envia `chat_prompt_sent`)
- ✅ Ver relatórios (envia `report_viewed`)

### Passo 4: Verificar no DebugView

Você deve ver algo assim no DebugView:

```
🟢 app_first_open
   install_date: 2026-01-14T15:30:00.000Z

🟢 screen_view
   firebase_screen: OnboardingScreen
   firebase_screen_class: OnboardingScreen

🟢 chat_prompt_sent
   event_type: promptSent

🟢 report_viewed
   event_type: viewed
```

---

## ⚡ Teste Rápido (30 segundos)

Execute este comando para testar AGORA:

```bash
cd /Users/marcelacunha/meus_apps/assistente_financeiro && flutter run --debug
```

Enquanto o app roda:
1. Abra: https://console.firebase.google.com/project/assistente-financeiro-ai/analytics/debugview
2. Navegue no app por 10 segundos
3. Veja eventos aparecendo no DebugView ✅

---

## 🚨 Se NADA aparecer no DebugView

### Possíveis causas:

1. **Firebase não inicializou**
   - Verifique console do Flutter: deve aparecer `🔥 Firebase inicializado com sucesso!`

2. **Info.plist com Bundle ID errado**
   - Verifique: `ios/Runner/Info.plist` tem `com.assistentefinanceiro.assistenteFinanceiro`
   - Verificar no Xcode: Project → Runner → General → Bundle Identifier

3. **firebase_options.dart desatualizado**
   - Regenerar com: `flutterfire configure`

4. **GoogleService-Info.plist faltando**
   - Deve estar em: `ios/Runner/GoogleService-Info.plist`

---

## 📱 Verificar GoogleService-Info.plist

```bash
# Verificar se arquivo existe
ls -la ios/Runner/GoogleService-Info.plist

# Ver conteúdo (deve ter BUNDLE_ID = com.assistentefinanceiro.assistenteFinanceiro)
cat ios/Runner/GoogleService-Info.plist | grep BUNDLE_ID
```

Se não existir, baixe do Firebase Console:
1. https://console.firebase.google.com/project/assistente-financeiro-ai/settings/general/ios:com.assistentefinanceiro.assistenteFinanceiro
2. Download do `GoogleService-Info.plist`
3. Adicionar em `ios/Runner/`

---

## ✅ RESUMO

**Situação atual:**
- ✅ Código 100% correto
- ✅ Firebase configurado
- ✅ Analytics implementado
- ⏱️ Google Analytics aguardando primeiro evento

**Solução:**
1. Execute: `flutter run --debug`
2. Abra: Firebase Console → DebugView
3. Use o app por 30 segundos
4. Veja eventos aparecendo ✅

**Resultado esperado:**
- Google Analytics mudará de "Verificando" para "✅ Configurado"
- Eventos começarão a aparecer no console
- Dentro de 24h, relatórios completos estarão disponíveis

---

## 🎯 Próximos Passos

Depois que o Analytics verificar (após rodar o app):

1. ✅ Continuar rodando campanhas de anúncios
2. ✅ Monitorar eventos no Firebase Analytics
3. ✅ Corrigir IDs do AdMob para Android (conforme `CHECKLIST_ANUNCIOS_ADMOB.md`)
4. ✅ Publicar nova versão nas lojas

---

## 📞 Suporte

- **Firebase Console**: https://console.firebase.google.com/project/assistente-financeiro-ai
- **DebugView**: https://console.firebase.google.com/project/assistente-financeiro-ai/analytics/debugview
- **Documentação**: https://firebase.google.com/docs/analytics/get-started?platform=flutter



