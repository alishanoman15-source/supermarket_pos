class Category {
  final String id;
  final String businessId;
  final String name;
  final String status;

  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    this.status = 'active',
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        name: (map['name'] as String?) ?? '',
        status: (map['status'] as String?) ?? 'active',
      );
}

class Brand {
  final String id;
  final String businessId;
  final String name;
  final String status;

  const Brand({
    required this.id,
    required this.businessId,
    required this.name,
    this.status = 'active',
  });

  factory Brand.fromMap(Map<String, dynamic> map) => Brand(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        name: (map['name'] as String?) ?? '',
        status: (map['status'] as String?) ?? 'active',
      );
}

class Unit {
  final String id;
  final String? businessId;
  final String name;
  final String? abbreviation;
  final int decimalsAllowed;
  final bool isSystem;

  const Unit({
    required this.id,
    required this.name,
    this.businessId,
    this.abbreviation,
    this.decimalsAllowed = 0,
    this.isSystem = false,
  });

  factory Unit.fromMap(Map<String, dynamic> map) => Unit(
        id: map['id'] as String,
        businessId: map['business_id'] as String?,
        name: (map['name'] as String?) ?? '',
        abbreviation: map['abbreviation'] as String?,
        decimalsAllowed: (map['decimals_allowed'] as num?)?.toInt() ?? 0,
        isSystem: (map['is_system'] as bool?) ?? false,
      );
}
