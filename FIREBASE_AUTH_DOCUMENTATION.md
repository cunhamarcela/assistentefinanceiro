# 🔐 Documentação Completa - Serviço de Autenticação Firebase

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Configuração Inicial](#configuração-inicial)
4. [Estrutura de Arquivos](#estrutura-de-arquivos)
5. [Implementação Detalhada](#implementação-detalhada)
6. [Modelos de Dados](#modelos-de-dados)
7. [Serviços](#serviços)
8. [Controllers e UI](#controllers-e-ui)
9. [Storage Seguro](#storage-seguro)
10. [Integração com Firestore](#integração-com-firestore)
11. [Fluxos de Autenticação](#fluxos-de-autenticação)
12. [Tratamento de Erros](#tratamento-de-erros)
13. [Como Usar em Outros Projetos](#como-usar-em-outros-projetos)

---

## 🎯 Visão Geral

Este sistema de autenticação foi desenvolvido seguindo os princípios da **Clean Architecture** com **GetX** para gerenciamento de estado. Oferece autenticação completa com Firebase, incluindo:

### ✅ **Funcionalidades Implementadas:**

- **Autenticação por Email/Senha** - Registro e login tradicional
- **Autenticação Social** - Google Sign-In e Apple Sign-In
- **Recuperação de Senha** - Reset via email
- **Verificação de Email** - Confirmação de conta
- **Persistência Segura** - Storage criptografado local
- **Sincronização Firestore** - Dados do usuário no banco
- **Gerenciamento de Sessão** - Tokens e estado de autenticação
- **Tratamento de Erros** - Mensagens personalizadas em português

### 🏗️ **Tecnologias Utilizadas:**

- **Firebase Auth** - Autenticação principal
- **Cloud Firestore** - Banco de dados NoSQL
- **Flutter Secure Storage** - Armazenamento seguro local
- **GetX** - Gerenciamento de estado e injeção de dependência
- **Google Sign-In** - Autenticação social Google
- **Sign in with Apple** - Autenticação social Apple

---

## 🏛️ Arquitetura do Sistema

### **Clean Architecture + GetX**

```
lib/features/auth/
├── data/
│   ├── models/          # Modelos de dados
│   └── services/        # Serviços de dados
├── presentation/
│   ├── controllers/     # Controllers GetX
│   ├── pages/          # Telas da UI
│   └── bindings/       # Injeção de dependências
```

### **Fluxo de Dados:**

```
UI (Pages) → Controllers → Services → Firebase/Firestore
     ↓           ↓           ↓            ↓
  Bindings → SecureStorage → UserModel → Database
```

---

## ⚙️ Configuração Inicial

### **1. Dependências (pubspec.yaml)**

```yaml
dependencies:
  # State Management
  get: ^4.6.6
  
  # Firebase & Auth
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^6.1.2
  
  # Storage & Security
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.3
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.9.0

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### **2. Configuração Firebase**

#### **Android (android/app/google-services.json)**
```json
{
  "project_info": {
    "project_number": "SEU_PROJECT_NUMBER",
    "project_id": "SEU_PROJECT_ID"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "SEU_APP_ID",
        "android_client_info": {
          "package_name": "com.seuapp.nome"
        }
      }
    }
  ]
}
```

#### **iOS (ios/Runner/GoogleService-Info.plist)**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>SEU_CLIENT_ID</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>SEU_REVERSED_CLIENT_ID</string>
    <!-- ... outros campos ... -->
</dict>
</plist>
```

### **3. Inicialização no main.dart**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar serviços
  await _initializeServices();
  
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  // SecureStorage
  final secureStorage = await SecureStorage.instance.init();
  Get.put<SecureStorage>(secureStorage, permanent: true);
  
  // FirestoreUserService
  final firestoreUserService = FirestoreUserService();
  Get.put<FirestoreUserService>(firestoreUserService, permanent: true);
  
  // AuthService
  final authService = AuthService();
  await authService.onInit();
  Get.put<AuthService>(authService, permanent: true);
}
```

---

## 📁 Estrutura de Arquivos

```
lib/features/auth/
├── data/
│   ├── models/
│   │   ├── user_model.dart           # Modelo do usuário
│   │   └── user_model.g.dart         # Gerado pelo json_serializable
│   └── services/
│       ├── auth_service.dart         # Serviço principal de autenticação
│       └── firestore_user_service.dart # Serviço do Firestore
├── presentation/
│   ├── bindings/
│   │   └── auth_binding.dart         # Injeção de dependências
│   ├── controllers/
│   │   └── auth_controller.dart      # Controller da UI
│   └── pages/
│       ├── login_page.dart           # Tela de login
│       ├── register_page.dart        # Tela de registro
│       ├── forgot_password_page.dart # Tela de recuperação
│       └── email_verification_page.dart # Tela de verificação
```

---

## 🔧 Implementação Detalhada

### **1. AuthService - Serviço Principal**

```dart
class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SecureStorage _secureStorage = SecureStorage.instance;
  late final FirestoreUserService _firestoreUserService;

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
    _firestoreUserService = Get.find<FirestoreUserService>();
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
        await _firestoreUserService.saveUserToFirestore(userModel);
        await _firestoreUserService.updateLastLogin(userModel.id);
      } catch (e) {
        print('Erro ao salvar no Firestore: $e');
      }
      
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

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      
      if (userCredential.user == null) {
        throw const AuthException('Falha na autenticação com Apple');
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
      final message = 'Erro inesperado durante login com Apple';
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

      // Atualizar perfil do usuário
      await credential.user!.updateDisplayName(name.trim());
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

  /// Logout
  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        _secureStorage.clearAuthData(),
      ]);
      
      _currentUser.value = null;
      _lastError.value = '';
    } catch (e) {
      _handleError('Erro durante logout', e);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Enviar email de recuperação de senha
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

  /// Enviar verificação de email
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw const AuthException('Erro ao enviar email de verificação');
    }
  }

  /// Recarregar dados do usuário
  Future<void> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _firebaseAuth.currentUser;
        if (updatedUser != null) {
          final userModel = UserModel.fromFirebaseUser(updatedUser);
          _currentUser.value = userModel;
          await _secureStorage.saveUserData(userModel);
        }
      }
    } catch (e) {
      throw const AuthException('Erro ao recarregar dados do usuário');
    }
  }

  // ==================== VALIDADORES ====================

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

  void _handleError(String context, dynamic error) {
    print('$context: $error');
    if (error is FirebaseAuthException) {
      _lastError.value = _getFirebaseErrorMessage(error.code);
    } else {
      _lastError.value = 'Erro inesperado';
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Este email já está em uso';
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
      case 'credential-already-in-use':
        return 'Credencial já está em uso';
      case 'invalid-verification-code':
        return 'Código de verificação inválido';
      case 'invalid-verification-id':
        return 'ID de verificação inválido';
      default:
        return 'Erro de autenticação: $code';
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
}

/// Exceção personalizada para autenticação
class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => 'AuthException: $message';
}
```

---

## 📊 Modelos de Dados

### **UserModel - Modelo Principal do Usuário**

```dart
@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? lastLogin;
  final bool emailVerified;
  final String? phoneNumber;
  final Map<String, dynamic>? customClaims;
  @JsonKey(fromJson: _dateTimeFromJsonNullable, toJson: _dateTimeToJsonNullable)
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.lastLogin,
    required this.emailVerified,
    this.phoneNumber,
    this.customClaims,
    this.updatedAt,
  });

  /// Factory constructor para criar UserModel a partir de Firebase User
  factory UserModel.fromFirebaseUser(User user, {Map<String, dynamic>? customClaims}) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Usuário',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLogin: user.metadata.lastSignInTime,
      emailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber,
      customClaims: customClaims,
      updatedAt: DateTime.now(),
    );
  }

  /// Factory constructor para criar UserModel vazio
  factory UserModel.empty() {
    return UserModel(
      id: '',
      name: '',
      email: '',
      createdAt: DateTime.now(),
      emailVerified: false,
    );
  }

  /// Factory constructor para JSON
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// Converter para JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Verificar se o usuário está vazio
  bool get isEmpty => id.isEmpty;

  /// Verificar se o usuário não está vazio
  bool get isNotEmpty => !isEmpty;

  /// Obter iniciais do nome
  String get initials {
    if (name.isEmpty) return 'U';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  /// Obter nome de exibição
  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Usuário';
  }

  /// Verificar se é administrador
  bool get isAdmin {
    return customClaims?['admin'] == true;
  }

  /// Verificar se tem role específico
  bool hasRole(String role) {
    final roles = customClaims?['roles'] as List<dynamic>?;
    return roles?.contains(role) ?? false;
  }

  /// Copiar com novos valores
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? emailVerified,
    String? phoneNumber,
    Map<String, dynamic>? customClaims,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      customClaims: customClaims ?? this.customClaims,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        photoUrl,
        createdAt,
        lastLogin,
        emailVerified,
        phoneNumber,
        customClaims,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, emailVerified: $emailVerified)';
  }
}

