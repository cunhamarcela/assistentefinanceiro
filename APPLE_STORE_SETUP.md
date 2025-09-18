# Guia de Configuração para Apple App Store

## 📋 Pré-requisitos

- [ ] Conta Apple Developer ativa ($99/ano)
- [ ] Xcode instalado (versão mais recente)
- [ ] Certificados de desenvolvimento e distribuição
- [ ] Bundle ID único definido

## 🔧 1. Configuração no Apple Developer Console

### 1.1 Criar App ID
1. Acesse [Apple Developer Console](https://developer.apple.com/account/)
2. Vá em **Certificates, Identifiers & Profiles**
3. Clique em **Identifiers** → **App IDs**
4. Clique no botão **+** para criar novo App ID
5. Selecione **App** e clique **Continue**
6. Preencha os dados:
   - **Description**: Assistente Financeiro
   - **Bundle ID**: `com.seudominio.assistentefinanceiro` (substitua pelo seu domínio)
   - **Explicit Bundle ID**: Marque esta opção

### 1.2 Habilitar Capabilities
Na seção **Capabilities**, habilite:
- [ ] **Sign In with Apple** (obrigatório)
- [ ] **Push Notifications** (recomendado)
- [ ] **Associated Domains** (se usar deep links)
- [ ] **App Groups** (se necessário para compartilhamento)

### 1.3 Criar Certificates
1. Vá em **Certificates** → **All**
2. Clique no botão **+**
3. Crie os certificados necessários:
   - [ ] **iOS Development** (para desenvolvimento)
   - [ ] **iOS Distribution** (para App Store)

### 1.4 Criar Provisioning Profiles
1. Vá em **Profiles** → **All**
2. Clique no botão **+**
3. Crie os profiles:
   - [ ] **iOS App Development** (para desenvolvimento)
   - [ ] **App Store** (para distribuição)

## 🍎 2. Configuração Sign In with Apple

### 2.1 No Firebase Console
1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto
3. Vá em **Authentication** → **Sign-in method**
4. Habilite **Apple** como provedor
5. Configure:
   - **OAuth redirect URI**: Copie a URI fornecida
   - **Apple Team ID**: Encontre em Apple Developer → Membership
   - **Key ID**: Será criado no próximo passo
   - **Private Key**: Será criado no próximo passo

### 2.2 Criar Apple Sign In Key
1. No Apple Developer Console, vá em **Keys**
2. Clique no botão **+**
3. Preencha:
   - **Key Name**: Firebase Apple Sign In
   - **Services**: Marque **Sign In with Apple**
4. Clique **Continue** → **Register**
5. **IMPORTANTE**: Baixe o arquivo `.p8` (só pode ser baixado uma vez!)
6. Anote o **Key ID** mostrado

### 2.3 Configurar no Firebase
1. Volte ao Firebase Console
2. Em **Apple Sign-in**, preencha:
   - **Apple Team ID**: Seu Team ID
   - **Key ID**: O Key ID da chave criada
   - **Private Key**: Cole o conteúdo do arquivo `.p8`
3. Salve as configurações

## 📱 3. Configuração no Xcode

### 3.1 Abrir Projeto no Xcode
```bash
cd /Users/marcelacunha/meus_apps/assistente_financeiro
open ios/Runner.xcworkspace
```

### 3.2 Configurar Bundle ID
1. Selecione o projeto **Runner** no navigator
2. Em **Targets** → **Runner**
3. Na aba **General**:
   - **Bundle Identifier**: Use o mesmo Bundle ID criado no Developer Console
   - **Version**: 1.0.0
   - **Build**: 1

### 3.3 Configurar Signing & Capabilities
1. Na aba **Signing & Capabilities**:
   - **Team**: Selecione seu Apple Developer Team
   - **Provisioning Profile**: Selecione o profile criado
   - **Signing Certificate**: Deve aparecer automaticamente

### 3.4 Adicionar Sign In with Apple Capability
1. Clique no botão **+ Capability**
2. Adicione **Sign In with Apple**
3. Verifique se aparece na lista de capabilities

### 3.5 Verificar Entitlements
1. Confirme que o arquivo `Runner.entitlements` está referenciado
2. Verifique se contém:
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

## 🏪 4. Configuração App Store Connect

### 4.1 Criar App no App Store Connect
1. Acesse [App Store Connect](https://appstoreconnect.apple.com/)
2. Clique em **My Apps** → **+** → **New App**
3. Preencha:
   - **Platform**: iOS
   - **Name**: Assistente Financeiro
   - **Primary Language**: Portuguese (Brazil)
   - **Bundle ID**: Selecione o Bundle ID criado
   - **SKU**: Código único (ex: assistente-financeiro-2024)

### 4.2 Configurar Informações do App
1. **App Information**:
   - **Name**: Assistente Financeiro
   - **Subtitle**: Gerencie seus gastos com IA
   - **Category**: Finance
   - **Content Rights**: Marque se aplicável

2. **Pricing and Availability**:
   - **Price**: Free
   - **Availability**: All countries/regions (ou selecione específicos)

### 4.3 Preparar Metadados
1. **App Store Listing**:
   - **Description**: Descrição completa do app (até 4000 caracteres)
   - **Keywords**: Palavras-chave separadas por vírgula
   - **Support URL**: URL do seu site de suporte
   - **Marketing URL**: URL do seu site (opcional)

2. **App Review Information**:
   - **Contact Information**: Seus dados de contato
   - **Demo Account**: Se necessário para review
   - **Notes**: Informações adicionais para o revisor

## 🖼️ 5. Assets Necessários

### 5.1 Ícones do App
Tamanhos necessários (em pixels):
- [ ] 1024x1024 (App Store)
- [ ] 180x180 (iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus, X, XS, XS Max, XR, 11, 11 Pro, 11 Pro Max)
- [ ] 120x120 (iPhone 6, 6s, 7, 8, SE 2nd gen)
- [ ] 87x87 (iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus)
- [ ] 80x80 (iPhone 6, 6s, 7, 8, SE 2nd gen)
- [ ] 60x60 (iPhone)
- [ ] 58x58 (iPhone)
- [ ] 40x40 (iPhone)
- [ ] 29x29 (iPhone)
- [ ] 20x20 (iPhone)

### 5.2 Screenshots
Para cada tamanho de tela suportado:
- [ ] iPhone 6.7" (iPhone 14 Pro Max, 13 Pro Max, 12 Pro Max)
- [ ] iPhone 6.5" (iPhone 11 Pro Max, XS Max)
- [ ] iPhone 5.5" (iPhone 8 Plus, 7 Plus, 6s Plus, 6 Plus)
- [ ] iPad Pro 12.9" (3rd, 4th, 5th generation)
- [ ] iPad Pro 12.9" (2nd generation)

**Requisitos dos Screenshots**:
- Formato: PNG ou JPEG
- Resolução: Nativa do dispositivo
- Quantidade: 3-10 screenshots por tamanho
- Sem transparência
- Sem cantos arredondados

## 📄 6. Documentos Legais

### 6.1 Privacy Policy (Obrigatório)
Deve incluir:
- [ ] Quais dados são coletados
- [ ] Como os dados são usados
- [ ] Com quem os dados são compartilhados
- [ ] Como os usuários podem controlar seus dados
- [ ] Informações de contato

### 6.2 Terms of Service
Deve incluir:
- [ ] Termos de uso do app
- [ ] Limitações de responsabilidade
- [ ] Política de cancelamento/reembolso
- [ ] Lei aplicável

## 🚀 7. Build e Submissão

### 7.1 Criar Build de Produção
```bash
# Limpar build anterior
flutter clean

# Instalar dependências
flutter pub get

# Gerar build iOS
flutter build ios --release
```

### 7.2 Archive no Xcode
1. Abra o projeto no Xcode
2. Selecione **Generic iOS Device** como target
3. **Product** → **Archive**
4. Aguarde o processo de archive
5. Na janela **Organizer**, clique **Distribute App**
6. Selecione **App Store Connect**
7. Siga o assistente para upload

### 7.3 Submeter para Review
1. No App Store Connect, vá para seu app
2. Clique em **+ Version or Platform**
3. Selecione a build enviada
4. Preencha todas as informações obrigatórias
5. Clique **Submit for Review**

## ✅ 8. Checklist Final

### Antes da Submissão:
- [ ] App funciona corretamente em dispositivos físicos
- [ ] Sign In with Apple funciona
- [ ] Todos os ícones estão corretos
- [ ] Screenshots estão atualizados
- [ ] Privacy Policy está acessível
- [ ] Terms of Service estão acessíveis
- [ ] Informações do app estão completas
- [ ] Build foi testado em diferentes dispositivos

### Após Submissão:
- [ ] Monitorar status do review
- [ ] Responder a feedback do Apple Review Team se necessário
- [ ] Preparar marketing para lançamento
- [ ] Configurar analytics e crash reporting

## 🔍 9. Possíveis Problemas e Soluções

### Sign In with Apple não funciona:
1. Verificar se capability está habilitada no Xcode
2. Confirmar Bundle ID no Apple Developer Console
3. Verificar configuração no Firebase
4. Testar em dispositivo físico (não funciona no simulador para produção)

### Rejeição por Privacy:
1. Adicionar descrição de uso de dados no Info.plist
2. Implementar App Tracking Transparency se necessário
3. Revisar Privacy Policy

### Problemas de Build:
1. Verificar certificados e provisioning profiles
2. Limpar derived data no Xcode
3. Verificar versão do Xcode compatível

## 📞 10. Suporte e Recursos

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase Apple Sign-in Documentation](https://firebase.google.com/docs/auth/ios/apple)
- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)

---

**Nota**: Este processo pode levar de algumas horas a alguns dias, dependendo da complexidade do app e do tempo de review da Apple (geralmente 24-48 horas).


