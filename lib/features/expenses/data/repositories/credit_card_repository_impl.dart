import '../../domain/entities/credit_card.dart';
import '../../domain/repositories/credit_card_repository.dart';
import '../datasources/credit_card_firestore_datasource.dart';
import '../datasources/credit_card_local_datasource.dart';
import '../models/credit_card_model.dart';

/// Implementação do repository de cartões com armazenamento híbrido
class CreditCardRepositoryImpl implements CreditCardRepository {
  final CreditCardLocalDataSource _localDataSource;
  final CreditCardFirestoreDataSource _remoteDataSource;

  CreditCardRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<void> addCard(CreditCard card) async {
    print('💳 [Repository] Convertendo cartão para model...');
    final model = CreditCardModel.fromEntity(card);

    print('💳 [Repository] Salvando localmente (SQLite)...');
    // Salva localmente
    await _localDataSource.addCard(model);
    print('💳 [Repository] ✅ Salvo localmente!');

    // Tenta salvar remotamente
    try {
      print('💳 [Repository] Salvando remotamente (Firestore)...');
      await _remoteDataSource.addCard(model);
      print('💳 [Repository] ✅ Salvo remotamente!');
    } catch (e) {
      print('❌ [Repository] Erro ao salvar cartão no Firestore: $e');
      // Continua mesmo com erro no remoto (offline-first)
    }
  }

  @override
  Future<List<CreditCard>> getAllCards() async {
    try {
      // Tenta buscar do Firestore primeiro
      final remoteCards = await _remoteDataSource.getAllCards();
      
      // Atualiza o cache local
      for (final card in remoteCards) {
        await _localDataSource.addCard(card);
      }
      
      return remoteCards.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Erro ao buscar cartões do Firestore: $e');
      // Fallback para dados locais
      final localCards = await _localDataSource.getAllCards();
      return localCards.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<List<CreditCard>> getActiveCards() async {
    try {
      // Tenta buscar do Firestore primeiro
      final remoteCards = await _remoteDataSource.getActiveCards();
      
      // Atualiza o cache local
      for (final card in remoteCards) {
        await _localDataSource.addCard(card);
      }
      
      return remoteCards.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Erro ao buscar cartões ativos do Firestore: $e');
      // Fallback para dados locais
      final localCards = await _localDataSource.getActiveCards();
      return localCards.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<CreditCard?> getCardById(String id) async {
    try {
      // Tenta buscar do Firestore primeiro
      final remoteCard = await _remoteDataSource.getCardById(id);
      
      if (remoteCard != null) {
        // Atualiza o cache local
        await _localDataSource.addCard(remoteCard);
        return remoteCard.toEntity();
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar cartão do Firestore: $e');
      // Fallback para dados locais
      final localCard = await _localDataSource.getCardById(id);
      return localCard?.toEntity();
    }
  }

  @override
  Future<void> updateCard(CreditCard card) async {
    final model = CreditCardModel.fromEntity(card);

    // Atualiza localmente
    await _localDataSource.updateCard(model);

    // Tenta atualizar remotamente
    try {
      await _remoteDataSource.updateCard(model);
    } catch (e) {
      print('Erro ao atualizar cartão no Firestore: $e');
      // Continua mesmo com erro no remoto (offline-first)
    }
  }

  @override
  Future<void> deleteCard(String id) async {
    // Deleta localmente
    await _localDataSource.deleteCard(id);

    // Tenta deletar remotamente
    try {
      await _remoteDataSource.deleteCard(id);
    } catch (e) {
      print('Erro ao deletar cartão no Firestore: $e');
      // Continua mesmo com erro no remoto (offline-first)
    }
  }

  @override
  Future<void> permanentlyDeleteCard(String id) async {
    // Deleta permanentemente localmente
    await _localDataSource.permanentlyDeleteCard(id);

    // Tenta deletar permanentemente remotamente
    try {
      await _remoteDataSource.permanentlyDeleteCard(id);
    } catch (e) {
      print('Erro ao deletar permanentemente cartão no Firestore: $e');
      // Continua mesmo com erro no remoto (offline-first)
    }
  }

  @override
  Stream<List<CreditCard>> watchActiveCards() {
    return _remoteDataSource.watchActiveCards().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Stream<List<CreditCard>> watchAllCards() {
    return _remoteDataSource.watchAllCards().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }
}

