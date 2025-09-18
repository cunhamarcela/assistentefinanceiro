# 📚 Exemplos de Uso - Design System

## Como Usar os Componentes

### 1. Importações Necessárias

```dart
// Tema
import 'package:assistente_financeiro/core/theme/app_colors.dart';
import 'package:assistente_financeiro/core/theme/app_text_styles.dart';
import 'package:assistente_financeiro/core/theme/app_spacing.dart';
import 'package:assistente_financeiro/core/theme/app_theme.dart';

// Widgets
import 'package:assistente_financeiro/shared/widgets/buttons/app_button.dart';
import 'package:assistente_financeiro/shared/widgets/cards/app_card.dart';
import 'package:assistente_financeiro/shared/widgets/inputs/app_text_field.dart';
```

### 2. Configuração do Tema no App

```dart
// main.dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistente Financeiro',
      theme: AppTheme.lightTheme,
      home: HomeScreen(),
    );
  }
}
```

### 3. Usando Cores

```dart
// Cores principais
Container(
  color: AppColors.primary,        // Roxo principal
  child: Text(
    'Título',
    style: TextStyle(color: AppColors.textPrimary), // Branco
  ),
)

// Cores de estado
Container(
  decoration: BoxDecoration(
    color: AppColors.success,      // Verde para sucesso
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
)

// Gradientes
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

### 4. Usando Tipografia

```dart
// Títulos
Text('Título Principal', style: AppTextStyles.headline1),
Text('Subtítulo', style: AppTextStyles.headline2),
Text('Título Seção', style: AppTextStyles.headline3),

// Texto do corpo
Text('Texto normal', style: AppTextStyles.body1),
Text('Texto menor', style: AppTextStyles.body2),

// Texto especial
Text('R\$ 1.500,00', style: AppTextStyles.currency),
Text('CATEGORIA', style: AppTextStyles.label),

// Variações de cor
Text('Texto escuro', style: AppTextStyles.headline1Dark),
```

### 5. Usando Botões

```dart
// Botão padrão preenchido
AppButton(
  text: 'Salvar',
  onPressed: () => print('Clicado'),
)

// Botão com borda
AppButton.outlined(
  text: 'Cancelar',
  onPressed: () => print('Cancelado'),
)

// Botão pequeno
AppButton.small(
  text: 'OK',
  onPressed: () => print('OK'),
)

// Botão com ícone
AppButton(
  text: 'Adicionar',
  icon: Icons.add,
  onPressed: () => print('Adicionar'),
)

// Botão carregando
AppButton(
  text: 'Salvando...',
  loading: true,
  onPressed: null,
)

// Botão personalizado
AppButton(
  text: 'Especial',
  color: AppColors.accent,
  onPressed: () => print('Especial'),
)
```

### 6. Usando Cards

```dart
// Card básico
AppCard(
  child: Text('Conteúdo do card'),
)

// Card com padding
AppCard.padded(
  child: Column(
    children: [
      Text('Título'),
      Text('Conteúdo'),
    ],
  ),
)

// Card clicável
AppCard(
  onTap: () => print('Card clicado'),
  child: ListTile(
    title: Text('Item clicável'),
  ),
)

// Card do dashboard
HomeCard(
  title: 'Despesas',
  icon: Icons.receipt,
  onTap: () => Navigator.push(...),
)


// Card de resumo
SummaryCard(
  title: 'Total Gasto',
  value: 'R\$ 2.450,00',
  icon: Icons.trending_down,
  color: AppColors.error,
  subtitle: 'Este mês',
  onTap: () => print('Ver detalhes'),
)
```

### 7. Usando Campos de Texto

```dart
// Campo básico
AppTextField(
  label: 'Nome',
  hint: 'Digite seu nome',
  controller: _nameController,
  onChanged: (value) => print(value),
)

// Campo de email
AppTextField.email(
  controller: _emailController,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Email obrigatório';
    return null;
  },
)

// Campo de senha
AppTextField.password(
  controller: _passwordController,
  obscureText: _obscurePassword,
  onToggleVisibility: () {
    setState(() => _obscurePassword = !_obscurePassword);
  },
)

// Campo monetário
AppTextField.currency(
  label: 'Valor da Despesa',
  controller: _amountController,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ],
)

// Campo de busca
AppTextField.search(
  hint: 'Buscar despesas...',
  onChanged: (value) => _filterExpenses(value),
)

