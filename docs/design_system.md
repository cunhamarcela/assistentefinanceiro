# 🎨 Design System - Assistente Financeiro

## Visão Geral

Este documento define o sistema de design para o aplicativo Assistente Financeiro, garantindo consistência visual e experiência de usuário em todas as telas e componentes.

## 🎨 Paleta de Cores

### Cores Principais

```dart
class AppColors {
  static const primary = Color(0xFF6A4DFF);     // Roxo principal
  static const secondary = Color(0xFF1C1C1E);   // Fundo escuro
  static const accent = Color(0xFFFFC542);      // Amarelo de destaque
  static const blue = Color(0xFF0052CC);        // Azul Monarch
  static const surface = Color(0xFFF5F5F7);     // Superfície clara
  static const textPrimary = Colors.white;      // Texto principal
  static const textSecondary = Color(0xFF8E8E93); // Texto secundário
}
```

### Uso das Cores

- **Primary (Roxo)**: AppBars, botões principais, ícones de destaque
- **Secondary (Escuro)**: Fundos alternativos, elementos de contraste
- **Accent (Amarelo)**: Elementos de destaque, indicadores importantes
- **Blue (Azul)**: Links, elementos informativos
- **Surface (Claro)**: Cards, superfícies elevadas
- **Text Primary (Branco)**: Títulos, texto sobre fundos escuros
- **Text Secondary (Cinza)**: Subtítulos, texto auxiliar

## ✍️ Tipografia

### Hierarquia Textual

```dart
class AppText {
  static const headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
```

### Estilos Adicionais Recomendados

```dart
// Adicionar ao AppText
static const headline3 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

static const subtitle1 = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  color: AppColors.textSecondary,
);

static const subtitle2 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: AppColors.textSecondary,
);

static const caption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: AppColors.textSecondary,
);

static const button = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);
```

## 🔘 Componentes

### Botões

#### AppButton - Botão Principal

```dart
AppButton(
  text: "Texto do Botão",
  onTap: () {},
  filled: true, // true para preenchido, false para outline
)
```

**Variações:**
- `filled: true` - Botão preenchido com cor primária
- `filled: false` - Botão com borda e fundo transparente

#### Botões Adicionais Recomendados

```dart
// Botão pequeno
class AppButtonSmall extends StatelessWidget {
  // Implementação similar ao AppButton com padding reduzido
}

// Botão com ícone
class AppButtonIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  // Implementação
}

// Botão flutuante
class AppFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  // Implementação
}
```

### Cards

#### HomeCard - Card do Dashboard

```dart
HomeCard(
  title: "Título do Card",
  icon: Icons.icon_name,
)
```

#### Cards Adicionais Recomendados

```dart

// Card de resumo financeiro
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  // Implementação
}

// Card de categoria
class CategoryCard extends StatelessWidget {
  final String name;
  final Color color;
  final double spent;
  final double budget;
  // Implementação
}
```

## 📱 Layout e Espaçamento

### Padding e Margin Padrões

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

### Border Radius Padrões

```dart
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circular = 50.0;
}
```

## 🖼️ Ícones

### Ícones do Sistema

- **Adicionar**: `Icons.add`
- **Despesas**: `Icons.receipt`
- **Relatórios**: `Icons.bar_chart`
- **Configurações**: `Icons.settings`
- **Gráfico Pizza**: `Icons.pie_chart`
- **Carteira**: `Icons.account_balance_wallet`
- **Chat**: `Icons.chat`
- **Câmera**: `Icons.camera_alt`
- **Calendário**: `Icons.calendar_today`
- **Filtro**: `Icons.filter_list`

## 📋 Padrões de Tela

### Estrutura Base

```dart
Scaffold(
  appBar: AppBar(
    backgroundColor: AppColors.primary,
    title: Text("Título da Tela"),
    elevation: 0,
  ),
  body: Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: // Conteúdo da tela
  ),
)
```

### AppBar Padrão

- Cor de fundo: `AppColors.primary`
- Texto: Branco
- Elevação: 0 (flat design)
- Altura: Padrão do Material Design

### Navegação

```dart
// Bottom Navigation Bar
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  items: [
    // Items de navegação
  ],
)
```

## 🎯 Telas Específicas

### 1. Tela de Autenticação
- Fundo: `AppColors.primary`
- Texto principal: `AppText.headline1`
- Centralizado verticalmente

### 2. Onboarding
- Fundo: `AppColors.surface`
- PageView com indicadores
- Botão fixo na parte inferior

### 3. Dashboard/Home
- AppBar com cor primária
- Grid 2x2 de cards
- Cards com `AppColors.surface`

### 4. Adicionar Despesa
- Formulário com campos de entrada
- Botão de ação na parte inferior
- Validação visual dos campos

### 5. Lista de Despesas
- ListView com ListTiles
- Separadores visuais
- Ações de swipe (opcional)

### 6. Relatórios
- Gráficos e visualizações
- Cards de resumo
- Filtros na parte superior

## 🎨 Estados Visuais

### Estados de Botão
- **Normal**: Cor primária
- **Pressed**: Cor primária com opacidade 0.8
- **Disabled**: Cinza com opacidade 0.5

### Estados de Input
- **Normal**: Borda cinza clara
- **Focused**: Borda cor primária
- **Error**: Borda vermelha
- **Disabled**: Fundo cinza claro

### Estados de Card
- **Normal**: Elevação 2
- **Pressed**: Elevação 4
- **Selected**: Borda cor primária

## 📐 Responsividade

### Breakpoints
- **Mobile**: < 600px
- **Tablet**: 600px - 1024px
- **Desktop**: > 1024px

### Adaptações
- Grid responsivo (1 coluna mobile, 2+ colunas tablet/desktop)
- Padding adaptativo
- Tamanhos de fonte escaláveis

## ♿ Acessibilidade

### Contraste
- Todas as combinações de cor atendem WCAG AA
- Texto sobre fundo tem contraste mínimo 4.5:1

### Tamanhos Mínimos
- Botões: 44x44px mínimo
- Texto: 16px mínimo para leitura
- Áreas tocáveis: 48x48px recomendado

### Semântica
- Uso correto de Semantics widgets
- Labels descritivos para ações
- Navegação por teclado suportada

## 🔧 Implementação

### Estrutura de Arquivos Recomendada

```
lib/
  core/
    theme/
      app_colors.dart
      app_text_styles.dart
      app_theme.dart
  shared/
    widgets/
      buttons/
        app_button.dart
        app_button_small.dart
        app_button_icon.dart
      cards/
        home_card.dart
        expense_card.dart
        summary_card.dart
      inputs/
        app_text_field.dart
        app_dropdown.dart
```

### Theme Configuration

```dart
class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      titleTextStyle: AppText.headline2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    // Mais configurações...
  );
}
```

## 📝 Checklist de Implementação

### Para cada nova tela:
- [ ] Usar AppBar padrão com cor primária
- [ ] Aplicar padding padrão (16px)
- [ ] Usar estilos de texto definidos
- [ ] Implementar estados de loading/error
- [ ] Testar em diferentes tamanhos de tela
- [ ] Verificar acessibilidade
- [ ] Validar contraste de cores

### Para cada novo componente:
- [ ] Seguir padrões de nomenclatura (App + Nome)
- [ ] Implementar estados visuais necessários
- [ ] Documentar props e uso
- [ ] Adicionar exemplos de implementação
- [ ] Testar responsividade

---

**Versão**: 1.0  
**Última atualização**: Dezembro 2024  
**Responsável**: Equipe de Desenvolvimento
