import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/data/services/auth_service.dart';
import '../models/onboarding_question_model.dart';

class OnboardingService extends GetxService {
  late final SecureStorage _secureStorage;
  late final AuthService _authService;

  static const String _onboardingProfileKey = 'onboarding_profile';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  @override
  void onInit() {
    super.onInit();
    _secureStorage = Get.find<SecureStorage>();
    _authService = Get.find<AuthService>();
  }

  /// Salva uma resposta do onboarding
  Future<void> saveResponse(String questionId, dynamic answer) async {
    try {
      final profile = await getOnboardingProfile() ?? OnboardingProfileModel(
        userId: _authService.currentUser?.id ?? '',
        responses: [],
        completedAt: DateTime.now(),
      );

      // Remove resposta anterior se existir
      profile.responses.removeWhere((r) => r.questionId == questionId);

      // Adiciona nova resposta
      profile.responses.add(OnboardingResponseModel(
        questionId: questionId,
        answer: answer,
        answeredAt: DateTime.now(),
      ));

      await _secureStorage.write(_onboardingProfileKey, jsonEncode(profile.toJson()));
    } catch (e) {
      print('❌ Erro ao salvar resposta do onboarding: $e');
      rethrow;
    }
  }

  /// Recupera o perfil completo do onboarding
  Future<OnboardingProfileModel?> getOnboardingProfile() async {
    try {
      final data = await _secureStorage.read(_onboardingProfileKey);
      if (data != null && data is String) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        return OnboardingProfileModel.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao recuperar perfil do onboarding: $e');
      return null;
    }
  }

  /// Marca o onboarding como completo
  Future<void> completeOnboarding() async {
    try {
      final profile = await getOnboardingProfile();
      if (profile != null) {
        final completedProfile = OnboardingProfileModel(
          userId: profile.userId,
          responses: profile.responses,
          completedAt: DateTime.now(),
          isCompleted: true,
        );
        
        await _secureStorage.write(_onboardingProfileKey, jsonEncode(completedProfile.toJson()));
        await _secureStorage.write(_onboardingCompletedKey, 'true');
      }
    } catch (e) {
      print('❌ Erro ao completar onboarding: $e');
      rethrow;
    }
  }

  /// Verifica se o onboarding foi completo
  Future<bool> isOnboardingCompleted() async {
    try {
      final completed = await _secureStorage.read(_onboardingCompletedKey);
      return completed == 'true';
    } catch (e) {
      print('❌ Erro ao verificar status do onboarding: $e');
      return false;
    }
  }

  /// Limpa os dados do onboarding (para testes)
  Future<void> clearOnboardingData() async {
    try {
      await _secureStorage.delete(_onboardingProfileKey);
      await _secureStorage.delete(_onboardingCompletedKey);
    } catch (e) {
      print('❌ Erro ao limpar dados do onboarding: $e');
      rethrow;
    }
  }

  /// Recupera uma resposta específica
  Future<OnboardingResponseModel?> getResponse(String questionId) async {
    try {
      final profile = await getOnboardingProfile();
      if (profile != null) {
        return profile.responses.firstWhereOrNull((r) => r.questionId == questionId);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao recuperar resposta específica: $e');
      return null;
    }
  }

  /// Calcula o progresso do onboarding (0.0 a 1.0)
  Future<double> getProgress() async {
    try {
      final profile = await getOnboardingProfile();
      if (profile == null) return 0.0;
      
      final totalQuestions = OnboardingQuestionModel.questions.length;
      final answeredQuestions = profile.responses.length;
      
      return answeredQuestions / totalQuestions;
    } catch (e) {
      print('❌ Erro ao calcular progresso: $e');
      return 0.0;
    }
  }

  /// Verifica se uma pergunta foi respondida
  Future<bool> isQuestionAnswered(String questionId) async {
    try {
      final response = await getResponse(questionId);
      return response != null;
    } catch (e) {
      print('❌ Erro ao verificar se pergunta foi respondida: $e');
      return false;
    }
  }

  /// Recupera todas as respostas como Map para fácil acesso
  Future<Map<String, dynamic>> getAllResponsesAsMap() async {
    try {
      final profile = await getOnboardingProfile();
      if (profile == null) return {};
      
      final Map<String, dynamic> responsesMap = {};
      for (final response in profile.responses) {
        responsesMap[response.questionId] = response.answer;
      }
      
      return responsesMap;
    } catch (e) {
      print('❌ Erro ao recuperar respostas como Map: $e');
      return {};
    }
  }
}
