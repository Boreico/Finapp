// 1. Import required packages
import 'package:hive/hive.dart';

// 2. Define a TypeAdapter identifier for Hive
part 'category.g.dart';

// 3. Define the Category data model
@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isIncome;

  @HiveField(3)
  final String source;

  // 4. Constructor
  Category({
    required this.id,
    required this.name,
    required this.isIncome,
    required this.source,
  });
    Category copyWith({
    String? id,
    String? name,
    bool? isIncome,
    String? source,

  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isIncome: isIncome ?? this.isIncome,
      source: source ?? this.source,
    );
  }
}