// Helper functions para serialização de DateTime
DateTime _dateTimeFromJson(int timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp);
int _dateTimeToJson(DateTime dateTime) => dateTime.millisecondsSinceEpoch;

DateTime? _dateTimeFromJsonNullable(int? timestamp) =>
    timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
int? _dateTimeToJsonNullable(DateTime? dateTime) => dateTime?.millisecondsSinceEpoch;
```

---

## 🗄️ Storage Seguro

### **SecureStorage - Armazenamento Criptografado**

```dart
class SecureStorage {
  static SecureStorage? _instance;
  static SecureStorage get instance => _instance ??= SecureStorage._();
  
  SecureStorage._();

  late FlutterSecureStorage _storage;

  // Chaves para armazenamento
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLastEmail = 'last_email';
  static const String _keySessionId = 'session_id';

  /// Inicializar o storage
  Future<SecureStorage> init() async {
    _storage = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
    return this;
  }

  /// Configurações específicas do Android
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'assistente_financeiro_secure_prefs',
        preferencesKeyPrefix: 'af_',
      );

  /// Configurações específicas do iOS
  IOSOptions _getIOSOptions() => const IOSOptions(
        groupId: 'group.com.assistentefinanceiro.app',
        accountName: 'assistente_financeiro_keychain',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );

  /// Salvar token de acesso
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: _encryptData(token));
  }

  /// Obter token de acesso
  Future<String?> getAccessToken() async {
    final encryptedToken = await _storage.read(key: _keyAccessToken);
    return encryptedToken != null ? _decryptData(encryptedToken) : null;
  }

  /// Salvar dados do usuário
  Future<void> saveUserData(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _keyUserData, value: _encryptData(userJson));
  }

  /// Obter dados do usuário
  Future<UserModel?> getUserData() async {
    try {
      final encryptedData = await _storage.read(key: _keyUserData);
      if (encryptedData == null) return null;
      
      final userJson = _decryptData(encryptedData);
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      print('Erro ao recuperar dados do usuário: $e');
      return null;
    }
  }

  /// Limpar todos os dados de autenticação
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserData),
      _storage.delete(key: _keySessionId),
    ]);
  }

  /// Verificar se há dados de sessão válidos
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final userData = await getUserData();
    return token != null && userData != null && userData.isNotEmpty;
  }

  /// Criptografar dados (criptografia simples)
  String _encryptData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    final key = digest.toString().substring(0, 32);
    
    // Criptografia simples XOR (para dados não críticos)
    final encrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ key.codeUnitAt(i % key.length));
    }
    
    return base64Encode(encrypted);
  }

  /// Descriptografar dados
  String _decryptData(String encryptedData) {
    try {
      final encrypted = base64Decode(encryptedData);
      final tempBytes = utf8.encode('temp_data_for_key');
      final digest = sha256.convert(tempBytes);
      final key = digest.toString().substring(0, 32);
      
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ key.codeUnitAt(i % key.length));
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      print('Erro ao descriptografar dados: $e');
      return '';
    }
  }
}
```

---

## 🔥 Integração com Firestore

### **FirestoreUserService - Gerenciamento de Dados no Banco**

```dart
class FirestoreUserService extends GetxService {
  static FirestoreUserService get instance => Get.find<FirestoreUserService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Salvar dados do usuário no Firestore
  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
      
