import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../routes/app_routes.dart';

/// Middleware base para autenticação
abstract class BaseAuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  /// Verificar se o usuário está autenticado
  bool get isAuthenticated {
    try {
      final authService = Get.find<AuthService>();
      return authService.isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// Verificar se o email está verificado
  bool get isEmailVerified {
    try {
      final authService = Get.find<AuthService>();
      return authService.isEmailVerified;
    } catch (e) {
      return false;
    }
  }

  /// Redirecionar para login
  RouteSettings? redirectToLogin() {
    return const RouteSettings(name: AppRoutes.login);
  }

  /// Redirecionar para home
  RouteSettings? redirectToHome() {
    return const RouteSettings(name: AppRoutes.home);
  }

  /// Redirecionar para verificação de email
  RouteSettings? redirectToEmailVerification() {
    return const RouteSettings(name: AppRoutes.emailVerification);
  }
}

/// Middleware para proteger rotas que requerem autenticação
class AuthMiddleware extends BaseAuthMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Se não estiver autenticado, redirecionar para login
    if (!isAuthenticated) {
      print('🔒 Acesso negado para $route - usuário não autenticado');
      return redirectToLogin();
    }

    print('✅ Acesso permitido para $route - usuário autenticado');
    return null;
  }
}

/// Middleware para rotas que só devem ser acessadas por usuários não autenticados
class GuestMiddleware extends BaseAuthMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Aguardar um pouco para o estado de autenticação se estabilizar
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isAuthenticated && Get.currentRoute == route) {
        print('🔄 Redirecionando de $route para home - usuário já autenticado');
        Get.offAllNamed(AppRoutes.home);
      }
    });

    print('✅ Acesso permitido para $route - usuário não autenticado');
    return null;
  }
}

/// Middleware para rotas que requerem email verificado
class EmailVerificationMiddleware extends BaseAuthMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Primeiro verificar se está autenticado
    if (!isAuthenticated) {
      print('🔒 Acesso negado para $route - usuário não autenticado');
      return redirectToLogin();
    }

    // Verificar se o email está verificado
    if (!isEmailVerified) {
      print('📧 Redirecionando de $route - email não verificado');
      return redirectToEmailVerification();
    }

    print('✅ Acesso permitido para $route - email verificado');
    return null;
  }
}

/// Middleware para rotas administrativas
class AdminMiddleware extends BaseAuthMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Primeiro verificar se está autenticado
    if (!isAuthenticated) {
      print('🔒 Acesso negado para $route - usuário não autenticado');
      return redirectToLogin();
    }

    // Verificar se é administrador
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser;
      
      if (user == null || !user.isAdmin) {
        print('🚫 Acesso negado para $route - usuário não é administrador');
        return redirectToHome();
      }
    } catch (e) {
      print('❌ Erro ao verificar permissões administrativas: $e');
      return redirectToLogin();
    }

    print('👑 Acesso permitido para $route - usuário administrador');
    return null;
  }
}

/// Middleware para verificar conectividade de rede
class NetworkMiddleware extends GetMiddleware {
  @override
  int? get priority => 0; // Prioridade mais alta

  @override
  RouteSettings? redirect(String? route) {
    // Aqui você pode implementar verificação de rede
    // Por exemplo, usando connectivity_plus package
    
    // Por enquanto, sempre permitir acesso
    return null;
  }
}

/// Middleware para rotas que requerem roles específicos
class RoleMiddleware extends BaseAuthMiddleware {
  final List<String> requiredRoles;

  RoleMiddleware({required this.requiredRoles});

  @override
  RouteSettings? redirect(String? route) {
    // Primeiro verificar se está autenticado
    if (!isAuthenticated) {
      print('🔒 Acesso negado para $route - usuário não autenticado');
      return redirectToLogin();
    }

    // Verificar se tem as roles necessárias
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser;
      
      if (user == null) {
        return redirectToLogin();
      }

      // Verificar se tem pelo menos uma das roles necessárias
      bool hasRequiredRole = false;
      for (final role in requiredRoles) {
        if (user.hasRole(role)) {
          hasRequiredRole = true;
          break;
        }
      }

      if (!hasRequiredRole) {
        print('🚫 Acesso negado para $route - usuário não tem roles necessárias: $requiredRoles');
        return redirectToHome();
      }
    } catch (e) {
      print('❌ Erro ao verificar roles: $e');
      return redirectToLogin();
    }

    print('✅ Acesso permitido para $route - usuário tem roles necessárias');
    return null;
  }
}

/// Middleware para logging de navegação
class NavigationLogMiddleware extends GetMiddleware {
  @override
  int? get priority => 10; // Prioridade baixa para executar por último

  @override
  RouteSettings? redirect(String? route) {
    print('🧭 Navegando para: $route');
    
    // Log adicional para debug
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser;
      print('👤 Usuário atual: ${user?.email ?? 'Não autenticado'}');
    } catch (e) {
      print('👤 AuthService não disponível');
    }
    
    return null;
  }
}

/// Middleware para verificar se o usuário precisa atualizar dados
class ProfileUpdateMiddleware extends BaseAuthMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Verificar se está autenticado
    if (!isAuthenticated) {
      return null; // Deixar outros middlewares tratarem
    }

    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser;
      
      // Se o usuário não tem nome definido, redirecionar para completar perfil
      if (user != null && user.name.isEmpty) {
        print('📝 Redirecionando para completar perfil - nome não definido');
        return const RouteSettings(name: AppRoutes.completeProfile);
      }
    } catch (e) {
      print('❌ Erro ao verificar perfil: $e');
    }

    return null;
  }
}

/// Middleware para verificar manutenção do sistema
class MaintenanceMiddleware extends GetMiddleware {
  @override
  int? get priority => -1; // Prioridade máxima

  @override
  RouteSettings? redirect(String? route) {
    // Aqui você pode implementar verificação de manutenção
    // Por exemplo, verificando uma flag no Firebase Remote Config
    
    const isMaintenanceMode = false; // Implementar lógica real
    
    if (isMaintenanceMode && route != AppRoutes.maintenance) {
      print('🔧 Sistema em manutenção - redirecionando');
      return const RouteSettings(name: AppRoutes.maintenance);
    }
    
    return null;
  }
}

/// Factory para criar middlewares facilmente
class MiddlewareFactory {
  /// Middleware básico de autenticação
  static AuthMiddleware auth() => AuthMiddleware();
  
  /// Middleware para guests (não autenticados)
  static GuestMiddleware guest() => GuestMiddleware();
  
  /// Middleware para email verificado
  static EmailVerificationMiddleware emailVerified() => EmailVerificationMiddleware();
  
  /// Middleware para administradores
  static AdminMiddleware admin() => AdminMiddleware();
  
  /// Middleware para roles específicos
  static RoleMiddleware role(List<String> roles) => RoleMiddleware(requiredRoles: roles);
  
  /// Middleware de logging
  static NavigationLogMiddleware log() => NavigationLogMiddleware();
  
  /// Middleware de rede
  static NetworkMiddleware network() => NetworkMiddleware();
  
  /// Middleware de perfil
  static ProfileUpdateMiddleware profile() => ProfileUpdateMiddleware();
  
  /// Middleware de manutenção
  static MaintenanceMiddleware maintenance() => MaintenanceMiddleware();
  
  /// Combinação comum: autenticação + email verificado
  static List<GetMiddleware> authWithEmailVerified() => [
        auth(),
        emailVerified(),
      ];
  
  /// Combinação comum: autenticação + administrador
  static List<GetMiddleware> authAdmin() => [
        auth(),
        admin(),
      ];
}
