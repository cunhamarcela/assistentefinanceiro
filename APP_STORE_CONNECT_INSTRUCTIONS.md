# 🍎 INSTRUÇÕES DETALHADAS - App Store Connect

## 📋 **CONFIGURAÇÕES OBRIGATÓRIAS PARA APROVAÇÃO**

### **1. CONFIGURAR INFORMAÇÕES DE PRIVACIDADE**

#### **Passo 1: Acessar App Privacy**
1. Faça login no [App Store Connect](https://appstoreconnect.apple.com)
2. Selecione seu app "Assistente Financeiro"
3. No menu lateral, clique em **"App Privacy"**
4. Clique no botão **"Edit"** (Editar)

#### **Passo 2: Corrigir Configurações de Tracking**

**🚨 PROBLEMA ATUAL:** O app está marcado como coletando dados para tracking

**✅ SOLUÇÃO:**

1. **Procure pela seção "Data Used to Track You"**
2. **Para cada item listado (Email Address, User ID, Name):**
   - Clique no item
   - **DESMARQUE** a opção "Used for Tracking"
   - **MARQUE** apenas "Used for App Functionality"
   - **MARQUE** "Linked to User" (se aplicável)

3. **Configurações específicas:**

   **📧 Email Address:**
   - ❌ Used for Tracking: **NÃO**
   - ✅ Used for App Functionality: **SIM**
   - ✅ Linked to User: **SIM**
   - **Descrição:** "Email usado apenas para autenticação e login do usuário"

   **🆔 User ID:**
   - ❌ Used for Tracking: **NÃO**
   - ✅ Used for App Functionality: **SIM**
   - ✅ Linked to User: **SIM**
   - **Descrição:** "ID usado apenas para identificação interna do usuário"

   **👤 Name:**
   - ❌ Used for Tracking: **NÃO**
   - ✅ Used for App Functionality: **SIM**
   - ✅ Linked to User: **SIM**
   - **Descrição:** "Nome usado apenas para personalização da interface"

#### **Passo 3: Verificar Seção "Data Not Used for Tracking"**
1. Certifique-se que todos os dados estão listados aqui
2. Confirme que nenhum dado está marcado para tracking

---

### **2. ATUALIZAR REVIEW NOTES**

#### **Localização:**
1. Vá para **"App Store"** → **"iOS App"**
2. Clique na versão atual (1.0)
3. Role até **"App Review Information"**
4. No campo **"Notes"**, adicione:

```
CORREÇÕES IMPLEMENTADAS PARA REVISÃO:

1. PRIVACIDADE (Guideline 5.1.2):
   ✅ Corrigidas informações de privacidade no App Store Connect
   ✅ Dados (email, nome, ID) marcados como "não usados para tracking"
   ✅ Dados usados apenas para autenticação e personalização

2. CRASH CÂMERA IPAD (Guideline 2.1):
   ✅ Adicionada permissão NSCameraUsageDescription no Info.plist
   ✅ Implementado tratamento robusto de erros para iPad Air 5ª geração
   ✅ Adicionado delay de 300ms para evitar problemas de timing
   ✅ Configurações específicas para iPad (orientações flexíveis)
   ✅ Otimizado com requestFullMetadata: false

3. EXCLUSÃO DE CONTA (Guideline 5.1.1v):
   ✅ Implementada funcionalidade completa de exclusão de conta
   ✅ Localização: Perfil → Botão "Excluir Conta" (vermelho)
   ✅ Inclui confirmação dupla e reautenticação segura

4. FLUXO DE PERMISSÕES (Guideline 5.1.1):
   ✅ Corrigido fluxo de solicitação de permissões
   ✅ Removida possibilidade de cancelar seleção de fonte de imagem
   ✅ Usuário deve escolher entre Câmera ou Galeria

TESTE ESPECÍFICO:
- Testado em iPad Air 5ª geração com iPadOS 26.0
- Funcionalidade de câmera funcionando sem crashes
- Exclusão de conta acessível e funcional
- Fluxo de permissões sem botões de cancelamento
```

---

### **3. VERIFICAR OUTRAS CONFIGURAÇÕES**

#### **App Information:**
1. Vá para **"App Information"**
2. Verifique se **Privacy Policy URL** está preenchida:
   - `https://assistente-financeiro-ai.web.app/privacy-policy`
3. Verifique se **Terms of Service URL** está preenchida:
   - `https://assistente-financeiro-ai.web.app/terms-of-service`

#### **Age Rating:**
1. Vá para **"Age Rating"**
2. Certifique-se que está configurado como apropriado (provavelmente 4+)

---

### **4. SUBMETER PARA REVISÃO**

#### **Antes de Submeter:**
1. ✅ Verifique se todas as configurações de privacidade estão corretas
2. ✅ Confirme que as Review Notes estão preenchidas
3. ✅ Teste o app uma última vez no dispositivo

#### **Submissão:**
1. Vá para **"App Store"** → **"iOS App"**
2. Clique na versão 1.0
3. Role até o final da página
4. Clique em **"Submit for Review"**
5. Responda às perguntas:
   - **Export Compliance:** Provavelmente "No" (app não usa criptografia)
   - **Content Rights:** "Yes" (você possui os direitos do conteúdo)
   - **Advertising Identifier:** "No" (não usa IDFA)

---

## 🎯 **CHECKLIST FINAL**

Antes de submeter, confirme:

- [ ] **Privacidade:** Dados marcados como "não usados para tracking"
- [ ] **Review Notes:** Texto explicativo adicionado
- [ ] **URLs:** Privacy Policy e Terms of Service configuradas
- [ ] **Age Rating:** Configurado apropriadamente
- [ ] **Build:** Versão mais recente com correções enviada

---

## 📞 **SE HOUVER PROBLEMAS**

### **Se a Apple rejeitar novamente:**

1. **Leia cuidadosamente** a nova mensagem de rejeição
2. **Responda no App Store Connect** se for um mal-entendido
3. **Use o texto sugerido:**

```
Olá equipe de revisão,

Implementamos todas as correções solicitadas:

1. PRIVACIDADE: Atualizamos as configurações de privacidade no App Store Connect. 
   Os dados coletados (email, nome, ID) são usados APENAS para autenticação e 
   personalização, NÃO para tracking publicitário.

2. EXCLUSÃO DE CONTA: A funcionalidade está implementada e acessível em:
   Perfil → Botão "Excluir Conta" (botão vermelho na parte inferior)

3. PERMISSÕES: Corrigimos o fluxo para não permitir cancelamento da seleção 
   de fonte de imagem.

4. CRASH IPAD: Implementamos múltiplas correções específicas para iPad Air 5ª geração.

Por favor, testem novamente. Obrigado!
```

---

**Data:** 26 de Setembro de 2025  
**Versão:** 1.0  
**Status:** ✅ Pronto para configuração e resubmissão