      print('✅ Dados do usuário salvos no Firestore: ${user.email}');
    } catch (e) {
      print('❌ Erro ao salvar usuário no Firestore: $e');
      throw Exception('Erro ao salvar dados do usuário: $e');
    }
  }

  /// Obter dados do usuário do Firestore
  Future<UserModel?> getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar usuário no Firestore: $e');
      return null;
    }
  }

  /// Atualizar dados do usuário no Firestore
  Future<void> updateUserInFirestore(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Dados do usuário atualizados no Firestore');
    } catch (e) {
      print('❌ Erro ao atualizar usuário no Firestore: $e');
      throw Exception('Erro ao atualizar dados do usuário: $e');
    }
  }

  /// Atualizar último login
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('❌ Erro ao atualizar último login: $e');
    }
  }

  /// Stream para escutar mudanças nos dados do usuário
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserModel.fromJson(doc.data()!);
          }
          return null;
        });
  }

  /// Verificar se usuário existe no Firestore
  Future<bool> userExistsInFirestore(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('❌ Erro ao verificar existência do usuário: $e');
      return false;
    }
  }

  /// Deletar usuário do Firestore
  Future<void> deleteUserFromFirestore(String userId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();
      
      print('✅ Usuário removido do Firestore');
    } catch (e) {
      print('❌ Erro ao deletar usuário do Firestore: $e');
      throw Exception('Erro ao deletar dados do usuário: $e');
    }
  }

  /// Buscar usuários por email (para admin)
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThanOrEqualTo: '$email\uf8ff')
          .limit(10)
          .get();

      return query.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar usuários: $e');
      return [];
    }
  }

  /// Obter estatísticas de usuários (para admin)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .get();

      final totalUsers = query.docs.length;
      final verifiedUsers = query.docs
          .where((doc) => doc.data()['emailVerified'] == true)
          .length;

      return {
        'totalUsers': totalUsers,
        'verifiedUsers': verifiedUsers,
        'unverifiedUsers': totalUsers - verifiedUsers,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas: $e');
      return {};
    }
  }
}
```

### **Estrutura de Dados no Firestore:**

```json
// Coleção: users
{
  "id": "firebase_user_uid",
  "name": "Nome do Usuário",
  "email": "usuario@email.com",
  "photoUrl": "https://...",
  "createdAt": "timestamp",
  "lastLogin": "timestamp",
  "updatedAt": "timestamp",
  "emailVerified": true,
  "phoneNumber": "+55...",
  "customClaims": {
    "admin": false,
    "roles": ["user"]
  }
}
```

---

## 🎮 Controllers e UI

### **AuthController - Controller da Interface**

```dart
class AuthController extends GetxController {
  late final AuthService _authService;

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxBool rememberMe = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Getters
  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isEmailVerified => _authService.isEmailVerified;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _loadLastEmail();
    
