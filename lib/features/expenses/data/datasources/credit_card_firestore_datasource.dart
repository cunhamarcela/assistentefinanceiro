import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/credit_card_model.dart';

/// Datasource remoto para cartões de crédito (Firestore)
class CreditCardFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final String userId;
  
  /// Timeout padrão para operações do Firestore
  static const Duration _timeout = Duration(seconds: 3);

  CreditCardFirestoreDataSource(this._firestore, this.userId);

  /// Referência à coleção de cartões do usuário
  CollectionReference get _cardsCollection =>
      _firestore.collection('users').doc(userId).collection('credit_cards');

  /// Adiciona um novo cartão
  Future<void> addCard(CreditCardModel card) async {
    try {
      await _cardsCollection.doc(card.id).set(card.toFirestore())
          .timeout(_timeout, onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao salvar cartão no Firestore - será sincronizado depois');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao salvar cartão no Firestore: $e');
      }
      // Não propaga - dados serão sincronizados depois
    }
  }

  /// Obtém todos os cartões
  Future<List<CreditCardModel>> getAllCards() async {
    try {
      final snapshot = await _cardsCollection
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Firestore timeout');
      });

      return snapshot.docs
          .map((doc) => CreditCardModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Timeout/erro ao buscar cartões do Firestore: $e');
      }
      return []; // Retorna vazio para usar fallback local
    }
  }

  /// Obtém apenas cartões ativos
  Future<List<CreditCardModel>> getActiveCards() async {
    try {
      final snapshot = await _cardsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get()
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Firestore timeout');
      });

      return snapshot.docs
          .map((doc) => CreditCardModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Timeout/erro ao buscar cartões ativos do Firestore: $e');
      }
      return []; // Retorna vazio para usar fallback local
    }
  }

  /// Obtém um cartão por ID
  Future<CreditCardModel?> getCardById(String id) async {
    try {
      final doc = await _cardsCollection.doc(id).get()
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Firestore timeout');
      });
      
      if (!doc.exists) return null;
      return CreditCardModel.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Timeout/erro ao buscar cartão do Firestore: $e');
      }
      return null; // Retorna null para usar fallback local
    }
  }

  /// Atualiza um cartão
  Future<void> updateCard(CreditCardModel card) async {
    try {
      await _cardsCollection.doc(card.id).update(card.toFirestore())
          .timeout(_timeout, onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao atualizar cartão no Firestore');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao atualizar cartão no Firestore: $e');
      }
    }
  }

  /// Deleta um cartão (soft delete)
  Future<void> deleteCard(String id) async {
    try {
      await _cardsCollection.doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout, onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao deletar cartão no Firestore');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao deletar cartão no Firestore: $e');
      }
    }
  }

  /// Deleta permanentemente um cartão
  Future<void> permanentlyDeleteCard(String id) async {
    try {
      await _cardsCollection.doc(id).delete()
          .timeout(_timeout, onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Timeout ao deletar permanentemente cartão no Firestore');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao deletar permanentemente cartão no Firestore: $e');
      }
    }
  }

  /// Stream de cartões ativos
  Stream<List<CreditCardModel>> watchActiveCards() {
    return _cardsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditCardModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream de todos os cartões
  Stream<List<CreditCardModel>> watchAllCards() {
    return _cardsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditCardModel.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }
}

