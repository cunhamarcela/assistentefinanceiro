# Correções Obrigatórias para Info.plist

## 🔴 CRÍTICO: Adicionar Descrições de Privacidade

### Arquivo: `ios/Runner/Info.plist`

Adicione as seguintes chaves **OBRIGATÓRIAS** antes da tag `</dict>` final:

```xml
<!-- DESCRIÇÕES DE PRIVACIDADE OBRIGATÓRIAS -->

<!-- Tracking de usuário para analytics e personalização -->
<key>NSUserTrackingUsageDescription</key>
<string>Este app usa dados para melhorar sua experiência financeira e fornecer insights personalizados sobre seus gastos.</string>

<!-- Câmera para foto de perfil -->
<key>NSCameraUsageDescription</key>
<string>Acesso à câmera é usado para capturar foto de perfil do usuário.</string>

<!-- Galeria de fotos para foto de perfil -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Acesso à galeria de fotos é usado para selecionar foto de perfil do usuário.</string>

<!-- Localização para categorização automática (se implementado no futuro) -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Localização é usada para categorizar automaticamente gastos baseados em estabelecimentos próximos.</string>

<!-- Microfone para entrada de voz (se implementado no futuro) -->
<key>NSMicrophoneUsageDescription</key>
<string>Microfone é usado para entrada de gastos por comando de voz.</string>

<!-- Contatos para compartilhamento (se implementado no futuro) -->
<key>NSContactsUsageDescription</key>
<string>Contatos são usados para facilitar o compartilhamento de relatórios financeiros.</string>
```

## ✅ Verificar Configurações Existentes

### 1. App Transport Security
Confirme que esta configuração está presente:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>firebase.googleapis.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
        <key>firebaseapp.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>
```

### 2. URLs de Privacidade
Confirme que estas URLs estão corretas:

```xml
<key>NSPrivacyPolicyURL</key>
<string>https://assistente-financeiro-ai.web.app/privacy-policy</string>

<key>NSTermsOfServiceURL</key>
<string>https://assistente-financeiro-ai.web.app/terms-of-service</string>
```

### 3. Bundle Names
Confirme que os nomes estão consistentes:

```xml
<key>CFBundleName</key>
<string>Assistente Financeiro</string>

<key>CFBundleDisplayName</key>
<string>Assistente Financeiro</string>
```

### 4. Versão Mínima do iOS
Confirme que está adequada:

```xml
<key>MinimumOSVersion</key>
<string>12.0</string>
```

## 🚨 IMPORTANTE

### Antes de Submeter:
1. ✅ Adicione TODAS as descrições de privacidade
2. ✅ Verifique se as URLs estão funcionais
3. ✅ Teste o app em dispositivo físico
4. ✅ Confirme que Sign in with Apple funciona
5. ✅ Execute `flutter analyze` sem erros

### Após Adicionar as Correções:
```bash
# Limpar e reconstruir o projeto
cd ios
rm -rf Pods Podfile.lock
cd ..
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```

### Validação Final:
- App deve compilar sem erros
- Todas as funcionalidades devem funcionar
- Sign in with Apple deve estar operacional
- Não deve haver crashes ou problemas de performance

## ⚠️ ATENÇÃO

**SEM ESSAS CORREÇÕES O APP SERÁ REJEITADO AUTOMATICAMENTE PELA APPLE**

As descrições de privacidade são **OBRIGATÓRIAS** desde iOS 14 e a Apple rejeita automaticamente apps que não as possuem, mesmo que não utilizem essas permissões atualmente.

É melhor incluir todas as descrições agora para funcionalidades futuras do que ter que resubmeter o app posteriormente.



