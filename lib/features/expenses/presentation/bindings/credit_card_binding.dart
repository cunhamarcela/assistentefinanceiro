import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../data/datasources/credit_card_firestore_datasource.dart';
import '../../data/datasources/credit_card_local_datasource.dart';
import '../../data/repositories/credit_card_repository_impl.dart';
import '../../domain/usecases/add_credit_card_usecase.dart';
import '../../domain/usecases/delete_credit_card_usecase.dart';
import '../../domain/usecases/get_credit_cards_usecase.dart';
import '../../domain/usecases/update_credit_card_usecase.dart';
import '../controllers/credit_card_controller.dart';

/// Binding para injeção de dependências de cartões de crédito
class CreditCardBinding extends Bindings {
  @override
  void dependencies() {
    // DataSources
    Get.lazyPut(() => CreditCardLocalDataSource());
    
    Get.lazyPut(() => CreditCardFirestoreDataSource(
      FirebaseFirestore.instance,
      FirebaseAuth.instance.currentUser!.uid,
    ));

    // Repository
    Get.lazyPut(() => CreditCardRepositoryImpl(
      Get.find<CreditCardLocalDataSource>(),
      Get.find<CreditCardFirestoreDataSource>(),
    ));

    // Use Cases
    Get.lazyPut(() => AddCreditCardUseCase(Get.find<CreditCardRepositoryImpl>()));
    Get.lazyPut(() => GetCreditCardsUseCase(Get.find<CreditCardRepositoryImpl>()));
    Get.lazyPut(() => UpdateCreditCardUseCase(Get.find<CreditCardRepositoryImpl>()));
    Get.lazyPut(() => DeleteCreditCardUseCase(Get.find<CreditCardRepositoryImpl>()));

    // Controller
    Get.lazyPut(() => CreditCardController(
      Get.find<AddCreditCardUseCase>(),
      Get.find<GetCreditCardsUseCase>(),
      Get.find<UpdateCreditCardUseCase>(),
      Get.find<DeleteCreditCardUseCase>(),
    ));
  }
}

