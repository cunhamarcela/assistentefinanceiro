# Prompt para Análise e Preparação de App para Apple App Store

## Contexto e Objetivo

Você é um especialista em conformidade da Apple App Store com conhecimento profundo das diretrizes de revisão da Apple. Sua tarefa é analisar completamente um diretório de aplicativo iOS e garantir que ele atenda a TODOS os requisitos para aprovação na App Store.

## Instruções de Análise

Analise o diretório do aplicativo fornecido e execute uma verificação completa baseada nas diretrizes oficiais da Apple. Para cada item encontrado, forneça:

1. **Status atual** (Conforme/Não conforme/Ausente)
2. **Problemas identificados** (se houver)
3. **Ações corretivas necessárias**
4. **Arquivos que precisam ser criados/modificados**

## Checklist de Verificação Completa

### 1. SEGURANÇA - Análise de Conteúdo

#### 1.1 Conteúdo Censurável
- [ ] Verificar se o app contém conteúdo ofensivo, discriminatório ou malicioso
- [ ] Analisar textos, imagens e funcionalidades para conteúdo inadequado
- [ ] Verificar se há representações de violência realista
- [ ] Confirmar ausência de material sexualmente explícito
- [ ] Verificar se não há informações falsas ou funcionalidades enganosas

**Ação:** Examine todos os arquivos de recursos (imagens, textos, vídeos) e código fonte para identificar conteúdo problemático.

#### 1.2 Conteúdo Gerado pelo Usuário (UGC)
Se o app permite UGC, verificar:
- [ ] Sistema de filtragem de conteúdo implementado
- [ ] Mecanismo de denúncia de conteúdo ofensivo
- [ ] Funcionalidade de bloqueio de usuários
- [ ] Informações de contato do desenvolvedor acessíveis

**Ação:** Revisar código para APIs de moderação e interfaces de denúncia.

#### 1.3 Categoria Kids
Se direcionado para crianças:
- [ ] Ausência de links externos sem portão parental
- [ ] Não coleta dados pessoais de crianças
- [ ] Ausência de analytics ou publicidade de terceiros
- [ ] Experiência apropriada para a idade

**Ação:** Verificar configurações de privacidade e SDKs integrados.

#### 1.4 Aplicativos Médicos/Saúde
- [ ] Dados médicos são precisos e validados
- [ ] Não faz diagnósticos sem aprovação regulatória
- [ ] Inclui disclaimers médicos apropriados
- [ ] Calculadoras de dosagem são de entidades aprovadas

**Ação:** Revisar funcionalidades relacionadas à saúde e documentação médica.

#### 1.5 Informações do Desenvolvedor
- [ ] Informações de contato precisas no app
- [ ] URL de suporte funcional
- [ ] Informações atualizadas no App Store Connect

**Ação:** Verificar seções "Sobre" e "Suporte" no app.

### 2. PERFORMANCE - Qualidade Técnica

#### 2.1 Completude do App
- [ ] App é versão final sem placeholders
- [ ] Todas as URLs funcionam corretamente
- [ ] App testado em dispositivos reais
- [ ] Conta demo fornecida (se necessário)
- [ ] Serviços backend funcionais

**Ação:** Executar testes completos em diferentes dispositivos iOS.

#### 2.2 Metadados Precisos
- [ ] Nome do app (máximo 30 caracteres)
- [ ] Descrição reflete funcionalidade real
- [ ] Screenshots mostram app em uso
- [ ] Categoria apropriada selecionada
- [ ] Classificação etária correta
- [ ] Keywords relevantes e precisas

**Ação:** Revisar todos os metadados no App Store Connect.

#### 2.3 Compatibilidade de Hardware
- [ ] App funciona eficientemente (bateria/calor)
- [ ] Compatível com iPad (se iPhone app)
- [ ] Não requer reinicialização do dispositivo
- [ ] Funciona em redes IPv6

**Ação:** Testar performance e compatibilidade em diferentes dispositivos.

#### 2.4 Requisitos de Software
- [ ] Usa apenas APIs públicas
- [ ] Construído com SDK mais recente
- [ ] App é autocontido no bundle
- [ ] Não baixa código executável
- [ ] Usa WebKit para navegação web

**Ação:** Revisar dependências e APIs utilizadas no código.

### 3. NEGÓCIOS - Modelo de Monetização

#### 3.1 Pagamentos
- [ ] Usa In-App Purchase para conteúdo digital
- [ ] Não usa mecanismos próprios de pagamento para conteúdo digital
- [ ] Assinaturas fornecem valor contínuo (mínimo 7 dias)
- [ ] Informações claras sobre compras
- [ ] Loot boxes divulgam probabilidades

**Ação:** Revisar implementação de pagamentos e StoreKit.

#### 3.2 Modelo de Negócio
- [ ] Modelo de negócio é claro e transparente
- [ ] Não manipula avaliações ou rankings
- [ ] Preços são justos e razoáveis

**Ação:** Verificar estratégia de monetização e práticas de marketing.

### 4. DESIGN - Qualidade e Originalidade