    // Escutar mudanças no estado de autenticação
    _authService.authStateChanges.listen((user) {
      if (user != null && user.isNotEmpty) {
        // Usuário autenticado, redirecionar para home
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.currentRoute == AppRoutes.login || 
              Get.currentRoute == AppRoutes.register) {
            Get.offAllNamed(AppRoutes.home);
          }
        });
      }
    });
  }

  /// Login com email e senha
  Future<void> loginWithEmail() async {
    try {
      if (!loginFormKey.currentState!.validate()) return;

      clearMessages();
      
      await _authService.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (rememberMe.value) {
        final secureStorage = Get.find<SecureStorage>();
        await secureStorage.setRememberMe(true);
      }

      successMessage.value = 'Login realizado com sucesso!';
      
      // Navegar para home após delay para mostrar mensagem
      await Future.delayed(const Duration(milliseconds: 500));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante o login';
    }
  }

  /// Login com Google
  Future<void> loginWithGoogle() async {
    try {
      clearMessages();
      
      await _authService.signInWithGoogle();
      
      successMessage.value = 'Login com Google realizado com sucesso!';
      
      // Forçar redirecionamento após sucesso
      await Future.delayed(const Duration(milliseconds: 300));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante login com Google';
    }
  }

  /// Login com Apple
  Future<void> loginWithApple() async {
    try {
      clearMessages();
      
      await _authService.signInWithApple();
      
      successMessage.value = 'Login com Apple realizado com sucesso!';
      
      // Forçar redirecionamento após sucesso
      await Future.delayed(const Duration(milliseconds: 300));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante login com Apple';
    }
  }

  /// Registro com email e senha
  Future<void> registerWithEmail() async {
    try {
      if (!registerFormKey.currentState!.validate()) return;

      clearMessages();
      
      await _authService.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
      );

      successMessage.value = 'Conta criada com sucesso! Verifique seu email.';
      
      // Navegar para home após delay
      await Future.delayed(const Duration(milliseconds: 1500));
      _handleSuccessfulLogin();
      
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Erro inesperado durante o registro';
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      clearMessages();
      
      await _authService.signOut();
      
      // Limpar formulários
      clearForms();
      
      // Navegar para login
      Get.offAllNamed(AppRoutes.login);
      
    } catch (e) {
      errorMessage.value = 'Erro durante logout';
    }
  }

  // ==================== VALIDADORES ====================

  /// Validador de email
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

  /// Validador de senha
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    
    if (value.length > 128) {
      return 'Senha muito longa (máximo 128 caracteres)';
    }
    
    return null;
  }

  /// Validador de confirmação de senha
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    
    if (value != passwordController.text) {
      return 'Senhas não coincidem';
    }
    
    return null;
  }

  /// Validador de nome
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    
    if (value.length > 100) {
      return 'Nome muito longo (máximo 100 caracteres)';
    }
    
    return null;
  }

  // ==================== HELPERS ====================

  /// Lidar com login bem-sucedido
  void _handleSuccessfulLogin() {
    if (_authService.isAuthenticated) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Limpar mensagens
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  /// Limpar formulários
  void clearForms() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmPasswordController.clear();
    clearMessages();
  }

  /// Carregar último email usado
  Future<void> _loadLastEmail() async {
    try {
      final secureStorage = Get.find<SecureStorage>();
      final lastEmail = await secureStorage.getLastEmail();
      if (lastEmail != null) {
        emailController.text = lastEmail;
      }
      
      final remember = await secureStorage.getRememberMe();
      rememberMe.value = remember;
    } catch (e) {
      print('Erro ao carregar último email: $e');
    }
  }
}
```

### **AuthBinding - Injeção de Dependências**

```dart
/// Binding para injeção de dependências de autenticação
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Registrar AuthController
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true, // Permite recriar se necessário
    );
  }
}

