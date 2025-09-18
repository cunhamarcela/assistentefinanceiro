import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

/// Serviço para gerenciar dados do usuário no Firestore
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


