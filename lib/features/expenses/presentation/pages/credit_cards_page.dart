import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/credit_card_controller.dart';
import '../widgets/credit_card_widget.dart';

/// Página de gerenciamento de cartões de crédito
class CreditCardsPage extends GetView<CreditCardController> {
  const CreditCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Cartões'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.creditCards.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.creditCards.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadCreditCards,
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.creditCards.length,
            itemBuilder: (context, index) {
              final card = controller.creditCards[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: CreditCardWidget(
                  card: card,
                  onTap: () => _showCardDetails(card.id),
                  onEdit: () => _showEditCardDialog(card.id),
                  onDelete: () => _confirmDelete(card.id, card.displayName),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Cartão'),
        backgroundColor: AppColors.primary,
      ),
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
              Icons.credit_card_outlined,
              size: 100.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.h),
            Text(
              'Nenhum cartão cadastrado',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Adicione um cartão de crédito para começar a gerenciar suas compras parceladas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _showAddCardDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Cartão'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDetails(String cardId) {
    Get.toNamed('/credit-card-details', arguments: cardId);
  }

  void _showAddCardDialog() {
    Get.toNamed('/add-credit-card');
  }

  void _showEditCardDialog(String cardId) {
    Get.toNamed('/edit-credit-card', arguments: cardId);
  }

  void _confirmDelete(String cardId, String cardName) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Deseja realmente remover o cartão "$cardName"?\n\n'
          'As despesas vinculadas a este cartão não serão excluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCreditCard(cardId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

