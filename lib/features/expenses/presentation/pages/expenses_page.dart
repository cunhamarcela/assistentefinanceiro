import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../controllers/expense_controller.dart';
import '../widgets/expense_card.dart';

class ExpensesPage extends GetView<ExpenseController> {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Despesas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros ativos
          Obx(() {
            if (!controller.hasActiveFilters) {
              return const SizedBox.shrink();
            }
            
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              color: AppColors.accent.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16.sp,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      controller.activeFilterText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            );
          }),
          
          // Lista de despesas
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.expenses.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: controller.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = controller.expenses[index];
                    final category = controller.getCategoryById(expense.categoryId);
                    
                    return ExpenseCard(
                      expense: expense,
                      category: category,
                      onTap: () {
                        // TODO: Navegar para detalhes da despesa
                        _showExpenseDetails(expense);
                      },
                      onLongPress: () {
                        _showExpenseOptions(expense);
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addExpense),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'Nenhuma despesa encontrada',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.hasActiveFilters
                  ? 'Tente ajustar os filtros ou limpar a busca'
                  : 'Adicione sua primeira despesa para começar',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.addExpense),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Despesa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            Get.offNamed(AppRoutes.home);
            break;
          case 1:
            // Já está na página de despesas
            break;
          case 2:
            Get.toNamed(AppRoutes.addExpense);
            break;
          case 3:
            Get.toNamed(AppRoutes.analytics);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Despesas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle),
          label: 'Adicionar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Relatórios',
        ),
      ],
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Despesas'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Digite para buscar...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.searchExpenses(searchController.text);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              
              // Título
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Filtros rápidos
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Período
                    ListTile(
                      leading: const Icon(Icons.today),
                      title: const Text('Hoje'),
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.loadTodayExpenses();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Este Mês'),
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.loadCurrentMonthExpenses();
                      },
                    ),
                    
                    const Divider(),
                    
                    // Categorias
                    Text(
                      'Por Categoria',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    ...controller.categories.map((category) => ListTile(
                      leading: Icon(
                        category.iconData,
                        color: category.color,
                      ),
                      title: Text(category.name),
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.filterByCategory(category.id);
                      },
                    )),
                    
                    const Divider(),
                    
                    // Limpar filtros
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('Limpar Filtros'),
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.clearFilters();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(expense) {
    final category = controller.getCategoryById(expense.categoryId);
    
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            
            // Detalhes da despesa
            Text(
              'Detalhes da Despesa',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            
            ExpenseCard(
              expense: expense,
              category: category,
            ),
            
            SizedBox(height: 16.h),
            
            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.toNamed('/edit-expense', arguments: expense);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.confirmDeleteExpense(expense);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseOptions(expense) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.of(context).pop();
              Get.toNamed('/edit-expense', arguments: expense);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              controller.confirmDeleteExpense(expense);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Detalhes'),
            onTap: () {
              Navigator.of(context).pop();
              _showExpenseDetails(expense);
            },
          ),
        ],
      ),
    );
  }

}
