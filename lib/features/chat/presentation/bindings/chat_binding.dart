import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../../domain/usecases/generate_assistant_reply_usecase.dart';
import '../../domain/usecases/manage_conversation_usecase.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/datasources/chat_ia_remote_datasource.dart';
import '../../data/datasources/chat_ia_cache_datasource.dart';
import '../../../../core/services/analytics_service.dart';

/// Binding para injeção de dependências do chat IA
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Analytics Service (singleton)
    Get.lazyPut<AnalyticsService>(
      () => AnalyticsService.instance,
      fenix: true,
    );

    // Data Sources
    Get.lazyPut<ChatIaRemoteDataSource>(
      () => ChatIaRemoteDataSourceImpl(),
    );

    Get.lazyPut<ChatIaCacheDataSource>(
      () => ChatIaCacheDataSourceImpl(),
    );

    // Repository
    Get.lazyPut<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: Get.find<ChatIaRemoteDataSource>(),
        cacheDataSource: Get.find<ChatIaCacheDataSource>(),
      ),
    );

    // Use Cases
    Get.lazyPut<GenerateAssistantReplyUseCase>(
      () => GenerateAssistantReplyUseCase(Get.find<ChatRepository>()),
    );

    Get.lazyPut<ManageConversationUseCase>(
      () => ManageConversationUseCase(Get.find<ChatRepository>()),
    );

    // Controller
    Get.lazyPut<ChatController>(
      () => ChatController(
        generateReplyUseCase: Get.find<GenerateAssistantReplyUseCase>(),
        manageConversationUseCase: Get.find<ManageConversationUseCase>(),
        analyticsService: Get.find<AnalyticsService>(),
      ),
    );
  }
}
