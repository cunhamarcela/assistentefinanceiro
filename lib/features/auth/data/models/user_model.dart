import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

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
