import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/auth/data/services/auth_service.dart';
import '../../../../features/auth/data/models/user_model.dart';
import 'profile_controller.dart';

class EditProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Form key
  final formKey = GlobalKey<FormState>();
  
  // Text controllers
  final usernameController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  
  // Observables
  final _isLoading = false.obs;
  final _user = Rxn<UserModel>();
  
  // Getters
  bool get isLoading => _isLoading.value;
  UserModel? get user => _user.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }
  
  @override
  void onClose() {
    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    super.onClose();
  }
  
  /// Carrega dados do usuário
  void _loadUserData() {
    _user.value = _authService.currentUser;
    if (_user.value != null) {
      usernameController.text = _user.value!.name;
      fullNameController.text = _user.value!.name;
      emailController.text = _user.value!.email;
    }
  }
  
  /// Obtém iniciais do nome para avatar
  String get initials {
    final name = usernameController.text.isNotEmpty 
        ? usernameController.text 
        : user?.email.split('@').first ?? 'U';
    
    if (name.isEmpty) return 'U';
    
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
  
  /// Validação do nome de usuário
  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome de usuário é obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    return null;
  }
  
  /// Validação do nome completo
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome completo é obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    return null;
  }
  
  /// Validação do email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }
  
  /// Alterar foto do perfil
  Future<void> changePhoto() async {
    try {
      final options = await Get.bottomSheet<ImageSource>(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Alterar foto do perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
      
      if (options != null) {
        final XFile? image = await _imagePicker.pickImage(
          source: options,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        
        if (image != null) {
          // TODO: Implementar upload da imagem
          Get.snackbar(
            'Sucesso',
            'Foto selecionada! Upload será implementado em breve.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao selecionar foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  /// Salvar alterações do perfil
  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    try {
      _isLoading.value = true;
      
      final username = usernameController.text.trim();
      
      // Atualizar perfil no Firebase
      await _authService.updateProfile(displayName: username);
      
      // Atualizar controller do perfil
      final profileController = Get.find<ProfileController>();
      profileController.refreshUserData();
      
      Get.snackbar(
        'Sucesso',
        'Perfil atualizado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar perfil: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
