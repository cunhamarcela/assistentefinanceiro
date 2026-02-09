/// Módulo de Receitas (Income)
/// 
/// Este módulo gerencia:
/// - Registro de receitas/entradas de dinheiro
/// - Tipos de receita (salário, freelance, investimentos, etc.)
/// - Receitas recorrentes
/// - Relatórios de receitas

// Domain - Entidades
export 'domain/entities/income.dart';

// Domain - Repositórios
export 'domain/repositories/income_repository.dart';

// Data - Models
export 'data/models/income_model.dart';

// Data - Repositórios
export 'data/repositories/income_repository_impl.dart';

// Presentation - Controllers
export 'presentation/controllers/income_controller.dart';

// Presentation - Bindings
export 'presentation/bindings/income_binding.dart';

// Presentation - Pages
export 'presentation/pages/income_list_page.dart';
export 'presentation/pages/add_income_page.dart';