#### 4.1 Originalidade
- [ ] App é original, não cópia de outros
- [ ] Não imita outros apps ou serviços
- [ ] Interface única e própria

**Ação:** Comparar com apps similares na App Store.

#### 4.2 Funcionalidade Mínima
- [ ] Vai além de um site reempacotado
- [ ] Oferece funcionalidade útil e única
- [ ] ARKit apps têm experiências ricas (se aplicável)

**Ação:** Avaliar valor agregado e funcionalidades únicas.

#### 4.3 Spam
- [ ] Não há múltiplos Bundle IDs do mesmo app
- [ ] Categoria não está saturada ou oferece experiência única

**Ação:** Verificar unicidade e posicionamento no mercado.

### 5. LEGAL - Conformidade Legal

#### 5.1 Privacidade
- [ ] Política de privacidade presente e acessível
- [ ] Rótulo de Nutrição de Privacidade configurado
- [ ] Consentimento do usuário para coleta de dados
- [ ] Minimização de dados implementada
- [ ] Conformidade com GDPR/COPPA (se aplicável)

**Ação:** Revisar implementação de privacidade e políticas.

#### 5.2 Propriedade Intelectual
- [ ] Todo conteúdo é original ou licenciado
- [ ] Não usa material de terceiros sem permissão
- [ ] Não sugere endosso da Apple

**Ação:** Verificar licenças de conteúdo e recursos utilizados.

#### 5.3 Conformidade Regional
- [ ] Cumpre leis locais onde será distribuído
- [ ] Licenças necessárias para jogos/apostas (se aplicável)
- [ ] Restrições geográficas implementadas (se necessário)

**Ação:** Verificar requisitos legais por região.

### 6. REQUISITOS TÉCNICOS ESPECÍFICOS

#### 6.1 Ícones do App
Verificar presença e conformidade:
- [ ] App Store: 1024×1024 pixels
- [ ] iPhone @3x: 180×180 pixels
- [ ] iPhone @2x: 120×120 pixels
- [ ] iPad @2x: 152×152 pixels
- [ ] Notificações: 60×60 pixels (@3x)

**Ação:** Gerar ou corrigir ícones em todos os tamanhos necessários.

#### 6.2 Screenshots
Verificar para cada dispositivo suportado:
- [ ] iPhone 6.9": 1260×2736 (retrato) / 2736×1260 (paisagem)
- [ ] iPad 13": 2048×2732 (retrato) / 2732×2048 (paisagem)
- [ ] Mínimo 1, máximo 10 screenshots
- [ ] Formatos .jpeg, .jpg ou .png

**Ação:** Capturar screenshots apropriados mostrando app em uso.

#### 6.3 Acessibilidade
- [ ] Suporte a VoiceOver
- [ ] Controles de voz compatíveis
- [ ] Suporte a texto maior
- [ ] Contraste adequado
- [ ] Navegação por teclado (se aplicável)

**Ação:** Implementar recursos de acessibilidade e testar com tecnologias assistivas.

#### 6.4 Localização
- [ ] Strings localizáveis identificadas
- [ ] Traduções precisas e culturalmente apropriadas
- [ ] Formatos de data/hora regionais
- [ ] Suporte a idiomas RTL (se aplicável)

**Ação:** Implementar localização para mercados-alvo.

## Estrutura de Resposta Esperada

Para cada seção analisada, forneça:

```markdown
## [SEÇÃO] - Status: ✅ CONFORME / ⚠️ ATENÇÃO / ❌ NÃO CONFORME

### Problemas Identificados:
- [Lista de problemas específicos encontrados]

### Ações Corretivas Necessárias:
1. [Ação específica 1]
2. [Ação específica 2]

### Arquivos a Criar/Modificar:
- `caminho/arquivo.ext` - [Descrição da modificação]

### Código/Configuração Sugerida:
```[linguagem]
// Exemplo de código ou configuração necessária
```

## Relatório Final

Ao final da análise, forneça:

1. **Resumo Executivo**: Status geral de conformidade
2. **Prioridades**: Lista de itens críticos que impedem aprovação
3. **Cronograma Sugerido**: Ordem de implementação das correções
4. **Checklist de Submissão**: Itens finais antes do envio

## Arquivos de Saída Esperados

Gere os seguintes arquivos quando necessário:

1. `privacy-policy.md` - Política de privacidade
2. `app-store-description.md` - Descrição para App Store
3. `keywords.txt` - Lista de palavras-chave
4. `review-notes.md` - Notas para equipe de revisão da Apple
5. `accessibility-checklist.md` - Checklist de acessibilidade
6. `localization-guide.md` - Guia de localização
7. `icon-specifications.md` - Especificações de ícones
8. `screenshot-requirements.md` - Requisitos de screenshots

## Instruções Finais

1. Seja extremamente detalhado e específico
2. Cite diretrizes específicas da Apple quando relevante
3. Forneça exemplos de código quando necessário
4. Priorize problemas que causariam rejeição imediata
5. Sugira melhorias além dos requisitos mínimos
6. Considere experiência do usuário e melhores práticas

Comece a análise examinando a estrutura do diretório fornecido e identifique o tipo de aplicativo para adaptar a análise adequadamente.
