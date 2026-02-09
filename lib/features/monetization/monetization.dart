/// Módulo de Monetização - Controle de uso e Rewarded Ads
library monetization;

/// Este módulo gerencia:
/// - Limites diários de uso de features (IA, relatórios, etc.)
/// - Desbloqueios temporários via Rewarded Ads
/// - Compras e assinaturas (futuro)

// Domain - Entidades
export 'domain/entities/usage_limit.dart';
export 'domain/entities/feature_unlock.dart';

// Data - Models
export 'data/models/usage_limit_model.dart';
export 'data/models/feature_unlock_model.dart';

// Data - Services
export 'data/services/usage_limit_service.dart';

// Presentation - Bindings
export 'presentation/bindings/monetization_binding.dart';

// Presentation - Widgets
// Usage limit indicator, limit reached dialog, and unlock promo banner
export 'presentation/widgets/usage_limit_widget.dart';

