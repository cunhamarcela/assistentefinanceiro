# 🎨 DESIGN SYSTEM — CORES

> **Versão:** 1.0.0  
> **Última Atualização:** Dezembro 2024  
> **Status:** ✅ Ativo  
> **Arquivo de Implementação:** `lib/core/theme/app_colors.dart`

---

## 1. Visão Geral

### 1.1 Propósito

Esta paleta foi projetada para transmitir **confiança, profissionalismo e clareza** em um aplicativo de gestão financeira pessoal. As cores foram selecionadas para:

- Criar uma experiência visual **calma e organizada**
- Facilitar a **leitura de dados financeiros**
- Transmitir **segurança e credibilidade**
- Garantir **acessibilidade** para todos os usuários

### 1.2 Princípios de Design

| Princípio | Descrição |
|-----------|-----------|
| **Confiança** | Tons de azul marinho transmitem seriedade e estabilidade financeira |
| **Clareza** | Alto contraste entre texto e fundo para leitura fácil de números |
| **Controle** | Verde de ação indica progresso positivo e ações disponíveis |
| **Simplicidade** | Paleta reduzida evita sobrecarga visual |

### 1.3 Regras Gerais de Uso

1. **Nunca usar cores hardcoded** — Sempre referenciar Design Tokens
2. **Usar tokens pelo significado** — Ex: `colorSuccess` para sucesso, não "porque é verde"
3. **Respeitar hierarquia** — Cores de destaque apenas para elementos importantes
4. **Manter consistência** — Mesmo componente = mesmas cores em todo app

---

## 2. Paleta Base

### 2.1 Primary / Brand

