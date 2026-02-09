import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            ],
          ),
        ),
        isDismissible: false, // Impede fechar tocando fora do bottomSheet
        enableDrag: false,    // Impede fechar arrastando o bottomSheet
      );
      
      if (options != null) {
        await _pickImageWithErrorHandling(options);
      }
    } catch (e) {
      print('Erro geral ao alterar foto: $e');
      _showErrorMessage('Erro inesperado ao alterar foto do perfil');
    }
  }

  /// Selecionar imagem com tratamento robusto de erros
  Future<void> _pickImageWithErrorHandling(ImageSource source) async {
    try {
      // Verificar se a fonte é câmera e se está disponível
      if (source == ImageSource.camera) {
        // Adicionar delay para evitar problemas de timing no iPad
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        requestFullMetadata: false, // Reduzir overhead no iPad
      );
      
      if (image != null) {
        // Verificar se o arquivo existe e é válido
        final fileSize = await image.length();
        if (fileSize > 0) {
          // TODO: Implementar upload da imagem
          Get.snackbar(
            'Sucesso',
            'Foto selecionada! Upload será implementado em breve.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          _showErrorMessage('Arquivo de imagem inválido');
        }
      }
    } on PlatformException catch (e) {
      print('PlatformException ao selecionar imagem: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'camera_access_denied':
          _showPermissionError('Acesso à câmera negado. Verifique as permissões nas Configurações.');
          break;
        case 'photo_access_denied':
          _showPermissionError('Acesso à galeria negado. Verifique as permissões nas Configurações.');
          break;
        case 'camera_unavailable':
          _showErrorMessage('Câmera não disponível neste dispositivo');
          break;
        default:
          _showErrorMessage('Erro ao acessar ${source == ImageSource.camera ? 'câmera' : 'galeria'}: ${e.message ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      print('Erro inesperado ao selecionar imagem: $e');
      _showErrorMessage('Erro inesperado ao selecionar foto');
    }
  }

  /// Mostrar mensagem de erro padrão
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Erro',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Mostrar mensagem de erro de permissão com ação
  void _showPermissionError(String message) {
    Get.snackbar(
      'Permissão Necessária',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
      mainButton: TextButton(
        onPressed: () {
          // Abrir configurações do app
          // openAppSettings(); // Requer package permission_handler
        },
        child: const Text(
          'Configurações',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
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
