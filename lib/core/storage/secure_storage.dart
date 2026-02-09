import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../../features/auth/data/models/user_model.dart';

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
        accountName: 'assistente_financeiro_keychain',
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
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

  /// Salvar token de refresh
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: _encryptData(token));
  }

  /// Obter token de refresh
  Future<String?> getRefreshToken() async {
    final encryptedToken = await _storage.read(key: _keyRefreshToken);
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

  /// Salvar ID da sessão
  Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: _keySessionId, value: sessionId);
  }

  /// Obter ID da sessão
  Future<String?> getSessionId() async {
    return await _storage.read(key: _keySessionId);
  }

  /// Salvar último email usado
  Future<void> saveLastEmail(String email) async {
    await _storage.write(key: _keyLastEmail, value: email);
  }

  /// Obter último email usado
  Future<String?> getLastEmail() async {
    return await _storage.read(key: _keyLastEmail);
  }

  /// Configurar "Lembrar de mim"
  Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: _keyRememberMe, value: remember.toString());
  }

  /// Verificar se "Lembrar de mim" está ativo
  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _keyRememberMe);
    return value == 'true';
  }

  /// Configurar biometria
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  /// Verificar se biometria está habilitada
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Verificar se há dados de sessão válidos
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final userData = await getUserData();
    return token != null && userData != null && userData.isNotEmpty;
  }

  /// Limpar todos os dados de autenticação
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken).catchError((_) => null),
        _storage.delete(key: _keyRefreshToken).catchError((_) => null),
        _storage.delete(key: _keyUserData).catchError((_) => null),
        _storage.delete(key: _keySessionId).catchError((_) => null),
      ]);
    } catch (e) {
      print('Erro ao limpar dados de autenticação: $e');
      // Continuar mesmo com erro, pois pode ser problema de keychain
    }
  }

  /// Limpar apenas tokens (manter dados do usuário)
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keySessionId),
    ]);
  }

  /// Limpar todos os dados
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Obter todas as chaves armazenadas (para debug)
  Future<Map<String, String>> getAllData() async {
    return await _storage.readAll();
  }

  /// Verificar se o storage contém uma chave específica
  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  /// Método genérico para escrever dados
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      print('Erro ao escrever no SecureStorage: $e');
      // Para desenvolvimento, vamos ignorar erros de keychain
      // Em produção, você pode querer usar SharedPreferences como fallback
    }
  }

  /// Método genérico para ler dados
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('Erro ao ler do SecureStorage: $e');
      // Para desenvolvimento, retornar null em caso de erro
      return null;
    }
  }

  /// Método genérico para deletar dados
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('Erro ao deletar do SecureStorage: $e');
    }
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

  /// Verificar se o dispositivo suporta biometria
  Future<bool> isBiometricAvailable() async {
    try {
      // Funcionalidade de biometria será implementada futuramente
      // Por enquanto, retorna false
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Salvar dados com biometria
  Future<void> saveWithBiometric(String key, String value) async {
    // Por enquanto, usar storage normal
    await _storage.write(key: key, value: value);
  }

  /// Ler dados com biometria
  Future<String?> readWithBiometric(String key) async {
    try {
      // Por enquanto, usar storage normal
      return await _storage.read(key: key);
    } catch (e) {
      print('Erro na autenticação biométrica: $e');
      return null;
    }
  }
}