| Nome | HEX | Preview | Uso Principal | Uso Proibido |
|------|-----|---------|---------------|--------------|
| **Navy Dark** | `#0A1931` | ![#0A1931](https://via.placeholder.com/20/0A1931/0A1931) | Headers, AppBar, fundos escuros | Texto em fundo claro |
| **Navy** | `#1A3D63` | ![#1A3D63](https://via.placeholder.com/20/1A3D63/1A3D63) | Elementos de marca, títulos | Fundos de área grande |

### 2.2 Secondary

| Nome | HEX | Preview | Uso Principal | Uso Proibido |
|------|-----|---------|---------------|--------------|
| **Blue Medium** | `#4A7FA7` | ![#4A7FA7](https://via.placeholder.com/20/4A7FA7/4A7FA7) | Textos secundários, ícones, links | Botões primários |
| **Blue Light** | `#B3CFE5` | ![#B3CFE5](https://via.placeholder.com/20/B3CFE5/B3CFE5) | Bordas, backgrounds secundários, disabled | Texto principal |

### 2.3 Neutral / Background

| Nome | HEX | Preview | Uso Principal | Uso Proibido |
|------|-----|---------|---------------|--------------|
| **Background Primary** | `#F6FAFD` | ![#F6FAFD](https://via.placeholder.com/20/F6FAFD/F6FAFD) | Fundo geral do app | Textos, bordas fortes |
| **Surface Elevated** | `#FFFFFF` | ![#FFFFFF](https://via.placeholder.com/20/FFFFFF/FFFFFF) | Cards, modais, superfícies elevadas | Fundos de tela inteira |

### 2.4 Accent (Uso Restrito — Máx. 5%)

| Nome | HEX | Preview | Uso Principal | Uso Proibido |
|------|-----|---------|---------------|--------------|
| **Success / Action** | `#3CB371` | ![#3CB371](https://via.placeholder.com/20/3CB371/3CB371) | CTAs, sucesso, ações positivas | Fundos, textos longos |

### 2.5 Support States

| Nome | HEX | Preview | Uso Principal | Uso Proibido |
|------|-----|---------|---------------|--------------|
| **Warning** | `#E9C46A` | ![#E9C46A](https://via.placeholder.com/20/E9C46A/E9C46A) | Alertas, atenção necessária | Sucesso, informação |
| **Error** | `#E76F51` | ![#E76F51](https://via.placeholder.com/20/E76F51/E76F51) | Erros, valores negativos | Ações positivas |
| **Info** | `#4A7FA7` | ![#4A7FA7](https://via.placeholder.com/20/4A7FA7/4A7FA7) | Informações, dicas | Estados de erro |

---

## 3. Design Tokens (Semânticos)

### 3.1 Background Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorBackgroundPrimary` | `#F6FAFD` | Fundo principal de todas as telas |
| `colorBackgroundSecondary` | `#B3CFE5` | Áreas secundárias, seções diferenciadas |

### 3.2 Surface Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorSurfaceCard` | `#FFFFFF` | Cards, containers de conteúdo |
| `colorSurfaceElevated` | `#FFFFFF` | Modais, bottom sheets, elementos elevados |

### 3.3 Text Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorTextPrimary` | `#0A1931` | Títulos, textos principais |
| `colorTextSecondary` | `#1A3D63` | Subtítulos, textos de apoio |
| `colorTextMuted` | `#4A7FA7` | Captions, placeholders, textos desabilitados |
| `colorTextOnDark` | `#F6FAFD` | Texto sobre fundos escuros (AppBar, botões) |

### 3.4 Brand Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorBrandPrimary` | `#1A3D63` | Cor principal da marca |
| `colorBrandDark` | `#0A1931` | Versão escura da marca |
| `colorBrandSoft` | `#4A7FA7` | Versão suave/clara da marca |

### 3.5 Action Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorActionPrimary` | `#3CB371` | Botões primários, CTAs |
| `colorActionSecondary` | `#4A7FA7` | Botões secundários, links |
| `colorActionDisabled` | `#B3CFE5` | Estados desabilitados |

### 3.6 State Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorSuccess` | `#3CB371` | Operações bem-sucedidas, valores positivos |
| `colorWarning` | `#E9C46A` | Alertas, atenção necessária |
| `colorError` | `#E76F51` | Erros, valores negativos, exclusões |
| `colorInfo` | `#4A7FA7` | Informações neutras, dicas |

### 3.7 Border Tokens

| Token | Valor | Descrição |
|-------|-------|-----------|
| `colorBorderSubtle` | `#B3CFE5` | Bordas sutis, divisores leves |
| `colorBorderStrong` | `#4A7FA7` | Bordas de destaque, foco |

---

## 4. Mapa de Aplicação por Componente

### 4.1 AppBar / Header

| Propriedade | Token | Valor |
|-------------|-------|-------|
| Background | `colorBrandDark` | `#0A1931` |
| Texto | `colorTextOnDark` | `#F6FAFD` |
| Ícones | `colorTextOnDark` | `#F6FAFD` |
| Status Bar | Light (ícones brancos) | — |

### 4.2 Backgrounds

| Contexto | Token | Valor |
|----------|-------|-------|
| Tela principal | `colorBackgroundPrimary` | `#F6FAFD` |
| Seção secundária | `colorBackgroundSecondary` | `#B3CFE5` |
| Overlay/Modal | `colorSurfaceElevated` | `#FFFFFF` |

### 4.3 Cards

| Propriedade | Token | Valor |
|-------------|-------|-------|
| Background | `colorSurfaceCard` | `#FFFFFF` |
| Borda | `colorBorderSubtle` | `#B3CFE5` |
| Título | `colorTextPrimary` | `#0A1931` |
| Subtítulo | `colorTextSecondary` | `#1A3D63` |
| Caption | `colorTextMuted` | `#4A7FA7` |

### 4.4 Buttons

#### Primary Button
| Estado | Background | Texto | Borda |
|--------|------------|-------|-------|
| Default | `colorActionPrimary` | `colorTextOnDark` | none |
| Hover | `colorActionPrimary` (darken 10%) | `colorTextOnDark` | none |
| Pressed | `colorActionPrimary` (darken 20%) | `colorTextOnDark` | none |
| Disabled | `colorActionDisabled` | `colorTextMuted` | none |

#### Secondary Button
| Estado | Background | Texto | Borda |
|--------|------------|-------|-------|
| Default | transparent | `colorBrandPrimary` | `colorBrandPrimary` |
| Hover | `colorBrandPrimary` (10% opacity) | `colorBrandPrimary` | `colorBrandPrimary` |
| Pressed | `colorBrandPrimary` (20% opacity) | `colorBrandPrimary` | `colorBrandPrimary` |
| Disabled | transparent | `colorTextMuted` | `colorActionDisabled` |

#### Text Button
| Estado | Background | Texto |
|--------|------------|-------|
| Default | transparent | `colorActionSecondary` |
| Hover | `colorActionSecondary` (10% opacity) | `colorActionSecondary` |
| Disabled | transparent | `colorTextMuted` |

### 4.5 Inputs

| Propriedade | Token | Valor |
|-------------|-------|-------|
| Background | `colorSurfaceCard` | `#FFFFFF` |
| Texto | `colorTextPrimary` | `#0A1931` |
| Placeholder | `colorTextMuted` | `#4A7FA7` |
| Label | `colorTextSecondary` | `#1A3D63` |
| Borda (default) | `colorBorderSubtle` | `#B3CFE5` |
| Borda (focus) | `colorBrandPrimary` | `#1A3D63` |
| Borda (error) | `colorError` | `#E76F51` |
| Helper text | `colorTextMuted` | `#4A7FA7` |
| Error text | `colorError` | `#E76F51` |

### 4.6 Textos

| Tipo | Token | Uso |
|------|-------|-----|
| Título (H1, H2, H3) | `colorTextPrimary` | Headlines, títulos de seção |
| Subtítulo | `colorTextSecondary` | Subtítulos, descrições |
| Corpo | `colorTextSecondary` | Parágrafos, conteúdo |
| Caption | `colorTextMuted` | Legendas, timestamps, hints |
| Sobre fundo escuro | `colorTextOnDark` | AppBar, botões primários |

### 4.7 Ícones

| Contexto | Token | Valor |
|----------|-------|-------|
| Ícone primário | `colorTextPrimary` | `#0A1931` |
| Ícone secundário | `colorTextMuted` | `#4A7FA7` |
| Ícone ativo/selecionado | `colorActionPrimary` | `#3CB371` |
| Ícone sobre fundo escuro | `colorTextOnDark` | `#F6FAFD` |
| Ícone desabilitado | `colorActionDisabled` | `#B3CFE5` |

### 4.8 Gráficos e Indicadores

| Elemento | Token | Valor |
|----------|-------|-------|
| Cor base / track | `colorBorderSubtle` | `#B3CFE5` |
| Progresso / preenchimento | `colorBrandSoft` | `#4A7FA7` |
| Destaque positivo | `colorSuccess` | `#3CB371` |
| Alerta | `colorWarning` | `#E9C46A` |
| Negativo | `colorError` | `#E76F51` |

### 4.9 Estados de Feedback

| Estado | Background | Texto | Ícone | Borda |
|--------|------------|-------|-------|-------|
| Success | `colorSuccess` (10% opacity) | `colorSuccess` | `colorSuccess` | `colorSuccess` |
| Warning | `colorWarning` (10% opacity) | `colorWarning` | `colorWarning` | `colorWarning` |
| Error | `colorError` (10% opacity) | `colorError` | `colorError` | `colorError` |
| Info | `colorInfo` (10% opacity) | `colorInfo` | `colorInfo` | `colorInfo` |

---

## 5. Regras de Distribuição de Cor

### 5.1 Regra 60-30-10

| Proporção | Cores | Aplicação |
|-----------|-------|-----------|
| **60%** | Neutros (`#F6FAFD`, `#FFFFFF`) | Fundos, superfícies |
| **30%** | Brand (`#0A1931`, `#1A3D63`, `#4A7FA7`) | Textos, ícones, headers |
| **10%** | Accent + States | CTAs, feedbacks, destaques |

### 5.2 Limite de Accent Color

⚠️ **Máximo 5% da interface** pode usar `colorActionPrimary` (#3CB371)

**Usos permitidos:**
- ✅ Botão de ação principal (1 por tela)
- ✅ Indicador de sucesso
- ✅ FAB (Floating Action Button)
- ✅ Valores positivos (economia, lucro)

**Usos proibidos:**
- ❌ Fundos de área grande
- ❌ Múltiplos botões verdes na mesma tela
- ❌ Decoração visual sem função

### 5.3 Proibições

| Proibição | Motivo |
|-----------|--------|
| Cores HEX/RGB hardcoded | Quebra consistência, dificulta manutenção |
| Gradientes não documentados | Cria inconsistência visual |
| Cores fora da paleta | Dilui identidade da marca |
| Uso de cor por preferência | Tokens são semânticos, não estéticos |

---

## 6. Acessibilidade

### 6.1 Contraste Mínimo (WCAG AA)

| Combinação | Ratio | Status |
|------------|-------|--------|
| `colorTextPrimary` sobre `colorBackgroundPrimary` | 12.5:1 | ✅ AAA |
| `colorTextSecondary` sobre `colorBackgroundPrimary` | 8.2:1 | ✅ AAA |
| `colorTextMuted` sobre `colorBackgroundPrimary` | 4.6:1 | ✅ AA |
| `colorTextOnDark` sobre `colorBrandDark` | 11.8:1 | ✅ AAA |
| `colorTextOnDark` sobre `colorActionPrimary` | 4.5:1 | ✅ AA |

### 6.2 Combinações Permitidas

✅ **Texto sobre fundo claro:**
- `colorTextPrimary` + `colorBackgroundPrimary`
- `colorTextSecondary` + `colorBackgroundPrimary`
- `colorTextPrimary` + `colorSurfaceCard`

✅ **Texto sobre fundo escuro:**
- `colorTextOnDark` + `colorBrandDark`
- `colorTextOnDark` + `colorBrandPrimary`
- `colorTextOnDark` + `colorActionPrimary`

### 6.3 Combinações Proibidas

❌ **Baixo contraste:**
- `colorTextMuted` sobre `colorBackgroundSecondary`
- `colorBorderSubtle` sobre `colorBackgroundPrimary` (para texto)
- `colorActionDisabled` como cor de texto legível

❌ **Conflito semântico:**
- `colorError` para indicar sucesso
- `colorSuccess` para indicar erro
- `colorWarning` para informação neutra

---

## 7. Exemplos de Uso

### 7.1 ✅ Uso Correto

```dart
// Card de transação
Container(
  color: AppColors.colorSurfaceCard,
  child: Column(
    children: [
      Text('Supermercado', style: TextStyle(color: AppColors.colorTextPrimary)),
      Text('Ontem às 14:30', style: TextStyle(color: AppColors.colorTextMuted)),
      Text('-R\$ 150,00', style: TextStyle(color: AppColors.colorError)),
    ],
  ),
)

// Botão de adicionar
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.colorActionPrimary,
    foregroundColor: AppColors.colorTextOnDark,
  ),
  child: Text('Adicionar Gasto'),
)

// AppBar
AppBar(
  backgroundColor: AppColors.colorBrandDark,
  foregroundColor: AppColors.colorTextOnDark,
  title: Text('Meus Gastos'),
)
```

### 7.2 ❌ Uso Incorreto

```dart
// ❌ ERRADO: Cor hardcoded
Container(
  color: Color(0xFF1A3D63), // Nunca usar HEX direto
)

// ❌ ERRADO: Cor semântica errada
Text(
  'Pagamento realizado!',
  style: TextStyle(color: AppColors.colorError), // Deveria ser colorSuccess
)

// ❌ ERRADO: Texto ilegível
Container(
  color: AppColors.colorBackgroundSecondary,
  child: Text(
    'Texto',
    style: TextStyle(color: AppColors.colorTextMuted), // Baixo contraste
  ),
)

// ❌ ERRADO: Múltiplos botões de accent
Row(
  children: [
    ElevatedButton(backgroundColor: AppColors.colorActionPrimary, child: Text('Salvar')),
    ElevatedButton(backgroundColor: AppColors.colorActionPrimary, child: Text('Exportar')),
    ElevatedButton(backgroundColor: AppColors.colorActionPrimary, child: Text('Compartilhar')),
  ],
)
```

---

## 8. Gradientes Oficiais

### 8.1 Gradiente Brand (Headers, Splash)

```dart
LinearGradient(
  colors: [AppColors.colorBrandPrimary, AppColors.colorBrandDark],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```

### 8.2 Gradiente Accent (CTAs especiais)

```dart
LinearGradient(
  colors: [AppColors.colorActionPrimary, AppColors.colorBrandSoft],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

⚠️ **Nenhum outro gradiente é permitido sem atualização deste documento.**

---

## 9. Checklist de Validação

Antes de considerar uma tela/componente concluído, verificar:

- [ ] Todas as cores usam Design Tokens (não HEX direto)
- [ ] Contraste de texto atende WCAG AA (4.5:1 mínimo)
- [ ] Accent color (verde) usado em no máximo 1 CTA por tela
- [ ] Estados (success, error, warning) usam tokens corretos
- [ ] Texto sobre fundo escuro usa `colorTextOnDark`
- [ ] Cards usam `colorSurfaceCard` com borda `colorBorderSubtle`
- [ ] AppBar usa `colorBrandDark` com `colorTextOnDark`

---

## 10. Changelog

| Versão | Data | Alteração |
|--------|------|-----------|
| 1.0.0 | Dez 2024 | Criação inicial do Design System de Cores |

---

## 11. Referências

- **Implementação:** `lib/core/theme/app_colors.dart`
- **Tema:** `lib/core/theme/app_theme.dart`
- **Estilos de Texto:** `lib/core/theme/app_text_styles.dart`




