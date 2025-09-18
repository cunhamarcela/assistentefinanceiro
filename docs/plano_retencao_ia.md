# Plano de Retenção com IA

## Contexto
Este guia descreve como executar os dois primeiros passos do plano de retenção com IA: (1) mapear métricas de retenção e eventos-alvo; (2) priorizar casos de uso e desenhar o fluxo de dados necessário para ativá-los. O objetivo é alinhar time de produto, dados e engenharia em um roteiro acionável.

## Passo 1 — Mapear métricas de retenção e definir eventos-alvo

1. **Alinhar objetivos de negócio**  
   - Reúna produto, marketing e dados para validar metas de retenção (ex.: diminuir churn em 15%, aumentar sessões semanais).  
   - Documente as metas na wiki interna e confirme como elas se relacionam com monetização via anúncios (ex.: impressões mínimas por sessão).

2. **Inventariar fontes de dados**  
   - Liste dados em Firebase Analytics, Firestore e SQLite local (sincronização offline).  
   - Identifique gaps (ex.: ausência de evento para abertura do chat IA) e valide se podem ser medidos sem ferir privacidade.

3. **Definir métricas-chave de retenção**  
   - Métricas base: DAU/WAU, retenção D1/D7/D30, tempo médio de sessão, número médio de sessões/usuário, LTV estimado por anúncios.  
   - Métricas qualitativas: conclusão de onboarding, número de metas ativas, interações com recomendações de IA.  
   - Para cada métrica, documente fórmula, janela de análise e owner responsável.

4. **Mapear eventos-alvo**  
   - Categorize eventos em: aquisição (cadastro, onboarding completo), ativação (primeiro cadastro de gasto, criação de meta), engajamento (consultas ao chat, visualização de relatórios), risco (30 dias sem registrar gasto, metas atrasadas).  
   - Defina payload mínimo para cada evento (IDs anônimos, timestamps, canal). Use `core/utils` para normalizar datas e manter compatibilidade com offline-first.

5. **Planejar instrumentação**  
   - Conecte eventos às camadas do app: controllers GetX disparam eventos via serviço de telemetria (ex.: `AnalyticsService`).  
   - Garanta que dados críticos sejam persistidos em fila local (SQLite) para envio quando online.  
   - Priorize criação de testes unitários para validar formatação de eventos.

6. **Validar conformidade e privacidade**  
   - Revise políticas de privacidade e termos para assegurar consentimento explícito.  
   - Defina procedimento para anonimização (hash + salts) antes de enviar dados sensíveis ao back-end ou provedores de anúncios.

7. **Consolidar documentação**  
   - Crie planilha ou documento no Notion/Confluence com tabelas: métricas, eventos, owners, status da instrumentação.  
   - Estabeleça cadência de revisão (quinzenal) para acompanhar evolução e ajustar métricas conforme resultados dos experimentos.

## Passo 2 — Priorizar casos de uso e desenhar fluxo de dados

1. **Listar casos de uso candidatos**  
   - Comece pelos já identificados: chat IA, notificações proativas, relatórios dinâmicos, jornadas guiadas no onboarding.  
   - Inclua ideias adicionais do time (ex.: recomendações in-app, insights via widgets). Classifique se dependem de dados em tempo real ou histórico.

2. **Aplicar matriz impacto x esforço**  
   - Avalie cada caso de uso em termos de impacto esperado em retenção e receita de anúncios, esforço técnico (modelagem, infra, UI) e risco.  
   - Use pontuação 1–5 para cada eixo; compute prioridade = impacto − esforço + nota de sinergia com anúncios.

3. **Selecionar backlog inicial**  
   - Escolha 2–3 iniciativas de maior prioridade para ciclo piloto (ex.: notificações de risco de churn + melhorias no chat IA).  
   - Quebre iniciativas em épicos/estórias seguindo Clean Architecture (domain → data → presentation) e registre no board ágil.

4. **Desenhar fluxo de dados macro**  
   - Para cada caso de uso, mapeie: origem dos dados (eventos do Passo 1, Firestore, SQLite), processamento (modelos IA hospedados no back-end ou dispositivo) e destino (UI, notificações, anúncios personalizados).  
   - Documente fluxos usando diagrama (ex.: Miro, Excalidraw). Inclua etapas de sincronização offline-first e fallback quando IA estiver indisponível.

5. **Especificar contratos por camada**  
   - Domain: defina entidades e use cases necessários (ex.: `PredictChurnUseCase`).  
   - Data: detalhe repositórios, datasources e integrações (Firebase Functions, API externa).  
   - Presentation: ajuste controllers, bindings e widgets que consumirão insights de IA, garantindo reuse via `shared/widgets`.

6. **Planejar integração com anúncios**  
   - Identifique pontos do fluxo onde anúncios podem ser exibidos sem atrito (ex.: após recomendação personalizada).  
   - Defina regras para equilibrar conteúdo de valor vs. impressão publicitária (limite por sessão, frequência).  
   - Alinhe com parceiros de ads para garantir segmentação compatível com LGPD.

7. **Estabelecer roadmap e critérios de sucesso**  
   - Monte cronograma com marcos: validação de dados, implementação do protótipo, testes A/B, rollout gradual.  
   - Para cada caso de uso, defina métricas de sucesso alinhadas ao Passo 1 (ex.: +5% sessões semanais entre usuários expostos).  
   - Configure rotinas de monitoramento em dashboards (Looker Studio, Data Studio ou outro) para acompanhar evolução.

---

**Resultado esperado:** ao final desses passos, a equipe terá clareza sobre quais métricas de retenção acompanhar, como medi-las de forma confiável e quais iniciativas de IA priorizar primeiro, com dependências técnicas mapeadas e roadmap inicial aprovado.
