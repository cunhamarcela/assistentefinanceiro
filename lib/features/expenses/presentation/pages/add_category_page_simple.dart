import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';

/// Versão mais simples da tela de criar categoria sem ScreenUtil
class AddCategoryPageSimple extends StatelessWidget {
  const AddCategoryPageSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Categoria - Simples'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Teste básico de layout
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Teste de Layout Simples',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Campo de texto simples
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome da Categoria',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Container simples
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Área de Seleção de Ícones',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Container simples para cores
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Área de Seleção de Cores',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botão simples
              ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'Teste',
                    'Tela simples funcionando!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text('Testar Tela Simples'),
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