/// Binding inicial da aplicação
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Todos os serviços já foram inicializados no main.dart
    // Só precisamos registrar o AuthController
    
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}
```

---

## 🔄 Fluxos de Autenticação

### **1. Fluxo de Login com Email/Senha:**

```
1. Usuário insere email/senha → AuthController.loginWithEmail()
2. Controller valida dados → AuthService.signInWithEmailAndPassword()
3. AuthService chama Firebase Auth → Firebase retorna User
4. AuthService cria UserModel → Salva no SecureStorage
5. FirestoreUserService salva no banco → Atualiza lastLogin
6. AuthService atualiza estado → Controller redireciona para Home
```

### **2. Fluxo de Login Social (Google/Apple):**

```
1. Usuário clica botão social → AuthController.loginWithGoogle/Apple()
2. Controller chama AuthService → AuthService abre popup social
3. Usuário autentica na plataforma → Retorna credenciais
4. AuthService usa credenciais no Firebase → Firebase retorna User
5. Resto do fluxo igual ao login email/senha
```

### **3. Fluxo de Registro:**

```
1. Usuário preenche formulário → AuthController.registerWithEmail()
2. Controller valida dados → AuthService.createUserWithEmailAndPassword()
3. AuthService cria conta no Firebase → Atualiza displayName
4. Firebase envia email verificação → AuthService salva dados
5. Resto do fluxo igual ao login
```

### **4. Fluxo de Logout:**

```
1. Usuário clica logout → AuthController.logout()
2. Controller chama AuthService → AuthService.signOut()
3. AuthService limpa Firebase Auth → Limpa Google Sign-In
4. SecureStorage limpa dados locais → AuthService atualiza estado
5. Controller redireciona para Login
```

### **5. Fluxo de Inicialização:**

```
1. App inicia → main.dart inicializa serviços
2. AuthService.onInit() → Escuta authStateChanges
3. AuthService carrega usuário salvo → Verifica se ainda válido
4. Se válido: atualiza estado → Se inválido: limpa dados
5. App redireciona conforme estado
```

---

## ⚠️ Tratamento de Erros

### **Exceções Personalizadas:**

```dart
/// Exceção personalizada para autenticação
class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => 'AuthException: $message';
}
```

### **Mapeamento de Erros Firebase:**

```dart
String _getFirebaseErrorMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Usuário não encontrado';
    case 'wrong-password':
      return 'Senha incorreta';
    case 'email-already-in-use':
      return 'Este email já está em uso';
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
    case 'credential-already-in-use':
      return 'Credencial já está em uso';
    case 'invalid-verification-code':
      return 'Código de verificação inválido';
    case 'invalid-verification-id':
      return 'ID de verificação inválido';
    default:
      return 'Erro de autenticação: $code';
  }
}
```

### **Tratamento na UI:**

```dart
// No Controller
try {
  await _authService.signInWithEmailAndPassword(
    email: emailController.text,
    password: passwordController.text,
  );
  successMessage.value = 'Login realizado com sucesso!';
} on AuthException catch (e) {
  errorMessage.value = e.message; // Mensagem já traduzida
} catch (e) {
  errorMessage.value = 'Erro inesperado durante o login';
}

