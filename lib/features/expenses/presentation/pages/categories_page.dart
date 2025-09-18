import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../controllers/category_controller.dart';
import '../widgets/category_card.dart';
import '../widgets/category_usage_card.dart';

class CategoriesPage extends GetView<CategoryController> {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter_custom':
                  controller.showOnlyCustom.toggle();
                  break;
                case 'clear_filters':
                  controller.clearFilters();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter_custom',
                child: Obx(() => Row(
                  children: [
                    Icon(
                      controller.showOnlyCustom.value 
                          ? Icons.check_box 
                          : Icons.check_box_outline_blank,
                    ),
                    const SizedBox(width: 8),
                    const Text('Apenas personalizadas'),
                  ],
                )),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Limpar filtros'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: CustomScrollView(
          slivers: [
            // Estatísticas de uso
            SliverToBoxAdapter(
              child: _buildUsageStats(),
            ),
            
            // Filtros ativos
            SliverToBoxAdapter(
              child: _buildActiveFilters(),
            ),
            
            // Lista de categorias
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final filteredCategories = controller.filteredCategories;

              if (filteredCategories.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = filteredCategories[index];
                      return CategoryCard(
                        category: category,
                        onTap: () => _showCategoryDetails(category),
                        onEdit: category.isDefault 
                            ? null 
                            : () => _editCategory(category),
                        onDelete: category.isDefault 
                            ? null 
                            : () => controller.confirmDeleteCategory(category),
                      );
                    },
                    childCount: filteredCategories.length,
                  ),
                ),
              );
            }),
            
            // Padding bottom para FAB
            SliverToBoxAdapter(
              child: SizedBox(height: 100.h),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addCategory),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildUsageStats() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categorias Mais Usadas',
            style: AppTextStyles.headline3.copyWith(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Obx(() {
            if (controller.categoryUsages.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Nenhuma estatística disponível',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.categoryUsages.length,
                itemBuilder: (context, index) {
                  final usage = controller.categoryUsages[index];
                  return Container(
                    width: 200.w,
                    margin: EdgeInsets.only(right: 12.w),
                    child: CategoryUsageCard(usage: usage),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Obx(() {
      final hasFilters = controller.searchQuery.value.isNotEmpty || 
                       controller.showOnlyCustom.value;

      if (!hasFilters) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _getActiveFiltersText(),
                style: AppTextStyles.body2.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: controller.clearFilters,
              child: const Text('Limpar'),
            ),
          ],
        ),
      );
    });
  }

  String _getActiveFiltersText() {
    final filters = <String>[];
    
    if (controller.searchQuery.value.isNotEmpty) {
      filters.add('Busca: "${controller.searchQuery.value}"');
    }
    
    if (controller.showOnlyCustom.value) {
      filters.add('Apenas personalizadas');
    }
    
    return filters.join(' • ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'Nenhuma categoria encontrada',
            style: AppTextStyles.headline3.copyWith(
              fontSize: 18.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Crie sua primeira categoria personalizada',
            style: AppTextStyles.body2.copyWith(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.addCategory),
            icon: const Icon(Icons.add),
            label: const Text('Criar Categoria'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController(text: controller.searchQuery.value);
    
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Categorias'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Digite o nome ou palavra-chave...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onChanged: (value) {
            controller.searchQuery.value = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.searchQuery.value = '';
              Navigator.of(context).pop();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(category) async {
    final stats = await controller.getCategoryStats(category.id);
    
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
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
              
              // Cabeçalho da categoria
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      category.iconData,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          category.isDefault ? 'Categoria padrão' : 'Categoria personalizada',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!category.isDefault) ...[
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _editCategory(category);
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.confirmDeleteCategory(category);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // Estatísticas
              if (stats != null) ...[
                Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Despesas',
                        stats.expenseCount.toString(),
                        Icons.receipt,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        'R\$ ${stats.totalAmount.toStringAsFixed(2)}',
                        Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
              
              // Palavras-chave
              Text(
                'Palavras-chave',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Flexible(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: category.keywords.map<Widget>((keyword) => Chip(
                    label: Text(
                      keyword,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    backgroundColor: category.color.withOpacity(0.1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.w, color: AppColors.primary),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _editCategory(category) {
    Get.toNamed(AppRoutes.editCategory, arguments: category);
  }
}


