# ✅ Checklist de Implementação AdMob - Interstitial Ads

## 📋 Status da Implementação

### ✅ 1. SDK Inicializado
- [x] `google_mobile_ads: ^5.1.0` no `pubspec.yaml`
- [x] `MobileAds.instance.initialize()` chamado no `AdsService.onInit()`
- [x] SDK inicializa automaticamente quando o app abre

### ✅ 2. IDs de Anúncios Configurados
**Arquivo:** `lib/core/services/ads_service.dart`

| Tipo | Plataforma | ID |
|------|------------|-----|
| Interstitial (PROD) | iOS | `ca-app-pub-6286381265499018/4081630365` |
| Interstitial (PROD) | Android | ⚠️ Precisa configurar |
| Interstitial (TEST) | Ambos | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded (PROD) | iOS | `ca-app-pub-6286381265499018/7433719494` |

### ✅ 3. Serviço de Interstitial Implementado
**Métodos disponíveis:**
- `loadInterstitial()` - Pré-carrega o anúncio
- `showInterstitialIfAvailable()` - Mostra se disponível
- `hasInterstitialReady` - Verifica se está pronto

### ✅ 4. Integração com Fluxo do App
- [x] Pré-carrega na inicialização da Home (`ExpenseBinding`)
- [x] Mostra após salvar despesa (`ExpenseController.addExpense`)

---

## 🧪 Como Testar

### Em Modo Debug (IDs de Teste)
1. Execute o app em modo debug (`flutter run`)
2. Os IDs de teste serão usados automaticamente
3. Adicione uma despesa
4. O interstitial deve aparecer após salvar

### Em Modo Release (IDs de Produção)
1. Build em release (`flutter build ios --release`)
2. Teste em dispositivo físico
3. **NÃO clique nos anúncios reais** (pode causar ban)

---

## 📊 Validação no AdMob

### O que verificar no painel AdMob:
1. **Relatórios → Hoje**
2. Métricas esperadas:
   - **Solicitações > 0** ✅
   - **Taxa de correspondência** (match rate)
   - **Impressões > 0** ✅

### Tempo para aparecer:
- Solicitações: 30-60 minutos após primeiro uso
- Impressões: Após anúncios serem exibidos
- Receita: Pode levar 24-48h para aparecer

---

## 🔧 Configuração Android (PENDENTE)

Para Android funcionar em produção, você precisa:

1. **Criar Ad Unit no AdMob para Android:**
   - Vá em AdMob → Apps → Adicionar App (Android)
   - Crie um Ad Unit Interstitial para Android
   - Copie o ID

2. **Atualizar o código:**
```dart
// Em lib/core/services/ads_service.dart
static const String prodInterstitialAdUnitIdAndroid = 'SEU-ID-AQUI';
```

---

## 🚨 Pontos de Atenção

### ❌ NUNCA faça:
- Clicar em anúncios reais (causa ban)
- Mostrar anúncio ao abrir o app
- Mostrar no meio de formulários
- Mostrar antes de mostrar resultado

### ✅ SEMPRE faça:
- Mostrar após ação concluída (salvar, gerar insight)
- Usar IDs de teste em desenvolvimento
- Testar em dispositivo físico
- Verificar métricas no AdMob

---

## 📱 Fluxo Atual de Anúncios

```
App Inicia
    ↓
AdsService.onInit()
    ↓
MobileAds.instance.initialize()
    ↓
_loadInterstitialAd() (pré-carrega)
    ↓
Usuário navega para Home
    ↓
ExpenseBinding._preloadInterstitialAd() (garante carregamento)
    ↓
Usuário adiciona despesa
    ↓
ExpenseController.addExpense()
    ↓
Get.back() (volta para home)
    ↓
_showInterstitialAfterAction() (mostra interstitial)
    ↓
_loadInterstitialAd() (pré-carrega próximo)
```

---

## 📈 Próximos Passos Sugeridos

1. [ ] Configurar ID Android para produção
2. [ ] Adicionar interstitial após gerar insight IA
3. [ ] Adicionar interstitial após gerar relatório
4. [ ] Implementar Banner Ads na home (opcional)
5. [ ] Configurar frequência máxima de anúncios

---

**Última atualização:** Janeiro 2026