// Na UI
Obx(() {
  if (controller.errorMessage.isNotEmpty) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
  return SizedBox.shrink();
})
```

---

## 🚀 Como Usar em Outros Projetos

### **1. Copiar Estrutura de Arquivos:**

```bash
# Copie toda a pasta auth para seu projeto
cp -r lib/features/auth/ /seu_projeto/lib/features/

# Copie os arquivos de storage
cp -r lib/core/storage/ /seu_projeto/lib/core/

# Copie configurações do Firebase
cp firebase_options.dart /seu_projeto/
cp android/app/google-services.json /seu_projeto/android/app/
cp ios/Runner/GoogleService-Info.plist /seu_projeto/ios/Runner/
```

### **2. Instalar Dependências:**

```yaml
# Adicione ao pubspec.yaml
dependencies:
  get: ^4.6.6
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^6.1.2
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.3
  equatable: ^2.0.5
  json_annotation: ^4.9.0

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### **3. Configurar Firebase:**

```bash
# Instale Firebase CLI
npm install -g firebase-tools

# Faça login no Firebase
firebase login

# Configure o projeto
firebase init

# Gere arquivos de configuração
flutterfire configure
```

### **4. Inicializar no main.dart:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar serviços
  await _initializeServices();
  
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  // SecureStorage
  final secureStorage = await SecureStorage.instance.init();
  Get.put<SecureStorage>(secureStorage, permanent: true);
  
  // FirestoreUserService
  final firestoreUserService = FirestoreUserService();
  Get.put<FirestoreUserService>(firestoreUserService, permanent: true);
  
  // AuthService
  final authService = AuthService();
  await authService.onInit();
  Get.put<AuthService>(authService, permanent: true);
}
```

### **5. Configurar Rotas:**

```dart
// app_routes.dart
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
}