// Campo de texto longo
AppTextField.multiline(
  label: 'Observações',
  hint: 'Digite observações adicionais...',
  maxLines: 4,
  maxLength: 200,
)

// Dropdown
AppDropdown<String>(
  label: 'Categoria',
  hint: 'Selecione uma categoria',
  value: _selectedCategory,
  items: categories.map((category) => 
    DropdownMenuItem(
      value: category,
      child: Text(category),
    ),
  ).toList(),
  onChanged: (value) => setState(() => _selectedCategory = value),
)
```

### 8. Estrutura de Tela Padrão

```dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Título da Tela'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção
            Text(
              'Seção Principal',
              style: AppTextStyles.headline2Dark,
            ),
            SizedBox(height: AppSpacing.lg),
            
            // Cards em grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              children: [
                HomeCard(
                  title: 'Item 1',
                  icon: Icons.add,
                  onTap: () {},
                ),
                HomeCard(
                  title: 'Item 2',
                  icon: Icons.list,
                  onTap: () {},
                ),
              ],
            ),
            
            Spacer(),
            
            // Botão na parte inferior
            AppButton(
              text: 'Ação Principal',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

### 9. Formulário Completo

```dart
class ExpenseFormScreen extends StatefulWidget {
  @override
  _ExpenseFormScreenState createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Despesa'),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              AppTextField(
                label: 'Título',
                hint: 'Ex: Supermercado',
                controller: _titleController,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Título é obrigatório';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),
              
              AppTextField.currency(
                controller: _amountController,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Valor é obrigatório';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),
              
              AppDropdown<String>(
                label: 'Categoria',
                hint: 'Selecione uma categoria',
                value: _selectedCategory,
                items: ['Alimentação', 'Transporte', 'Lazer']
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) {
                  if (value == null) return 'Categoria é obrigatória';
                  return null;
                },
              ),
              
              Spacer(),
              
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      text: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Salvar',
                      loading: _isLoading,
                      onPressed: _isLoading ? null : _saveExpense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveExpense() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      // Simular salvamento
      await Future.delayed(Duration(seconds: 2));
      
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }
}
```

### 10. Lista com Cards

```dart
class ExpenseListScreen extends StatelessWidget {
  final List<Expense> expenses = [
    // Lista de despesas...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Despesas'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppTextField.search(
              onChanged: (value) => _filterExpenses(value),
            ),
          ),
          
          // Lista de despesas
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                // ExpenseCard específico do domínio será usado aqui
                return Container(); // Placeholder
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### 11. Dashboard com Resumos

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo financeiro
            Text(
              'Resumo do Mês',
              style: AppTextStyles.headline2Dark,
            ),
            SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Receitas',
                    value: 'R\$ 5.000,00',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SummaryCard(
                    title: 'Despesas',
                    value: 'R\$ 3.200,00',
                    icon: Icons.trending_down,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppSpacing.lg),
            
            // Ações rápidas
            Text(
              'Ações Rápidas',
              style: AppTextStyles.headline2Dark,
            ),
            SizedBox(height: AppSpacing.md),
            
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              children: [
                HomeCard(
                  title: 'Nova Despesa',
                  icon: Icons.add,
                  onTap: () => _addExpense(),
                ),
                HomeCard(
                  title: 'Ver Despesas',
                  icon: Icons.list,
                  onTap: () => _viewExpenses(),
                ),
                HomeCard(
                  title: 'Relatórios',
                  icon: Icons.bar_chart,
                  onTap: () => _viewReports(),
                ),
                HomeCard(
                  title: 'Configurações',
                  icon: Icons.settings,
                  onTap: () => _openSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Dicas de Uso

### 1. Consistência Visual
- Sempre use as cores definidas em `AppColors`
- Use os estilos de texto de `AppTextStyles`
- Mantenha espaçamentos consistentes com `AppSpacing`

### 2. Responsividade
- Use `Expanded` e `Flexible` para layouts adaptativos
- Teste em diferentes tamanhos de tela
- Use `MediaQuery` quando necessário para breakpoints

### 3. Acessibilidade
- Sempre forneça `semanticsLabel` para ícones
- Use contrastes adequados
- Teste com TalkBack/VoiceOver

### 4. Performance
- Use `const` constructors quando possível
- Evite reconstruções desnecessárias
- Use `ListView.builder` para listas grandes

### 5. Manutenibilidade
- Mantenha componentes pequenos e focados
- Use composição ao invés de herança
- Documente componentes customizados
