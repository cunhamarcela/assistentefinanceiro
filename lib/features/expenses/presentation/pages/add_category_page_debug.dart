import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../controllers/category_controller.dart';

/// Versão de debug da tela de criar categoria para identificar problemas
class AddCategoryPageDebug extends GetView<CategoryController> {
  const AddCategoryPageDebug({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Categoria - Debug'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teste básico de layout
              Container(
                height: 100.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Center(
                  child: Text(
                    'Teste de Layout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Campo de texto simples
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome da Categoria',
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Grid simples de ícones
              Container(
                height: 200.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: EdgeInsets.all(8.w),
                  children: List.generate(8, (index) {
                    return Container(
                      margin: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Grid simples de cores
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Wrap(
                  children: [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                  ].map((color) {
                    return Container(
                      width: 40.w,
                      height: 40.w,
                      margin: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Botão simples
              ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'Teste',
                    'Botão funcionando!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text('Testar'),
              ),
              
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}
