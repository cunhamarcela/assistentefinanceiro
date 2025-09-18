# Guia de Implementação — Interações IA e Relatórios Visuais

## Objetivo
Definir passos práticos para entregar duas iniciativas de retenção focadas em monetização por anúncios:
1. **Interações reais com IA** no chat existente e em pontos-chave da jornada.
2. **Relatórios visuais personalizados** que transformam dados financeiros em insights acionáveis.

As instruções respeitam Clean Architecture + GetX, armazenamento híbrido (Firestore/SQLite) e a estratégia offline-first.

---

## 1. Interações Reais com IA

### 1.1 Alinhamento de escopo e UX
1. Realize workshop com Produto/Marketing para desenhar roteiros prioritários: dúvidas sobre orçamento, alertas de gastos excessivos, metas semanais.
2. Defina persona e tom de voz do assistente IA (consistente com `AppTextStyles` e componentes do design system).
3. Mapeie pontos de ativação: onboarding, tela Home, aba Chat e notificações push.
4. Esboce wireframes (Figma) e estados de UI: aguardando resposta, resposta recebida, falha offline.

### 1.2 Domínio
1. Criar entidade `ChatMessageEntity` (caso ainda não exista) com campos `id`, `content`, `role`, `createdAt`, `metadata` (para classificação e anúncios).
2. Adicionar `GenerateAssistantReplyUseCase` no diretório `lib/features/chat/domain/usecases` retornando `Either<Failure, ChatMessageEntity>`.
3. Atualizar contrato do repositório (`ChatRepository`) para incluir método `generateReply({required List<ChatMessageEntity> history})`.

### 1.3 Data Layer
1. Criar datasource remoto `ChatIaRemoteDataSource` responsável por chamar o provedor de IA escolhido (ex.: Firebase Functions + modelo hospedado).  
   - Implementar retriable HTTP com `dio`, serialização usando DTO.
2. Adicionar datasource local `ChatIaCacheDataSource` (SQLite) para persistir histórico mínimo (últimas N mensagens) e fila de prompts offline.
3. Atualizar `ChatRepositoryImpl` para orquestrar cache + remoto, incluindo fallback offline que retorne resposta padrão ou sugestão de relatório visual.
4. Configurar autenticação segura: tokens no `FlutterSecureStorage`, renovação via backend.

### 1.4 Presentation Layer
1. Expandir `ChatController` (GetX) com estados: `idle`, `sending`, `receiving`, `error`, `retrying`.
2. Integrar binding (em `presentation/bindings`) para fornecer novo use case e serviços de telemetria.
3. Ajustar `ChatPage` para suportar:
   - Indicadores visuais (spinner, AppCard de dica) seguindo design system.  
   - Botão de "Ver insight" que abre relatório visual relevante (integração com feature do item 2).
4. Criar widgets reutilizáveis em `shared/widgets` (ex.: `AssistantBubble`, `RetryBanner`).

### 1.5 Telemetria & Ads
1. Instrumentar eventos: `chat_ai_prompt_sent`, `chat_ai_success`, `chat_ai_error`, `chat_ai_insight_click` com payload mínimo (tamanho do histórico, tipo de insight gerado).
2. Sincronizar eventos usando serviço de analytics com fila offline.
3. Definir regras de exibição de anúncios nativos após interações de valor: máximo 1 banner a cada 3 respostas significativas. Documentar em `docs/plano_retencao_ia.md`.

### 1.6 QA e Segurança
1. Cobrir use cases com testes unitários (mock dos datasources).  
2. Testar fluxo offline → sincronização posterior em aparelhos com conectividade intermitente.
3. Revisar limites de requisições à IA (quotas) e implementar circuito anti-spam.
4. Validar LGPD: ocultar dados pessoais, anonimizar identificadores antes de enviar ao back-end.

### 1.7 Roadmap sugerido
1. Sprint 1: Implementar domínio/data + API mockada.  
2. Sprint 2: Ajustes UI, integração real, observabilidade.  
3. Sprint 3: Personalizações avançadas (metas, categoria de despesas) e testes A/B com/sem IA.

