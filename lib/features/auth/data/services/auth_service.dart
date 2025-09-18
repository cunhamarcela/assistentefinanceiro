import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../../../../core/storage/secure_storage.dart';
import 'firestore_user_service.dart';
import '../../../expenses/data/repositories/expense_hybrid_repository.dart';
import '../../../expenses/data/datasources/expense_local_datasource.dart';
import '../../../expenses/data/datasources/expense_firestore_datasource.dart';

/// Exceção personalizada para autenticação
class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => 'AuthException: $message';
}

/// Serviço principal de autenticação
class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SecureStorage _secureStorage = SecureStorage.instance;
  FirestoreUserService? _firestoreUserService;

  // Observables
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _lastError = ''.obs;

  // Getters
  UserModel? get currentUser => _currentUser.value;
  bool get isAuthenticated => _currentUser.value != null && _currentUser.value!.isNotEmpty;
  bool get isLoading => _isLoading.value;
  String get lastError => _lastError.value;
  bool get isEmailVerified => _currentUser.value?.emailVerified ?? false;

  // Stream do estado de autenticação
  Stream<UserModel?> get authStateChanges => _currentUser.stream;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      if (!Get.isRegistered<FirestoreUserService>()) {
        Get.put<FirestoreUserService>(FirestoreUserService());
      }
      _firestoreUserService = Get.find<FirestoreUserService>();
    } catch (e) {
      print('Erro ao inicializar FirestoreUserService: $e');
      _firestoreUserService = FirestoreUserService();
    }
    await _initializeAuth();
  }

  /// Inicializar autenticação
  Future<void> _initializeAuth() async {
    try {
      _isLoading.value = true;

      // Escutar mudanças no estado de autenticação do Firebase
      _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);

      // Tentar recuperar usuário salvo
      await _loadSavedUser();
    } catch (e) {
      _handleError('Erro ao inicializar autenticação', e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Callback para mudanças no estado de autenticação
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      _currentUser.value = userModel;
      
      // Salvar dados localmente
      await _secureStorage.saveUserData(userModel);
      
      // Salvar dados no Firestore
      try {
        await _firestoreUserService?.saveUserToFirestore(userModel);
        await _firestoreUserService?.updateLastLogin(userModel.id);
      } catch (e) {
        print('Erro ao salvar no Firestore: $e');
      }
      
      // Inicializar categorias padrão para o usuário
      _initializeUserDefaultCategories();
      
      // Salvar token se disponível
      try {
        final token = await firebaseUser.getIdToken();
        if (token != null) {
          await _secureStorage.saveAccessToken(token);
        }
      } catch (e) {
        print('Erro ao salvar token: $e');
      }
    } else {
      _currentUser.value = null;
      await _secureStorage.clearAuthData();
    }
  }

  /// Carregar usuário salvo
  Future<void> _loadSavedUser() async {
    try {
      final savedUser = await _secureStorage.getUserData();
      if (savedUser != null && savedUser.isNotEmpty) {
        // Verificar se o usuário ainda está logado no Firebase
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          _currentUser.value = savedUser;
        } else {
          // Limpar dados se não há usuário no Firebase
          await _secureStorage.clearAuthData();
        }
      }
    } catch (e) {
      print('Erro ao carregar usuário salvo: $e');
    }
  }

  /// Login com email e senha
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      _validateEmail(email);
      _validatePassword(password);

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException('Falha na autenticação');
      }

      final userModel = UserModel.fromFirebaseUser(credential.user!);
      _currentUser.value = userModel;

      // Salvar dados
      await _secureStorage.saveUserData(userModel);
      await _secureStorage.saveLastEmail(email.trim());

      return userModel;
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      _lastError.value = message;
      throw AuthException(message, code: e.code);
    } catch (e) {
      final message = 'Erro inesperado durante o login';
      _lastError.value = message;
      throw AuthException(message);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Registro com email e senha
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      _validateEmail(email);
      _validatePassword(password);
      _validateName(name);

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException('Falha ao criar conta');
      }

      // Atualizar nome do usuário
      await credential.user!.updateDisplayName(name.trim());
      await credential.user!.reload();

      // Enviar email de verificação
      await credential.user!.sendEmailVerification();

      final userModel = UserModel.fromFirebaseUser(credential.user!);
      _currentUser.value = userModel;

      // Salvar dados
      await _secureStorage.saveUserData(userModel);
      await _secureStorage.saveLastEmail(email.trim());

      return userModel;
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      _lastError.value = message;
      throw AuthException(message, code: e.code);
    } catch (e) {
      final message = 'Erro inesperado durante o registro';
      _lastError.value = message;
      throw AuthException(message);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login com Google
  Future<UserModel> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Login com Google cancelado');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw const AuthException('Falha na autenticação com Google');
      }

      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      _currentUser.value = userModel;

      // Salvar dados
      await _secureStorage.saveUserData(userModel);
      await _secureStorage.saveLastEmail(userModel.email);

      return userModel;
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      _lastError.value = message;
      throw AuthException(message, code: e.code);
    } catch (e) {
      final message = 'Erro inesperado durante login com Google';
      _lastError.value = message;
      throw AuthException(message);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login com Apple
  Future<UserModel> signInWithApple() async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      print('Iniciando Apple Sign-In...');
      
      // Verificar se Sign in with Apple está disponível
      final isAvailable = await SignInWithApple.isAvailable();
      print('Apple Sign-In disponível: $isAvailable');
      
      if (!isAvailable) {
        throw const AuthException('Sign in with Apple não está disponível neste dispositivo');
      }

      print('🍎 ========== INÍCIO APPLE SIGN IN NATIVO ==========');
      
      // Implementação 100% nativa (como Ray Club)
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      print('✅ Credenciais Apple obtidas com sucesso');
      print('✅ Identity token obtido: ${appleCredential.identityToken != null}');
      
      print('Credenciais recebidas do Apple: ${appleCredential.userIdentifier}');

   final oauthCredential = OAuthProvider("apple.com").credential(
     idToken: appleCredential.identityToken,
     accessToken: appleCredential.authorizationCode,
   );

      print('Autenticando com Firebase...');
      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      
      if (userCredential.user == null) {
        throw const AuthException('Falha na autenticação com Apple');
      }

      // Se é o primeiro login com Apple e temos informações do nome
      if (userCredential.additionalUserInfo?.isNewUser == true && 
          appleCredential.givenName != null && 
          appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
      }

      final userModel = UserModel.fromFirebaseUser(userCredential.user!);
      _currentUser.value = userModel;

      // Salvar dados
      await _secureStorage.saveUserData(userModel);
      if (userModel.email.isNotEmpty) {
        await _secureStorage.saveLastEmail(userModel.email);
      }

      print('✅ Autenticação Apple concluída com sucesso!');
      print('🍎 ========== FIM APPLE SIGN IN SUCCESS ==========');

      return userModel;
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Sign-In Authorization Exception: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          message = 'Login com Apple cancelado pelo usuário';
          break;
        case AuthorizationErrorCode.failed:
          message = 'Falha na autenticação com Apple. Verifique sua conexão.';
          break;
        case AuthorizationErrorCode.invalidResponse:
          message = 'Resposta inválida do Apple. Tente novamente.';
          break;
        case AuthorizationErrorCode.notHandled:
          message = 'Erro não tratado do Apple. Contate o suporte.';
          break;
        case AuthorizationErrorCode.unknown:
        default:
          // Erro 1000 específico do simulador/configuração
          if (e.message.contains('1000')) {
            message = 'Apple Sign-In não configurado.\n\nPara usar:\n• Configure no Firebase Console\n• Ou teste em dispositivo físico\n• Ou use Google/Email';
          } else {
            message = 'Erro de configuração do Apple Sign-In.\n\nUse Google Sign-In ou Email/Senha por enquanto.';
          }
          break;
      }
      _lastError.value = message;
      throw AuthException(message, code: e.code.toString());
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      _lastError.value = message;
      throw AuthException(message, code: e.code);
    } catch (e) {
      print('Erro inesperado no Apple Sign-In: $e');
      String message = 'Erro inesperado durante login com Apple';
      
      // Tratamento específico para erros comuns
      if (e.toString().contains('network')) {
        message = 'Erro de conexão. Verifique sua internet e tente novamente.';
      } else if (e.toString().contains('unavailable')) {
        message = 'Apple Sign-In não está disponível no momento.';
      } else if (e.toString().contains('configuration')) {
        message = 'Erro de configuração do Apple Sign-In.';
      }
      
      _lastError.value = message;
      throw AuthException(message);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Recuperação de senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';

      _validateEmail(email);

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      _lastError.value = message;
      throw AuthException(message, code: e.code);
    } catch (e) {
      final message = 'Erro ao enviar email de recuperação';
      _lastError.value = message;
      throw AuthException(message);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Enviar email de verificação
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('Usuário não está logado');
      }

      if (user.emailVerified) {
        throw const AuthException('Email já está verificado');
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      throw AuthException(message, code: e.code);
    }
  }

  /// Recarregar dados do usuário
  Future<void> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = UserModel.fromFirebaseUser(_firebaseAuth.currentUser!);
        _currentUser.value = updatedUser;
        await _secureStorage.saveUserData(updatedUser);
      }
    } catch (e) {
      print('Erro ao recarregar usuário: $e');
    }
  }

  /// Atualizar perfil do usuário
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _isLoading.value = true;
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        throw const AuthException('Usuário não está logado');
      }

      if (displayName != null) {
        _validateName(displayName);
        await user.updateDisplayName(displayName.trim());
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
      final updatedUser = UserModel.fromFirebaseUser(_firebaseAuth.currentUser!);
      _currentUser.value = updatedUser;
      await _secureStorage.saveUserData(updatedUser);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      throw AuthException(message, code: e.code);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reautenticar usuário com senha
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        throw const AuthException('Usuário não está logado');
      }

      if (user.email == null) {
        throw const AuthException('Email do usuário não encontrado');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      throw AuthException(message, code: e.code);
    }
  }

  /// Alterar senha
  Future<void> updatePassword(String newPassword) async {
    try {
      _isLoading.value = true;
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        throw const AuthException('Usuário não está logado');
      }

      _validatePassword(newPassword);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      throw AuthException(message, code: e.code);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Obter token de ID
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken(forceRefresh);
      if (token != null) {
        await _secureStorage.saveAccessToken(token);
      }
      return token;
    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      _isLoading.value = true;

      // Logout do Google se estiver logado
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Logout do Firebase
      await _firebaseAuth.signOut();

      // Limpar dados locais
      _currentUser.value = null;
      await _secureStorage.clearAuthData();
      _lastError.value = '';
    } catch (e) {
      print('Erro durante logout: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Excluir conta
  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        throw const AuthException('Usuário não está logado');
      }

      await user.delete();
      _currentUser.value = null;
      await _secureStorage.clearAll();
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseErrorMessage(e.code);
      throw AuthException(message, code: e.code);
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== VALIDAÇÕES ====================

  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw const AuthException('Email é obrigatório');
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      throw const AuthException('Email inválido');
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw const AuthException('Senha é obrigatória');
    }
    
    if (password.length < 6) {
      throw const AuthException('Senha deve ter pelo menos 6 caracteres');
    }
    
    if (password.length > 128) {
      throw const AuthException('Senha muito longa (máximo 128 caracteres)');
    }
  }

  void _validateName(String name) {
    if (name.isEmpty) {
      throw const AuthException('Nome é obrigatório');
    }
    
    if (name.trim().length < 2) {
      throw const AuthException('Nome deve ter pelo menos 2 caracteres');
    }
    
    if (name.length > 100) {
      throw const AuthException('Nome muito longo (máximo 100 caracteres)');
    }
  }

  // ==================== TRATAMENTO DE ERROS ====================

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Conta desabilitada';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'invalid-credential':
        return 'Credenciais inválidas';
      case 'account-exists-with-different-credential':
        return 'Conta já existe com credencial diferente';
      case 'requires-recent-login':
        return 'Operação requer login recente';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      default:
        return 'Erro de autenticação: $errorCode';
    }
  }

  void _handleError(String message, dynamic error) {
    print('$message: $error');
    _lastError.value = message;
  }

  /// Método para testar se Apple Sign-In está configurado corretamente
  Future<Map<String, dynamic>> testAppleSignInConfiguration() async {
    final result = <String, dynamic>{};
    
    try {
      // Verificar disponibilidade
      final isAvailable = await SignInWithApple.isAvailable();
      result['isAvailable'] = isAvailable;
      
      if (!isAvailable) {
        result['error'] = 'Apple Sign-In não está disponível neste dispositivo';
        result['suggestion'] = 'Teste em um dispositivo iOS físico ou simulador iOS 13+';
        return result;
      }
      
      result['status'] = 'Configuração OK';
      result['message'] = 'Apple Sign-In está disponível e configurado';
      
    } catch (e) {
      result['error'] = e.toString();
      result['suggestion'] = 'Verifique a configuração do Apple Sign-In no projeto iOS';
    }
    
    return result;
  }

  /// Inicializar categorias padrão para o usuário
  void _initializeUserDefaultCategories() {
    // Executa em background para não bloquear o login
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Verificar se os serviços de despesas estão disponíveis
        if (Get.isRegistered<ExpenseLocalDataSource>() && 
            Get.isRegistered<ExpenseFirestoreDataSource>()) {
          
          final localDataSource = Get.find<ExpenseLocalDataSource>();
          final firestoreDataSource = Get.find<ExpenseFirestoreDataSource>();
          
          final repository = ExpenseHybridRepository(
            localDataSource: localDataSource,
            firestoreDataSource: firestoreDataSource,
          );
          
          // Verificar se já existem categorias para o usuário
          final existingCategories = await repository.getAllCategories();
          
          if (existingCategories.isEmpty) {
            print('🏷️ Inicializando categorias padrão para novo usuário...');
            // As categorias padrão serão criadas automaticamente pelo repository
            await repository.getAllCategories();
            print('✅ Categorias padrão inicializadas com sucesso');
          } else {
            print('✅ Usuário já possui categorias (${existingCategories.length})');
          }
        } else {
          print('⚠️ Serviços de despesas não estão registrados ainda');
        }
      } catch (e) {
        print('⚠️ Erro ao inicializar categorias padrão: $e');
      }
    });
  }
}
