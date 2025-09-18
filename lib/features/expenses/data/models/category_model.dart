import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category.dart';

class CategoryModel extends ExpenseCategory {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.keywords,
    super.isDefault = false,
  });

  /// Factory para criar CategoryModel a partir de JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: Color(int.parse(json['color'].toString().replaceFirst('#', '0xFF'))),
      keywords: List<String>.from(json['keywords'] ?? []),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Converte CategoryModel para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'keywords': keywords,
      'isDefault': isDefault,
    };
  }

  /// Factory para criar CategoryModel a partir de Entity
  factory CategoryModel.fromEntity(ExpenseCategory category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      keywords: category.keywords,
      isDefault: category.isDefault,
    );
  }

  /// Converte CategoryModel para Entity
  ExpenseCategory toEntity() {
    return ExpenseCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
      keywords: keywords,
      isDefault: isDefault,
    );
  }

  /// Cria uma cópia com novos valores
  @override
  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    int? colorValue,
    List<String>? keywords,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: colorValue != null ? Color(colorValue) : (color ?? this.color),
      keywords: keywords ?? this.keywords,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Converte para Map para SQLite
  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'keywords': keywords.join(','),
      'isDefault': isDefault ? 1 : 0,
    };
  }

  /// Factory para criar a partir de Map do SQLite
  factory CategoryModel.fromSQLite(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: Color(map['color'] as int),
      keywords: (map['keywords'] as String).isEmpty 
          ? [] 
          : (map['keywords'] as String).split(','),
      isDefault: (map['isDefault'] as int) == 1,
    );
  }

  /// Categorias padrão como modelos
  static List<CategoryModel> get defaultCategories {
    return ExpenseCategory.defaultCategories
        .map((category) => CategoryModel.fromEntity(category))
        .toList();
  }

  /// Converte para Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'keywords': keywords,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Factory para criar a partir de Map do Firestore
  factory CategoryModel.fromFirestore(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: Color(map['color'] as int),
      keywords: List<String>.from(map['keywords'] ?? []),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}