// app_pages.dart
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.emailVerification,
      page: () => const EmailVerificationPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
```

### **6. Usar nos Controllers:**

```dart
class HomeController extends GetxController {
  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
  }

  // Verificar se usuário está autenticado
  bool get isAuthenticated => _authService.isAuthenticated;
  
  // Obter dados do usuário atual
  UserModel? get currentUser => _authService.currentUser;
  
  // Fazer logout
  Future<void> logout() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
```

### **7. Middleware de Autenticação:**

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    
    // Se não está autenticado e não está indo para telas de auth
    if (!authService.isAuthenticated && 
        route != AppRoutes.login && 
        route != AppRoutes.register && 
        route != AppRoutes.forgotPassword) {
      return const RouteSettings(name: AppRoutes.login);
    }
    
    // Se está autenticado e está indo para telas de auth
    if (authService.isAuthenticated && 
        (route == AppRoutes.login || route == AppRoutes.register)) {
      return const RouteSettings(name: AppRoutes.home);
    }
    
    return null;
  }
}

// Usar nas rotas
GetPage(
  name: AppRoutes.home,
  page: () => const HomePage(),
  middlewares: [AuthMiddleware()],
),
```

### **8. Personalizar Mensagens:**

```dart
// Edite o método _getFirebaseErrorMessage no AuthService
String _getFirebaseErrorMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Usuário não encontrado'; // Personalize aqui
    case 'wrong-password':
      return 'Senha incorreta'; // Personalize aqui
    // ... outros casos
    default:
      return 'Erro de autenticação: $code';
  }
}
```

### **9. Configurações Adicionais:**

#### **Android (android/app/build.gradle):**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.gms:play-services-auth'
}
```

#### **iOS (ios/Runner/Info.plist):**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>SEU_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

---

## 📝 Resumo das Funcionalidades

### ✅ **Implementado:**
- ✅ Autenticação Email/Senha
- ✅ Autenticação Google
- ✅ Autenticação Apple
- ✅ Registro de usuários
- ✅ Recuperação de senha
- ✅ Verificação de email
- ✅ Storage seguro local
- ✅ Sincronização Firestore
- ✅ Gerenciamento de estado GetX
- ✅ Tratamento de erros
- ✅ Validações de formulário
- ✅ Middleware de autenticação
- ✅ Persistência de sessão

### 🔄 **Fluxos Completos:**
- 🔄 Login → Validação → Firebase → Storage → Firestore → Home
- 🔄 Registro → Validação → Firebase → Email → Storage → Home
- 🔄 Social → Popup → Credenciais → Firebase → Storage → Home
- 🔄 Logout → Firebase → Storage → Login
- 🔄 Recuperação → Email → Firebase → Confirmação

### 🛡️ **Segurança:**
- 🛡️ Criptografia local
- 🛡️ Tokens seguros
- 🛡️ Validações robustas
- 🛡️ Tratamento de erros
- 🛡️ Limpeza de dados

---

## 🎯 Conclusão

Este sistema de autenticação oferece uma solução completa e robusta para aplicações Flutter, seguindo as melhores práticas de segurança e arquitetura. Com Firebase como backend e GetX para gerenciamento de estado, proporciona uma experiência fluida tanto para desenvolvedores quanto para usuários finais.

A documentação fornece todos os detalhes necessários para implementar o sistema em novos projetos, incluindo configurações, códigos e fluxos completos.

**Desenvolvido com ❤️ usando Clean Architecture + GetX + Firebase**