---

## 2. Relatórios Visuais Personalizados

### 2.1 Descoberta e Planejamento
1. Coletar requisitos com pesquisa de usuários: quais insights são mais valiosos (fluxo de caixa semanal, top categorias, metas vs. realidade).
2. Priorizar 3 relatórios MVP que gerem engajamento semanal e suportem anúncios contextuais.
3. Definir periodicidade (diário, semanal) e disparadores (login, metas atrasadas, sugestão da IA).

### 2.2 Domínio
1. Criar entidades em `lib/features/expenses/domain/entities`: `InsightReportEntity`, `ChartPointEntity`, `InsightRecommendation`.
2. Adicionar use cases: `GenerateInsightReportUseCase`, `GetCachedReportsUseCase`, `ScheduleReportNotificationsUseCase`.
3. Atualizar repositórios de despesas/metas para expor métodos agregados (totais por categoria, tendências).

### 2.3 Data Layer
1. Implementar datasource de agregação local (`ReportsLocalDataSource`) usando SQLite para cálculos offline.
2. Criar `ReportsRemoteDataSource` (Firestore ou Functions) para enriquecer com benchmarks/IA (ex.: sugestão de economia).  
3. Garantir sincronização bidirecional: quando online, salvar relatórios no Firestore para consulta multi-dispositivo.
4. Cachear gráficos prontos ou dados de base para navegação rápida usando `SharedPreferences` (metadados) + SQLite (payload).

### 2.4 Presentation Layer
1. Criar módulo `lib/features/expenses/presentation/pages/reports_page.dart` (ou similar) com GetX Controller dedicado.
2. Construir widgets reutilizando design system:  
   - `InsightHeader` (AppCard com resumo).  
   - Gráficos com `FLChart` configurados para seguir paleta `AppColors` (roxo→amarelo).  
   - Componentes responsivos usando ScreenUtil.
3. Disponibilizar relatórios em Home (carrossel) e gatilho via chat IA (“Quero ver meus gastos em gráfico”).
4. Adicionar modo `empty state` com CTA para registrar transações (impulsiona retenção e anúncios).

### 2.5 Interações com IA
1. Expor API para que o chat IA possa solicitar `GenerateInsightReportUseCase` e retornar resumo textual + link para UI.
2. Permitir que usuários façam perguntas “O que mudou nos meus gastos?” → IA chama relatório e devolve highlights.
3. Registrar evento `insight_report_viewed` com metadados (tipo, origem: chat/home/notificação).

### 2.6 Instrumentação & Ads
1. Associe cada relatório a slots de anúncios nativos respeitando regras de frequência (ex.: banner após usuário expandir gráfico).  
2. Acompanhe métricas: taxa de abertura de relatórios, tempo de permanência, CTR de anúncios dentro do contexto.
3. Utilize dados para treinar modelo de recomendação (quais relatórios geram retorno semanal).

### 2.7 QA e Lançamento Gradual
1. Testes unitários para agregações e formatação de dados (valores monetários, datas).  
2. Testes widget/integrados para garantir responsividade em telas pequenas.  
3. Feature flag no Firestore para rollout gradual; monitorar analytics antes de liberar 100%.
4. Documentar comportamento esperado em `docs/design_system.md` (novos componentes) e atualizar `plano_retencao_ia.md` com eventos adicionais.

---

## 3. Integrações Cruzadas e Próximos Passos
1. Atualizar Backlog ágil com épicos “Chat IA Retentivo” e “Relatórios Visuais Inteligentes”.
2. Garantir que pipelines CI rodem testes (`flutter test`, `flutter analyze`) a cada merge.
3. Preparar monitoração (dashboards Looker/Data Studio) com funis: abertura do chat → insight → anúncio → retenção D7.
4. Planejar campanhas de marketing destacando novos recursos e coletar feedback contínuo via in-app surveys alimentados pela IA.

Resultado esperado: usuários recebem orientação proativa e visualizações claras que aumentam sessões recorrentes, desbloqueando mais impressões de anúncios sem comprometer a experiência.
