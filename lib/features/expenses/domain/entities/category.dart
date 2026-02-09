import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ExpenseCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final List<String> keywords;
  final bool isDefault;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.keywords,
    this.isDefault = false,
  });

  /// Factory para criar categoria a partir de JSON
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: Color(int.parse(json['color'].toString().replaceFirst('#', '0xFF'))),
      keywords: List<String>.from(json['keywords'] ?? []),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Converte categoria para JSON
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

  /// Factory para criar uma nova categoria
  factory ExpenseCategory.create({
    required String name,
    required String icon,
    required int colorValue,
    required List<String> keywords,
  }) {
    final now = DateTime.now();
    final id = '${name.toLowerCase().replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}';
    
    return ExpenseCategory(
      id: id,
      name: name,
      icon: icon,
      color: Color(colorValue),
      keywords: keywords,
      isDefault: false,
    );
  }

  /// Cria uma cópia da categoria com novos valores
  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    int? colorValue,
    List<String>? keywords,
    bool? isDefault,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: colorValue != null ? Color(colorValue) : (color ?? this.color),
      keywords: keywords ?? this.keywords,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Verifica se a descrição corresponde a esta categoria
  bool matchesDescription(String description) {
    if (keywords.isEmpty) return false;
    
    final lowerDescription = description.toLowerCase();
    return keywords.any((keyword) => 
        lowerDescription.contains(keyword.toLowerCase()));
  }

  /// Retorna o ícone como IconData
  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'receipt':
        return Icons.receipt;
      case 'movie':
        return Icons.movie;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'devices':
        return Icons.devices;
      case 'trending_up':
        return Icons.trending_up;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'pets':
        return Icons.pets;
      case 'work':
        return Icons.work;
      case 'more_horiz':
      default:
        return Icons.more_horiz;
    }
  }

  /// Retorna cor com opacidade
  Color get colorWithOpacity => color.withOpacity(0.1);

  @override
  List<Object?> get props => [id, name, icon, color, keywords, isDefault];

  @override
  String toString() {
    return 'ExpenseCategory(id: $id, name: $name, icon: $icon)';
  }

  /// Categorias padrão do sistema
  static List<ExpenseCategory> get defaultCategories => [
    const ExpenseCategory(
      id: 'alimentacao',
      name: 'Alimentação',
      icon: 'restaurant',
      color: Color(0xFFFF5722),
      keywords: ['supermercado', 'restaurante', 'lanche', 'comida', 'almoço', 'jantar', 'café', 'padaria', 'açougue', 'hortifruti', 'delivery', 'ifood', 'uber eats', 'mercado', 'feira', 'bebida'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'transporte',
      name: 'Transporte',
      icon: 'directions_car',
      color: Color(0xFF2196F3),
      keywords: ['uber', 'gasolina', 'ônibus', 'metro', 'taxi', 'combustível', 'estacionamento', 'pedágio', '99', 'cabify', 'carro', 'moto', 'bicicleta', 'transporte público', 'viagem', 'passagem'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'saude',
      name: 'Saúde',
      icon: 'local_hospital',
      color: Color(0xFFE91E63),
      keywords: ['farmácia', 'médico', 'hospital', 'remédio', 'consulta', 'dentista', 'exame', 'plano de saúde'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'contas',
      name: 'Contas',
      icon: 'receipt',
      color: Color(0xFFFF9800),
      keywords: ['luz', 'água', 'internet', 'telefone', 'energia', 'conta', 'celular', 'tv', 'streaming', 'netflix', 'spotify', 'amazon prime', 'gás', 'condomínio', 'iptu', 'seguro'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'lazer',
      name: 'Lazer',
      icon: 'movie',
      color: Color(0xFF9C27B0),
      keywords: ['cinema', 'show', 'festa', 'viagem', 'entretenimento', 'bar', 'balada', 'teatro', 'parque'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'casa',
      name: 'Casa',
      icon: 'home',
      color: Color(0xFF795548),
      keywords: ['aluguel', 'financiamento', 'móveis', 'decoração', 'limpeza', 'manutenção', 'reforma'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'educacao',
      name: 'Educação',
      icon: 'school',
      color: Color(0xFF3F51B5),
      keywords: ['curso', 'livro', 'escola', 'faculdade', 'mensalidade', 'material escolar', 'aula'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'roupas',
      name: 'Roupas e Beleza',
      icon: 'shopping_bag',
      color: Color(0xFFE91E63),
      keywords: ['roupa', 'sapato', 'beleza', 'cabelo', 'salão', 'maquiagem', 'perfume', 'acessório'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'tecnologia',
      name: 'Tecnologia',
      icon: 'devices',
      color: Color(0xFF00BCD4),
      keywords: ['celular', 'computador', 'software', 'aplicativo', 'eletrônicos', 'gadget', 'internet'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'pets',
      name: 'Pets',
      icon: 'pets',
      color: Color(0xFF4CAF50),
      keywords: ['pet', 'cachorro', 'gato', 'veterinário', 'ração', 'petshop', 'animal'],
      isDefault: true,
    ),
    const ExpenseCategory(
      id: 'outros',
      name: 'Outros',
      icon: 'more_horiz',
      color: Color(0xFF607D8B),
      keywords: ['diversos', 'vários', 'geral'],
      isDefault: true,
    ),
  ];
}
