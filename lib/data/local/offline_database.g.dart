// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    parentId,
    status,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String businessId;
  final String name;
  final String? parentId;
  final String status;
  final DateTime? createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    this.parentId,
    required this.status,
    this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      businessId: Value(businessId),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Category copyWith({
    String? id,
    String? businessId,
    String? name,
    Value<String?> parentId = const Value.absent(),
    String? status,
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    status: status ?? this.status,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    parentId,
    status,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String> status;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String businessId,
    required String name,
    this.parentId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? parentId,
    Value<String>? status,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandIdMeta = const VerificationMeta(
    'brandId',
  );
  @override
  late final GeneratedColumn<String> brandId = GeneratedColumn<String>(
    'brand_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
    'unit_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellingPriceMeta = const VerificationMeta(
    'sellingPrice',
  );
  @override
  late final GeneratedColumn<String> sellingPrice = GeneratedColumn<String>(
    'selling_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<String> taxRate = GeneratedColumn<String>(
    'tax_rate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isWeightBasedMeta = const VerificationMeta(
    'isWeightBased',
  );
  @override
  late final GeneratedColumn<bool> isWeightBased = GeneratedColumn<bool>(
    'is_weight_based',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_weight_based" IN (0, 1))',
    ),
  );
  static const VerificationMeta _trackBatchMeta = const VerificationMeta(
    'trackBatch',
  );
  @override
  late final GeneratedColumn<bool> trackBatch = GeneratedColumn<bool>(
    'track_batch',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_batch" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reorderLevelMeta = const VerificationMeta(
    'reorderLevel',
  );
  @override
  late final GeneratedColumn<String> reorderLevel = GeneratedColumn<String>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<String> stock = GeneratedColumn<String>(
    'stock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    name,
    sku,
    barcode,
    categoryId,
    brandId,
    unitId,
    sellingPrice,
    taxRate,
    isWeightBased,
    trackBatch,
    reorderLevel,
    stock,
    status,
    imageUrl,
    description,
    createdAt,
    updatedAt,
    deletedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('brand_id')) {
      context.handle(
        _brandIdMeta,
        brandId.isAcceptableOrUnknown(data['brand_id']!, _brandIdMeta),
      );
    }
    if (data.containsKey('unit_id')) {
      context.handle(
        _unitIdMeta,
        unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta),
      );
    }
    if (data.containsKey('selling_price')) {
      context.handle(
        _sellingPriceMeta,
        sellingPrice.isAcceptableOrUnknown(
          data['selling_price']!,
          _sellingPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sellingPriceMeta);
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    } else if (isInserting) {
      context.missing(_taxRateMeta);
    }
    if (data.containsKey('is_weight_based')) {
      context.handle(
        _isWeightBasedMeta,
        isWeightBased.isAcceptableOrUnknown(
          data['is_weight_based']!,
          _isWeightBasedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isWeightBasedMeta);
    }
    if (data.containsKey('track_batch')) {
      context.handle(
        _trackBatchMeta,
        trackBatch.isAcceptableOrUnknown(data['track_batch']!, _trackBatchMeta),
      );
    } else if (isInserting) {
      context.missing(_trackBatchMeta);
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
        _reorderLevelMeta,
        reorderLevel.isAcceptableOrUnknown(
          data['reorder_level']!,
          _reorderLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reorderLevelMeta);
    }
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    } else if (isInserting) {
      context.missing(_stockMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, branchId};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      brandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_id'],
      ),
      unitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_id'],
      ),
      sellingPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selling_price'],
      )!,
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_rate'],
      )!,
      isWeightBased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_weight_based'],
      )!,
      trackBatch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_batch'],
      )!,
      reorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reorder_level'],
      )!,
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String businessId;
  final String branchId;
  final String name;
  final String? sku;
  final String? barcode;
  final String? categoryId;
  final String? brandId;
  final String? unitId;
  final String sellingPrice;
  final String taxRate;
  final bool isWeightBased;
  final bool trackBatch;
  final String reorderLevel;
  final String stock;
  final String status;
  final String? imageUrl;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime cachedAt;
  const Product({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.name,
    this.sku,
    this.barcode,
    this.categoryId,
    this.brandId,
    this.unitId,
    required this.sellingPrice,
    required this.taxRate,
    required this.isWeightBased,
    required this.trackBatch,
    required this.reorderLevel,
    required this.stock,
    required this.status,
    this.imageUrl,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['branch_id'] = Variable<String>(branchId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || brandId != null) {
      map['brand_id'] = Variable<String>(brandId);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<String>(unitId);
    }
    map['selling_price'] = Variable<String>(sellingPrice);
    map['tax_rate'] = Variable<String>(taxRate);
    map['is_weight_based'] = Variable<bool>(isWeightBased);
    map['track_batch'] = Variable<bool>(trackBatch);
    map['reorder_level'] = Variable<String>(reorderLevel);
    map['stock'] = Variable<String>(stock);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      businessId: Value(businessId),
      branchId: Value(branchId),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      brandId: brandId == null && nullToAbsent
          ? const Value.absent()
          : Value(brandId),
      unitId: unitId == null && nullToAbsent
          ? const Value.absent()
          : Value(unitId),
      sellingPrice: Value(sellingPrice),
      taxRate: Value(taxRate),
      isWeightBased: Value(isWeightBased),
      trackBatch: Value(trackBatch),
      reorderLevel: Value(reorderLevel),
      stock: Value(stock),
      status: Value(status),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      brandId: serializer.fromJson<String?>(json['brandId']),
      unitId: serializer.fromJson<String?>(json['unitId']),
      sellingPrice: serializer.fromJson<String>(json['sellingPrice']),
      taxRate: serializer.fromJson<String>(json['taxRate']),
      isWeightBased: serializer.fromJson<bool>(json['isWeightBased']),
      trackBatch: serializer.fromJson<bool>(json['trackBatch']),
      reorderLevel: serializer.fromJson<String>(json['reorderLevel']),
      stock: serializer.fromJson<String>(json['stock']),
      status: serializer.fromJson<String>(json['status']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String>(branchId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'categoryId': serializer.toJson<String?>(categoryId),
      'brandId': serializer.toJson<String?>(brandId),
      'unitId': serializer.toJson<String?>(unitId),
      'sellingPrice': serializer.toJson<String>(sellingPrice),
      'taxRate': serializer.toJson<String>(taxRate),
      'isWeightBased': serializer.toJson<bool>(isWeightBased),
      'trackBatch': serializer.toJson<bool>(trackBatch),
      'reorderLevel': serializer.toJson<String>(reorderLevel),
      'stock': serializer.toJson<String>(stock),
      'status': serializer.toJson<String>(status),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  Product copyWith({
    String? id,
    String? businessId,
    String? branchId,
    String? name,
    Value<String?> sku = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> brandId = const Value.absent(),
    Value<String?> unitId = const Value.absent(),
    String? sellingPrice,
    String? taxRate,
    bool? isWeightBased,
    bool? trackBatch,
    String? reorderLevel,
    String? stock,
    String? status,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => Product(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    brandId: brandId.present ? brandId.value : this.brandId,
    unitId: unitId.present ? unitId.value : this.unitId,
    sellingPrice: sellingPrice ?? this.sellingPrice,
    taxRate: taxRate ?? this.taxRate,
    isWeightBased: isWeightBased ?? this.isWeightBased,
    trackBatch: trackBatch ?? this.trackBatch,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    stock: stock ?? this.stock,
    status: status ?? this.status,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    description: description.present ? description.value : this.description,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      brandId: data.brandId.present ? data.brandId.value : this.brandId,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      sellingPrice: data.sellingPrice.present
          ? data.sellingPrice.value
          : this.sellingPrice,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      isWeightBased: data.isWeightBased.present
          ? data.isWeightBased.value
          : this.isWeightBased,
      trackBatch: data.trackBatch.present
          ? data.trackBatch.value
          : this.trackBatch,
      reorderLevel: data.reorderLevel.present
          ? data.reorderLevel.value
          : this.reorderLevel,
      stock: data.stock.present ? data.stock.value : this.stock,
      status: data.status.present ? data.status.value : this.status,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('brandId: $brandId, ')
          ..write('unitId: $unitId, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('isWeightBased: $isWeightBased, ')
          ..write('trackBatch: $trackBatch, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('stock: $stock, ')
          ..write('status: $status, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    branchId,
    name,
    sku,
    barcode,
    categoryId,
    brandId,
    unitId,
    sellingPrice,
    taxRate,
    isWeightBased,
    trackBatch,
    reorderLevel,
    stock,
    status,
    imageUrl,
    description,
    createdAt,
    updatedAt,
    deletedAt,
    cachedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.categoryId == this.categoryId &&
          other.brandId == this.brandId &&
          other.unitId == this.unitId &&
          other.sellingPrice == this.sellingPrice &&
          other.taxRate == this.taxRate &&
          other.isWeightBased == this.isWeightBased &&
          other.trackBatch == this.trackBatch &&
          other.reorderLevel == this.reorderLevel &&
          other.stock == this.stock &&
          other.status == this.status &&
          other.imageUrl == this.imageUrl &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.cachedAt == this.cachedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> branchId;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<String?> categoryId;
  final Value<String?> brandId;
  final Value<String?> unitId;
  final Value<String> sellingPrice;
  final Value<String> taxRate;
  final Value<bool> isWeightBased;
  final Value<bool> trackBatch;
  final Value<String> reorderLevel;
  final Value<String> stock;
  final Value<String> status;
  final Value<String?> imageUrl;
  final Value<String?> description;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.brandId = const Value.absent(),
    this.unitId = const Value.absent(),
    this.sellingPrice = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.isWeightBased = const Value.absent(),
    this.trackBatch = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.stock = const Value.absent(),
    this.status = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String businessId,
    required String branchId,
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.brandId = const Value.absent(),
    this.unitId = const Value.absent(),
    required String sellingPrice,
    required String taxRate,
    required bool isWeightBased,
    required bool trackBatch,
    required String reorderLevel,
    required String stock,
    required String status,
    this.imageUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       branchId = Value(branchId),
       name = Value(name),
       sellingPrice = Value(sellingPrice),
       taxRate = Value(taxRate),
       isWeightBased = Value(isWeightBased),
       trackBatch = Value(trackBatch),
       reorderLevel = Value(reorderLevel),
       stock = Value(stock),
       status = Value(status),
       cachedAt = Value(cachedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? categoryId,
    Expression<String>? brandId,
    Expression<String>? unitId,
    Expression<String>? sellingPrice,
    Expression<String>? taxRate,
    Expression<bool>? isWeightBased,
    Expression<bool>? trackBatch,
    Expression<String>? reorderLevel,
    Expression<String>? stock,
    Expression<String>? status,
    Expression<String>? imageUrl,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
      if (unitId != null) 'unit_id': unitId,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (taxRate != null) 'tax_rate': taxRate,
      if (isWeightBased != null) 'is_weight_based': isWeightBased,
      if (trackBatch != null) 'track_batch': trackBatch,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (stock != null) 'stock': stock,
      if (status != null) 'status': status,
      if (imageUrl != null) 'image_url': imageUrl,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? branchId,
    Value<String>? name,
    Value<String?>? sku,
    Value<String?>? barcode,
    Value<String?>? categoryId,
    Value<String?>? brandId,
    Value<String?>? unitId,
    Value<String>? sellingPrice,
    Value<String>? taxRate,
    Value<bool>? isWeightBased,
    Value<bool>? trackBatch,
    Value<String>? reorderLevel,
    Value<String>? stock,
    Value<String>? status,
    Value<String?>? imageUrl,
    Value<String?>? description,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      unitId: unitId ?? this.unitId,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      taxRate: taxRate ?? this.taxRate,
      isWeightBased: isWeightBased ?? this.isWeightBased,
      trackBatch: trackBatch ?? this.trackBatch,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (brandId.present) {
      map['brand_id'] = Variable<String>(brandId.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (sellingPrice.present) {
      map['selling_price'] = Variable<String>(sellingPrice.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<String>(taxRate.value);
    }
    if (isWeightBased.present) {
      map['is_weight_based'] = Variable<bool>(isWeightBased.value);
    }
    if (trackBatch.present) {
      map['track_batch'] = Variable<bool>(trackBatch.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<String>(reorderLevel.value);
    }
    if (stock.present) {
      map['stock'] = Variable<String>(stock.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('categoryId: $categoryId, ')
          ..write('brandId: $brandId, ')
          ..write('unitId: $unitId, ')
          ..write('sellingPrice: $sellingPrice, ')
          ..write('taxRate: $taxRate, ')
          ..write('isWeightBased: $isWeightBased, ')
          ..write('trackBatch: $trackBatch, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('stock: $stock, ')
          ..write('status: $status, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<String> subtotal = GeneratedColumn<String>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountTotalMeta = const VerificationMeta(
    'discountTotal',
  );
  @override
  late final GeneratedColumn<String> discountTotal = GeneratedColumn<String>(
    'discount_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxTotalMeta = const VerificationMeta(
    'taxTotal',
  );
  @override
  late final GeneratedColumn<String> taxTotal = GeneratedColumn<String>(
    'tax_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<String> grandTotal = GeneratedColumn<String>(
    'grand_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaidMeta = const VerificationMeta(
    'amountPaid',
  );
  @override
  late final GeneratedColumn<String> amountPaid = GeneratedColumn<String>(
    'amount_paid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeDueMeta = const VerificationMeta(
    'changeDue',
  );
  @override
  late final GeneratedColumn<String> changeDue = GeneratedColumn<String>(
    'change_due',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_sync'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpcPayloadMeta = const VerificationMeta(
    'rpcPayload',
  );
  @override
  late final GeneratedColumn<String> rpcPayload = GeneratedColumn<String>(
    'rpc_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSoldAtMeta = const VerificationMeta(
    'serverSoldAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverSoldAt = GeneratedColumn<DateTime>(
    'server_sold_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverCreatedAtMeta = const VerificationMeta(
    'serverCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverCreatedAt =
      GeneratedColumn<DateTime>(
        'server_created_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverSaleIdMeta = const VerificationMeta(
    'serverSaleId',
  );
  @override
  late final GeneratedColumn<String> serverSaleId = GeneratedColumn<String>(
    'server_sale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    branchId,
    shiftId,
    cashierId,
    customerId,
    idempotencyKey,
    invoiceNumber,
    subtotal,
    discountTotal,
    taxTotal,
    grandTotal,
    amountPaid,
    changeDue,
    status,
    syncStatus,
    note,
    rpcPayload,
    capturedAt,
    createdAt,
    serverSoldAt,
    serverCreatedAt,
    syncedAt,
    serverSaleId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Order> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount_total')) {
      context.handle(
        _discountTotalMeta,
        discountTotal.isAcceptableOrUnknown(
          data['discount_total']!,
          _discountTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTotalMeta);
    }
    if (data.containsKey('tax_total')) {
      context.handle(
        _taxTotalMeta,
        taxTotal.isAcceptableOrUnknown(data['tax_total']!, _taxTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_taxTotalMeta);
    }
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_grandTotalMeta);
    }
    if (data.containsKey('amount_paid')) {
      context.handle(
        _amountPaidMeta,
        amountPaid.isAcceptableOrUnknown(data['amount_paid']!, _amountPaidMeta),
      );
    } else if (isInserting) {
      context.missing(_amountPaidMeta);
    }
    if (data.containsKey('change_due')) {
      context.handle(
        _changeDueMeta,
        changeDue.isAcceptableOrUnknown(data['change_due']!, _changeDueMeta),
      );
    } else if (isInserting) {
      context.missing(_changeDueMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('rpc_payload')) {
      context.handle(
        _rpcPayloadMeta,
        rpcPayload.isAcceptableOrUnknown(data['rpc_payload']!, _rpcPayloadMeta),
      );
    } else if (isInserting) {
      context.missing(_rpcPayloadMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('server_sold_at')) {
      context.handle(
        _serverSoldAtMeta,
        serverSoldAt.isAcceptableOrUnknown(
          data['server_sold_at']!,
          _serverSoldAtMeta,
        ),
      );
    }
    if (data.containsKey('server_created_at')) {
      context.handle(
        _serverCreatedAtMeta,
        serverCreatedAt.isAcceptableOrUnknown(
          data['server_created_at']!,
          _serverCreatedAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('server_sale_id')) {
      context.handle(
        _serverSaleIdMeta,
        serverSaleId.isAcceptableOrUnknown(
          data['server_sale_id']!,
          _serverSaleIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtotal'],
      )!,
      discountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_total'],
      )!,
      taxTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_total'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grand_total'],
      )!,
      amountPaid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_paid'],
      )!,
      changeDue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_due'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      rpcPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rpc_payload'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      serverSoldAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_sold_at'],
      ),
      serverCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_created_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      serverSaleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_sale_id'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final String id;
  final String businessId;
  final String branchId;
  final String shiftId;
  final String cashierId;
  final String? customerId;
  final String idempotencyKey;
  final String? invoiceNumber;
  final String subtotal;
  final String discountTotal;
  final String taxTotal;
  final String grandTotal;
  final String amountPaid;
  final String changeDue;
  final String status;
  final String syncStatus;
  final String? note;
  final String rpcPayload;
  final DateTime capturedAt;
  final DateTime? createdAt;
  final DateTime? serverSoldAt;
  final DateTime? serverCreatedAt;
  final DateTime? syncedAt;
  final String? serverSaleId;
  const Order({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.shiftId,
    required this.cashierId,
    this.customerId,
    required this.idempotencyKey,
    this.invoiceNumber,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.amountPaid,
    required this.changeDue,
    required this.status,
    required this.syncStatus,
    this.note,
    required this.rpcPayload,
    required this.capturedAt,
    this.createdAt,
    this.serverSoldAt,
    this.serverCreatedAt,
    this.syncedAt,
    this.serverSaleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_id'] = Variable<String>(businessId);
    map['branch_id'] = Variable<String>(branchId);
    map['shift_id'] = Variable<String>(shiftId);
    map['cashier_id'] = Variable<String>(cashierId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    map['subtotal'] = Variable<String>(subtotal);
    map['discount_total'] = Variable<String>(discountTotal);
    map['tax_total'] = Variable<String>(taxTotal);
    map['grand_total'] = Variable<String>(grandTotal);
    map['amount_paid'] = Variable<String>(amountPaid);
    map['change_due'] = Variable<String>(changeDue);
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['rpc_payload'] = Variable<String>(rpcPayload);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || serverSoldAt != null) {
      map['server_sold_at'] = Variable<DateTime>(serverSoldAt);
    }
    if (!nullToAbsent || serverCreatedAt != null) {
      map['server_created_at'] = Variable<DateTime>(serverCreatedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || serverSaleId != null) {
      map['server_sale_id'] = Variable<String>(serverSaleId);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      businessId: Value(businessId),
      branchId: Value(branchId),
      shiftId: Value(shiftId),
      cashierId: Value(cashierId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      idempotencyKey: Value(idempotencyKey),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      subtotal: Value(subtotal),
      discountTotal: Value(discountTotal),
      taxTotal: Value(taxTotal),
      grandTotal: Value(grandTotal),
      amountPaid: Value(amountPaid),
      changeDue: Value(changeDue),
      status: Value(status),
      syncStatus: Value(syncStatus),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      rpcPayload: Value(rpcPayload),
      capturedAt: Value(capturedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      serverSoldAt: serverSoldAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSoldAt),
      serverCreatedAt: serverCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverCreatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      serverSaleId: serverSaleId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverSaleId),
    );
  }

  factory Order.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<String>(json['id']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      subtotal: serializer.fromJson<String>(json['subtotal']),
      discountTotal: serializer.fromJson<String>(json['discountTotal']),
      taxTotal: serializer.fromJson<String>(json['taxTotal']),
      grandTotal: serializer.fromJson<String>(json['grandTotal']),
      amountPaid: serializer.fromJson<String>(json['amountPaid']),
      changeDue: serializer.fromJson<String>(json['changeDue']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      note: serializer.fromJson<String?>(json['note']),
      rpcPayload: serializer.fromJson<String>(json['rpcPayload']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      serverSoldAt: serializer.fromJson<DateTime?>(json['serverSoldAt']),
      serverCreatedAt: serializer.fromJson<DateTime?>(json['serverCreatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      serverSaleId: serializer.fromJson<String?>(json['serverSaleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String>(branchId),
      'shiftId': serializer.toJson<String>(shiftId),
      'cashierId': serializer.toJson<String>(cashierId),
      'customerId': serializer.toJson<String?>(customerId),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'subtotal': serializer.toJson<String>(subtotal),
      'discountTotal': serializer.toJson<String>(discountTotal),
      'taxTotal': serializer.toJson<String>(taxTotal),
      'grandTotal': serializer.toJson<String>(grandTotal),
      'amountPaid': serializer.toJson<String>(amountPaid),
      'changeDue': serializer.toJson<String>(changeDue),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'note': serializer.toJson<String?>(note),
      'rpcPayload': serializer.toJson<String>(rpcPayload),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'serverSoldAt': serializer.toJson<DateTime?>(serverSoldAt),
      'serverCreatedAt': serializer.toJson<DateTime?>(serverCreatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'serverSaleId': serializer.toJson<String?>(serverSaleId),
    };
  }

  Order copyWith({
    String? id,
    String? businessId,
    String? branchId,
    String? shiftId,
    String? cashierId,
    Value<String?> customerId = const Value.absent(),
    String? idempotencyKey,
    Value<String?> invoiceNumber = const Value.absent(),
    String? subtotal,
    String? discountTotal,
    String? taxTotal,
    String? grandTotal,
    String? amountPaid,
    String? changeDue,
    String? status,
    String? syncStatus,
    Value<String?> note = const Value.absent(),
    String? rpcPayload,
    DateTime? capturedAt,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> serverSoldAt = const Value.absent(),
    Value<DateTime?> serverCreatedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<String?> serverSaleId = const Value.absent(),
  }) => Order(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    shiftId: shiftId ?? this.shiftId,
    cashierId: cashierId ?? this.cashierId,
    customerId: customerId.present ? customerId.value : this.customerId,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    subtotal: subtotal ?? this.subtotal,
    discountTotal: discountTotal ?? this.discountTotal,
    taxTotal: taxTotal ?? this.taxTotal,
    grandTotal: grandTotal ?? this.grandTotal,
    amountPaid: amountPaid ?? this.amountPaid,
    changeDue: changeDue ?? this.changeDue,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
    note: note.present ? note.value : this.note,
    rpcPayload: rpcPayload ?? this.rpcPayload,
    capturedAt: capturedAt ?? this.capturedAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    serverSoldAt: serverSoldAt.present ? serverSoldAt.value : this.serverSoldAt,
    serverCreatedAt: serverCreatedAt.present
        ? serverCreatedAt.value
        : this.serverCreatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    serverSaleId: serverSaleId.present ? serverSaleId.value : this.serverSaleId,
  );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountTotal: data.discountTotal.present
          ? data.discountTotal.value
          : this.discountTotal,
      taxTotal: data.taxTotal.present ? data.taxTotal.value : this.taxTotal,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      amountPaid: data.amountPaid.present
          ? data.amountPaid.value
          : this.amountPaid,
      changeDue: data.changeDue.present ? data.changeDue.value : this.changeDue,
      status: data.status.present ? data.status.value : this.status,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      note: data.note.present ? data.note.value : this.note,
      rpcPayload: data.rpcPayload.present
          ? data.rpcPayload.value
          : this.rpcPayload,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      serverSoldAt: data.serverSoldAt.present
          ? data.serverSoldAt.value
          : this.serverSoldAt,
      serverCreatedAt: data.serverCreatedAt.present
          ? data.serverCreatedAt.value
          : this.serverCreatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      serverSaleId: data.serverSaleId.present
          ? data.serverSaleId.value
          : this.serverSaleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('shiftId: $shiftId, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerId: $customerId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('taxTotal: $taxTotal, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('changeDue: $changeDue, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('note: $note, ')
          ..write('rpcPayload: $rpcPayload, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverSoldAt: $serverSoldAt, ')
          ..write('serverCreatedAt: $serverCreatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('serverSaleId: $serverSaleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    businessId,
    branchId,
    shiftId,
    cashierId,
    customerId,
    idempotencyKey,
    invoiceNumber,
    subtotal,
    discountTotal,
    taxTotal,
    grandTotal,
    amountPaid,
    changeDue,
    status,
    syncStatus,
    note,
    rpcPayload,
    capturedAt,
    createdAt,
    serverSoldAt,
    serverCreatedAt,
    syncedAt,
    serverSaleId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.shiftId == this.shiftId &&
          other.cashierId == this.cashierId &&
          other.customerId == this.customerId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.invoiceNumber == this.invoiceNumber &&
          other.subtotal == this.subtotal &&
          other.discountTotal == this.discountTotal &&
          other.taxTotal == this.taxTotal &&
          other.grandTotal == this.grandTotal &&
          other.amountPaid == this.amountPaid &&
          other.changeDue == this.changeDue &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.note == this.note &&
          other.rpcPayload == this.rpcPayload &&
          other.capturedAt == this.capturedAt &&
          other.createdAt == this.createdAt &&
          other.serverSoldAt == this.serverSoldAt &&
          other.serverCreatedAt == this.serverCreatedAt &&
          other.syncedAt == this.syncedAt &&
          other.serverSaleId == this.serverSaleId);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<String> id;
  final Value<String> businessId;
  final Value<String> branchId;
  final Value<String> shiftId;
  final Value<String> cashierId;
  final Value<String?> customerId;
  final Value<String> idempotencyKey;
  final Value<String?> invoiceNumber;
  final Value<String> subtotal;
  final Value<String> discountTotal;
  final Value<String> taxTotal;
  final Value<String> grandTotal;
  final Value<String> amountPaid;
  final Value<String> changeDue;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<String?> note;
  final Value<String> rpcPayload;
  final Value<DateTime> capturedAt;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> serverSoldAt;
  final Value<DateTime?> serverCreatedAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> serverSaleId;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.taxTotal = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.amountPaid = const Value.absent(),
    this.changeDue = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.note = const Value.absent(),
    this.rpcPayload = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.serverSoldAt = const Value.absent(),
    this.serverCreatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.serverSaleId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required String businessId,
    required String branchId,
    required String shiftId,
    required String cashierId,
    this.customerId = const Value.absent(),
    required String idempotencyKey,
    this.invoiceNumber = const Value.absent(),
    required String subtotal,
    required String discountTotal,
    required String taxTotal,
    required String grandTotal,
    required String amountPaid,
    required String changeDue,
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.note = const Value.absent(),
    required String rpcPayload,
    required DateTime capturedAt,
    this.createdAt = const Value.absent(),
    this.serverSoldAt = const Value.absent(),
    this.serverCreatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.serverSaleId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessId = Value(businessId),
       branchId = Value(branchId),
       shiftId = Value(shiftId),
       cashierId = Value(cashierId),
       idempotencyKey = Value(idempotencyKey),
       subtotal = Value(subtotal),
       discountTotal = Value(discountTotal),
       taxTotal = Value(taxTotal),
       grandTotal = Value(grandTotal),
       amountPaid = Value(amountPaid),
       changeDue = Value(changeDue),
       rpcPayload = Value(rpcPayload),
       capturedAt = Value(capturedAt);
  static Insertable<Order> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? shiftId,
    Expression<String>? cashierId,
    Expression<String>? customerId,
    Expression<String>? idempotencyKey,
    Expression<String>? invoiceNumber,
    Expression<String>? subtotal,
    Expression<String>? discountTotal,
    Expression<String>? taxTotal,
    Expression<String>? grandTotal,
    Expression<String>? amountPaid,
    Expression<String>? changeDue,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<String>? note,
    Expression<String>? rpcPayload,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? serverSoldAt,
    Expression<DateTime>? serverCreatedAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? serverSaleId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (shiftId != null) 'shift_id': shiftId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (customerId != null) 'customer_id': customerId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountTotal != null) 'discount_total': discountTotal,
      if (taxTotal != null) 'tax_total': taxTotal,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (amountPaid != null) 'amount_paid': amountPaid,
      if (changeDue != null) 'change_due': changeDue,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (note != null) 'note': note,
      if (rpcPayload != null) 'rpc_payload': rpcPayload,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (serverSoldAt != null) 'server_sold_at': serverSoldAt,
      if (serverCreatedAt != null) 'server_created_at': serverCreatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (serverSaleId != null) 'server_sale_id': serverSaleId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? businessId,
    Value<String>? branchId,
    Value<String>? shiftId,
    Value<String>? cashierId,
    Value<String?>? customerId,
    Value<String>? idempotencyKey,
    Value<String?>? invoiceNumber,
    Value<String>? subtotal,
    Value<String>? discountTotal,
    Value<String>? taxTotal,
    Value<String>? grandTotal,
    Value<String>? amountPaid,
    Value<String>? changeDue,
    Value<String>? status,
    Value<String>? syncStatus,
    Value<String?>? note,
    Value<String>? rpcPayload,
    Value<DateTime>? capturedAt,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? serverSoldAt,
    Value<DateTime?>? serverCreatedAt,
    Value<DateTime?>? syncedAt,
    Value<String?>? serverSaleId,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      shiftId: shiftId ?? this.shiftId,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      subtotal: subtotal ?? this.subtotal,
      discountTotal: discountTotal ?? this.discountTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      changeDue: changeDue ?? this.changeDue,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      note: note ?? this.note,
      rpcPayload: rpcPayload ?? this.rpcPayload,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      serverSoldAt: serverSoldAt ?? this.serverSoldAt,
      serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      serverSaleId: serverSaleId ?? this.serverSaleId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(subtotal.value);
    }
    if (discountTotal.present) {
      map['discount_total'] = Variable<String>(discountTotal.value);
    }
    if (taxTotal.present) {
      map['tax_total'] = Variable<String>(taxTotal.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<String>(grandTotal.value);
    }
    if (amountPaid.present) {
      map['amount_paid'] = Variable<String>(amountPaid.value);
    }
    if (changeDue.present) {
      map['change_due'] = Variable<String>(changeDue.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rpcPayload.present) {
      map['rpc_payload'] = Variable<String>(rpcPayload.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (serverSoldAt.present) {
      map['server_sold_at'] = Variable<DateTime>(serverSoldAt.value);
    }
    if (serverCreatedAt.present) {
      map['server_created_at'] = Variable<DateTime>(serverCreatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (serverSaleId.present) {
      map['server_sale_id'] = Variable<String>(serverSaleId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('shiftId: $shiftId, ')
          ..write('cashierId: $cashierId, ')
          ..write('customerId: $customerId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('taxTotal: $taxTotal, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('amountPaid: $amountPaid, ')
          ..write('changeDue: $changeDue, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('note: $note, ')
          ..write('rpcPayload: $rpcPayload, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('serverSoldAt: $serverSoldAt, ')
          ..write('serverCreatedAt: $serverCreatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('serverSaleId: $serverSaleId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverItemIdMeta = const VerificationMeta(
    'serverItemId',
  );
  @override
  late final GeneratedColumn<String> serverItemId = GeneratedColumn<String>(
    'server_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameSnapshotMeta = const VerificationMeta(
    'nameSnapshot',
  );
  @override
  late final GeneratedColumn<String> nameSnapshot = GeneratedColumn<String>(
    'name_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuSnapshotMeta = const VerificationMeta(
    'skuSnapshot',
  );
  @override
  late final GeneratedColumn<String> skuSnapshot = GeneratedColumn<String>(
    'sku_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeSnapshotMeta = const VerificationMeta(
    'barcodeSnapshot',
  );
  @override
  late final GeneratedColumn<String> barcodeSnapshot = GeneratedColumn<String>(
    'barcode_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<String> qty = GeneratedColumn<String>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<String> unitPrice = GeneratedColumn<String>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costAtSaleMeta = const VerificationMeta(
    'costAtSale',
  );
  @override
  late final GeneratedColumn<String> costAtSale = GeneratedColumn<String>(
    'cost_at_sale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<String> discount = GeneratedColumn<String>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _taxRateMeta = const VerificationMeta(
    'taxRate',
  );
  @override
  late final GeneratedColumn<String> taxRate = GeneratedColumn<String>(
    'tax_rate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<String> taxAmount = GeneratedColumn<String>(
    'tax_amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<String> lineTotal = GeneratedColumn<String>(
    'line_total',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    productId,
    batchId,
    serverItemId,
    nameSnapshot,
    skuSnapshot,
    barcodeSnapshot,
    qty,
    unitPrice,
    costAtSale,
    discount,
    taxRate,
    taxAmount,
    lineTotal,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('server_item_id')) {
      context.handle(
        _serverItemIdMeta,
        serverItemId.isAcceptableOrUnknown(
          data['server_item_id']!,
          _serverItemIdMeta,
        ),
      );
    }
    if (data.containsKey('name_snapshot')) {
      context.handle(
        _nameSnapshotMeta,
        nameSnapshot.isAcceptableOrUnknown(
          data['name_snapshot']!,
          _nameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameSnapshotMeta);
    }
    if (data.containsKey('sku_snapshot')) {
      context.handle(
        _skuSnapshotMeta,
        skuSnapshot.isAcceptableOrUnknown(
          data['sku_snapshot']!,
          _skuSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('barcode_snapshot')) {
      context.handle(
        _barcodeSnapshotMeta,
        barcodeSnapshot.isAcceptableOrUnknown(
          data['barcode_snapshot']!,
          _barcodeSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('cost_at_sale')) {
      context.handle(
        _costAtSaleMeta,
        costAtSale.isAcceptableOrUnknown(
          data['cost_at_sale']!,
          _costAtSaleMeta,
        ),
      );
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('tax_rate')) {
      context.handle(
        _taxRateMeta,
        taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      serverItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_item_id'],
      ),
      nameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_snapshot'],
      )!,
      skuSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku_snapshot'],
      ),
      barcodeSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode_snapshot'],
      ),
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_price'],
      )!,
      costAtSale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_at_sale'],
      ),
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount'],
      )!,
      taxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_rate'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_amount'],
      ),
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_total'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final String id;
  final String orderId;
  final String productId;
  final String? batchId;
  final String? serverItemId;
  final String nameSnapshot;
  final String? skuSnapshot;
  final String? barcodeSnapshot;
  final String qty;
  final String unitPrice;
  final String? costAtSale;
  final String discount;
  final String taxRate;
  final String? taxAmount;
  final String? lineTotal;
  final DateTime? createdAt;
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.batchId,
    this.serverItemId,
    required this.nameSnapshot,
    this.skuSnapshot,
    this.barcodeSnapshot,
    required this.qty,
    required this.unitPrice,
    this.costAtSale,
    required this.discount,
    required this.taxRate,
    this.taxAmount,
    this.lineTotal,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    if (!nullToAbsent || serverItemId != null) {
      map['server_item_id'] = Variable<String>(serverItemId);
    }
    map['name_snapshot'] = Variable<String>(nameSnapshot);
    if (!nullToAbsent || skuSnapshot != null) {
      map['sku_snapshot'] = Variable<String>(skuSnapshot);
    }
    if (!nullToAbsent || barcodeSnapshot != null) {
      map['barcode_snapshot'] = Variable<String>(barcodeSnapshot);
    }
    map['qty'] = Variable<String>(qty);
    map['unit_price'] = Variable<String>(unitPrice);
    if (!nullToAbsent || costAtSale != null) {
      map['cost_at_sale'] = Variable<String>(costAtSale);
    }
    map['discount'] = Variable<String>(discount);
    map['tax_rate'] = Variable<String>(taxRate);
    if (!nullToAbsent || taxAmount != null) {
      map['tax_amount'] = Variable<String>(taxAmount);
    }
    if (!nullToAbsent || lineTotal != null) {
      map['line_total'] = Variable<String>(lineTotal);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      serverItemId: serverItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverItemId),
      nameSnapshot: Value(nameSnapshot),
      skuSnapshot: skuSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(skuSnapshot),
      barcodeSnapshot: barcodeSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(barcodeSnapshot),
      qty: Value(qty),
      unitPrice: Value(unitPrice),
      costAtSale: costAtSale == null && nullToAbsent
          ? const Value.absent()
          : Value(costAtSale),
      discount: Value(discount),
      taxRate: Value(taxRate),
      taxAmount: taxAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(taxAmount),
      lineTotal: lineTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(lineTotal),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory OrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      productId: serializer.fromJson<String>(json['productId']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      serverItemId: serializer.fromJson<String?>(json['serverItemId']),
      nameSnapshot: serializer.fromJson<String>(json['nameSnapshot']),
      skuSnapshot: serializer.fromJson<String?>(json['skuSnapshot']),
      barcodeSnapshot: serializer.fromJson<String?>(json['barcodeSnapshot']),
      qty: serializer.fromJson<String>(json['qty']),
      unitPrice: serializer.fromJson<String>(json['unitPrice']),
      costAtSale: serializer.fromJson<String?>(json['costAtSale']),
      discount: serializer.fromJson<String>(json['discount']),
      taxRate: serializer.fromJson<String>(json['taxRate']),
      taxAmount: serializer.fromJson<String?>(json['taxAmount']),
      lineTotal: serializer.fromJson<String?>(json['lineTotal']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'productId': serializer.toJson<String>(productId),
      'batchId': serializer.toJson<String?>(batchId),
      'serverItemId': serializer.toJson<String?>(serverItemId),
      'nameSnapshot': serializer.toJson<String>(nameSnapshot),
      'skuSnapshot': serializer.toJson<String?>(skuSnapshot),
      'barcodeSnapshot': serializer.toJson<String?>(barcodeSnapshot),
      'qty': serializer.toJson<String>(qty),
      'unitPrice': serializer.toJson<String>(unitPrice),
      'costAtSale': serializer.toJson<String?>(costAtSale),
      'discount': serializer.toJson<String>(discount),
      'taxRate': serializer.toJson<String>(taxRate),
      'taxAmount': serializer.toJson<String?>(taxAmount),
      'lineTotal': serializer.toJson<String?>(lineTotal),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    Value<String?> batchId = const Value.absent(),
    Value<String?> serverItemId = const Value.absent(),
    String? nameSnapshot,
    Value<String?> skuSnapshot = const Value.absent(),
    Value<String?> barcodeSnapshot = const Value.absent(),
    String? qty,
    String? unitPrice,
    Value<String?> costAtSale = const Value.absent(),
    String? discount,
    String? taxRate,
    Value<String?> taxAmount = const Value.absent(),
    Value<String?> lineTotal = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => OrderItem(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    productId: productId ?? this.productId,
    batchId: batchId.present ? batchId.value : this.batchId,
    serverItemId: serverItemId.present ? serverItemId.value : this.serverItemId,
    nameSnapshot: nameSnapshot ?? this.nameSnapshot,
    skuSnapshot: skuSnapshot.present ? skuSnapshot.value : this.skuSnapshot,
    barcodeSnapshot: barcodeSnapshot.present
        ? barcodeSnapshot.value
        : this.barcodeSnapshot,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
    costAtSale: costAtSale.present ? costAtSale.value : this.costAtSale,
    discount: discount ?? this.discount,
    taxRate: taxRate ?? this.taxRate,
    taxAmount: taxAmount.present ? taxAmount.value : this.taxAmount,
    lineTotal: lineTotal.present ? lineTotal.value : this.lineTotal,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      serverItemId: data.serverItemId.present
          ? data.serverItemId.value
          : this.serverItemId,
      nameSnapshot: data.nameSnapshot.present
          ? data.nameSnapshot.value
          : this.nameSnapshot,
      skuSnapshot: data.skuSnapshot.present
          ? data.skuSnapshot.value
          : this.skuSnapshot,
      barcodeSnapshot: data.barcodeSnapshot.present
          ? data.barcodeSnapshot.value
          : this.barcodeSnapshot,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      costAtSale: data.costAtSale.present
          ? data.costAtSale.value
          : this.costAtSale,
      discount: data.discount.present ? data.discount.value : this.discount,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('batchId: $batchId, ')
          ..write('serverItemId: $serverItemId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('skuSnapshot: $skuSnapshot, ')
          ..write('barcodeSnapshot: $barcodeSnapshot, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costAtSale: $costAtSale, ')
          ..write('discount: $discount, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    productId,
    batchId,
    serverItemId,
    nameSnapshot,
    skuSnapshot,
    barcodeSnapshot,
    qty,
    unitPrice,
    costAtSale,
    discount,
    taxRate,
    taxAmount,
    lineTotal,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.batchId == this.batchId &&
          other.serverItemId == this.serverItemId &&
          other.nameSnapshot == this.nameSnapshot &&
          other.skuSnapshot == this.skuSnapshot &&
          other.barcodeSnapshot == this.barcodeSnapshot &&
          other.qty == this.qty &&
          other.unitPrice == this.unitPrice &&
          other.costAtSale == this.costAtSale &&
          other.discount == this.discount &&
          other.taxRate == this.taxRate &&
          other.taxAmount == this.taxAmount &&
          other.lineTotal == this.lineTotal &&
          other.createdAt == this.createdAt);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> productId;
  final Value<String?> batchId;
  final Value<String?> serverItemId;
  final Value<String> nameSnapshot;
  final Value<String?> skuSnapshot;
  final Value<String?> barcodeSnapshot;
  final Value<String> qty;
  final Value<String> unitPrice;
  final Value<String?> costAtSale;
  final Value<String> discount;
  final Value<String> taxRate;
  final Value<String?> taxAmount;
  final Value<String?> lineTotal;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.serverItemId = const Value.absent(),
    this.nameSnapshot = const Value.absent(),
    this.skuSnapshot = const Value.absent(),
    this.barcodeSnapshot = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.costAtSale = const Value.absent(),
    this.discount = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    required String id,
    required String orderId,
    required String productId,
    this.batchId = const Value.absent(),
    this.serverItemId = const Value.absent(),
    required String nameSnapshot,
    this.skuSnapshot = const Value.absent(),
    this.barcodeSnapshot = const Value.absent(),
    required String qty,
    required String unitPrice,
    this.costAtSale = const Value.absent(),
    this.discount = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       productId = Value(productId),
       nameSnapshot = Value(nameSnapshot),
       qty = Value(qty),
       unitPrice = Value(unitPrice);
  static Insertable<OrderItem> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? productId,
    Expression<String>? batchId,
    Expression<String>? serverItemId,
    Expression<String>? nameSnapshot,
    Expression<String>? skuSnapshot,
    Expression<String>? barcodeSnapshot,
    Expression<String>? qty,
    Expression<String>? unitPrice,
    Expression<String>? costAtSale,
    Expression<String>? discount,
    Expression<String>? taxRate,
    Expression<String>? taxAmount,
    Expression<String>? lineTotal,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (batchId != null) 'batch_id': batchId,
      if (serverItemId != null) 'server_item_id': serverItemId,
      if (nameSnapshot != null) 'name_snapshot': nameSnapshot,
      if (skuSnapshot != null) 'sku_snapshot': skuSnapshot,
      if (barcodeSnapshot != null) 'barcode_snapshot': barcodeSnapshot,
      if (qty != null) 'qty': qty,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (costAtSale != null) 'cost_at_sale': costAtSale,
      if (discount != null) 'discount': discount,
      if (taxRate != null) 'tax_rate': taxRate,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (lineTotal != null) 'line_total': lineTotal,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? productId,
    Value<String?>? batchId,
    Value<String?>? serverItemId,
    Value<String>? nameSnapshot,
    Value<String?>? skuSnapshot,
    Value<String?>? barcodeSnapshot,
    Value<String>? qty,
    Value<String>? unitPrice,
    Value<String?>? costAtSale,
    Value<String>? discount,
    Value<String>? taxRate,
    Value<String?>? taxAmount,
    Value<String?>? lineTotal,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      batchId: batchId ?? this.batchId,
      serverItemId: serverItemId ?? this.serverItemId,
      nameSnapshot: nameSnapshot ?? this.nameSnapshot,
      skuSnapshot: skuSnapshot ?? this.skuSnapshot,
      barcodeSnapshot: barcodeSnapshot ?? this.barcodeSnapshot,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      costAtSale: costAtSale ?? this.costAtSale,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (serverItemId.present) {
      map['server_item_id'] = Variable<String>(serverItemId.value);
    }
    if (nameSnapshot.present) {
      map['name_snapshot'] = Variable<String>(nameSnapshot.value);
    }
    if (skuSnapshot.present) {
      map['sku_snapshot'] = Variable<String>(skuSnapshot.value);
    }
    if (barcodeSnapshot.present) {
      map['barcode_snapshot'] = Variable<String>(barcodeSnapshot.value);
    }
    if (qty.present) {
      map['qty'] = Variable<String>(qty.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(unitPrice.value);
    }
    if (costAtSale.present) {
      map['cost_at_sale'] = Variable<String>(costAtSale.value);
    }
    if (discount.present) {
      map['discount'] = Variable<String>(discount.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<String>(taxRate.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<String>(taxAmount.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<String>(lineTotal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('batchId: $batchId, ')
          ..write('serverItemId: $serverItemId, ')
          ..write('nameSnapshot: $nameSnapshot, ')
          ..write('skuSnapshot: $skuSnapshot, ')
          ..write('barcodeSnapshot: $barcodeSnapshot, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costAtSale: $costAtSale, ')
          ..write('discount: $discount, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id)',
    ),
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierIdMeta = const VerificationMeta(
    'cashierId',
  );
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
    'cashier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idempotencyKey,
    orderId,
    businessId,
    cashierId,
    payload,
    status,
    attempts,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(
        _cashierIdMeta,
        cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idempotencyKey};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      cashierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String idempotencyKey;
  final String orderId;
  final String businessId;
  final String cashierId;
  final String payload;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueData({
    required this.idempotencyKey,
    required this.orderId,
    required this.businessId,
    required this.cashierId,
    required this.payload,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['order_id'] = Variable<String>(orderId);
    map['business_id'] = Variable<String>(businessId);
    map['cashier_id'] = Variable<String>(cashierId);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      idempotencyKey: Value(idempotencyKey),
      orderId: Value(orderId),
      businessId: Value(businessId),
      cashierId: Value(cashierId),
      payload: Value(payload),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      orderId: serializer.fromJson<String>(json['orderId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'orderId': serializer.toJson<String>(orderId),
      'businessId': serializer.toJson<String>(businessId),
      'cashierId': serializer.toJson<String>(cashierId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueData copyWith({
    String? idempotencyKey,
    String? orderId,
    String? businessId,
    String? cashierId,
    String? payload,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncQueueData(
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    orderId: orderId ?? this.orderId,
    businessId: businessId ?? this.businessId,
    cashierId: cashierId ?? this.cashierId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('orderId: $orderId, ')
          ..write('businessId: $businessId, ')
          ..write('cashierId: $cashierId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idempotencyKey,
    orderId,
    businessId,
    cashierId,
    payload,
    status,
    attempts,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.idempotencyKey == this.idempotencyKey &&
          other.orderId == this.orderId &&
          other.businessId == this.businessId &&
          other.cashierId == this.cashierId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> idempotencyKey;
  final Value<String> orderId;
  final Value<String> businessId;
  final Value<String> cashierId;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.idempotencyKey = const Value.absent(),
    this.orderId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String idempotencyKey,
    required String orderId,
    required String businessId,
    required String cashierId,
    required String payload,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       orderId = Value(orderId),
       businessId = Value(businessId),
       cashierId = Value(cashierId),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? idempotencyKey,
    Expression<String>? orderId,
    Expression<String>? businessId,
    Expression<String>? cashierId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (orderId != null) 'order_id': orderId,
      if (businessId != null) 'business_id': businessId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? idempotencyKey,
    Value<String>? orderId,
    Value<String>? businessId,
    Value<String>? cashierId,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      orderId: orderId ?? this.orderId,
      businessId: businessId ?? this.businessId,
      cashierId: cashierId ?? this.cashierId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('orderId: $orderId, ')
          ..write('businessId: $businessId, ')
          ..write('cashierId: $cashierId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogCacheStatesTable extends CatalogCacheStates
    with TableInfo<$CatalogCacheStatesTable, CatalogCacheState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogCacheStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [businessId, branchId, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_cache_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogCacheState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId, branchId};
  @override
  CatalogCacheState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogCacheState(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $CatalogCacheStatesTable createAlias(String alias) {
    return $CatalogCacheStatesTable(attachedDatabase, alias);
  }
}

class CatalogCacheState extends DataClass
    implements Insertable<CatalogCacheState> {
  final String businessId;
  final String branchId;
  final DateTime syncedAt;
  const CatalogCacheState({
    required this.businessId,
    required this.branchId,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['branch_id'] = Variable<String>(branchId);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CatalogCacheStatesCompanion toCompanion(bool nullToAbsent) {
    return CatalogCacheStatesCompanion(
      businessId: Value(businessId),
      branchId: Value(branchId),
      syncedAt: Value(syncedAt),
    );
  }

  factory CatalogCacheState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogCacheState(
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String>(branchId),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CatalogCacheState copyWith({
    String? businessId,
    String? branchId,
    DateTime? syncedAt,
  }) => CatalogCacheState(
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CatalogCacheState copyWithCompanion(CatalogCacheStatesCompanion data) {
    return CatalogCacheState(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheState(')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(businessId, branchId, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogCacheState &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.syncedAt == this.syncedAt);
}

class CatalogCacheStatesCompanion extends UpdateCompanion<CatalogCacheState> {
  final Value<String> businessId;
  final Value<String> branchId;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CatalogCacheStatesCompanion({
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogCacheStatesCompanion.insert({
    required String businessId,
    required String branchId,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       branchId = Value(branchId),
       syncedAt = Value(syncedAt);
  static Insertable<CatalogCacheState> custom({
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogCacheStatesCompanion copyWith({
    Value<String>? businessId,
    Value<String>? branchId,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return CatalogCacheStatesCompanion(
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCacheStatesCompanion(')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PosShiftsTable extends PosShifts
    with TableInfo<$PosShiftsTable, PosShift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PosShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingFloatMeta = const VerificationMeta(
    'openingFloat',
  );
  @override
  late final GeneratedColumn<String> openingFloat = GeneratedColumn<String>(
    'opening_float',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingCountedMeta = const VerificationMeta(
    'closingCounted',
  );
  @override
  late final GeneratedColumn<String> closingCounted = GeneratedColumn<String>(
    'closing_counted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedCashMeta = const VerificationMeta(
    'expectedCash',
  );
  @override
  late final GeneratedColumn<String> expectedCash = GeneratedColumn<String>(
    'expected_cash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _varianceMeta = const VerificationMeta(
    'variance',
  );
  @override
  late final GeneratedColumn<String> variance = GeneratedColumn<String>(
    'variance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _varianceReasonMeta = const VerificationMeta(
    'varianceReason',
  );
  @override
  late final GeneratedColumn<String> varianceReason = GeneratedColumn<String>(
    'variance_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    businessId,
    branchId,
    status,
    openingFloat,
    closingCounted,
    expectedCash,
    variance,
    varianceReason,
    openedAt,
    closedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pos_shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PosShift> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('opening_float')) {
      context.handle(
        _openingFloatMeta,
        openingFloat.isAcceptableOrUnknown(
          data['opening_float']!,
          _openingFloatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingFloatMeta);
    }
    if (data.containsKey('closing_counted')) {
      context.handle(
        _closingCountedMeta,
        closingCounted.isAcceptableOrUnknown(
          data['closing_counted']!,
          _closingCountedMeta,
        ),
      );
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
        _expectedCashMeta,
        expectedCash.isAcceptableOrUnknown(
          data['expected_cash']!,
          _expectedCashMeta,
        ),
      );
    }
    if (data.containsKey('variance')) {
      context.handle(
        _varianceMeta,
        variance.isAcceptableOrUnknown(data['variance']!, _varianceMeta),
      );
    }
    if (data.containsKey('variance_reason')) {
      context.handle(
        _varianceReasonMeta,
        varianceReason.isAcceptableOrUnknown(
          data['variance_reason']!,
          _varianceReasonMeta,
        ),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PosShift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PosShift(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openingFloat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_float'],
      )!,
      closingCounted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closing_counted'],
      ),
      expectedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_cash'],
      ),
      variance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variance'],
      ),
      varianceReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variance_reason'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $PosShiftsTable createAlias(String alias) {
    return $PosShiftsTable(attachedDatabase, alias);
  }
}

class PosShift extends DataClass implements Insertable<PosShift> {
  final String id;
  final String profileId;
  final String businessId;
  final String branchId;
  final String status;
  final String openingFloat;
  final String? closingCounted;
  final String? expectedCash;
  final String? variance;
  final String? varianceReason;
  final DateTime openedAt;
  final DateTime? closedAt;
  final DateTime cachedAt;
  const PosShift({
    required this.id,
    required this.profileId,
    required this.businessId,
    required this.branchId,
    required this.status,
    required this.openingFloat,
    this.closingCounted,
    this.expectedCash,
    this.variance,
    this.varianceReason,
    required this.openedAt,
    this.closedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['business_id'] = Variable<String>(businessId);
    map['branch_id'] = Variable<String>(branchId);
    map['status'] = Variable<String>(status);
    map['opening_float'] = Variable<String>(openingFloat);
    if (!nullToAbsent || closingCounted != null) {
      map['closing_counted'] = Variable<String>(closingCounted);
    }
    if (!nullToAbsent || expectedCash != null) {
      map['expected_cash'] = Variable<String>(expectedCash);
    }
    if (!nullToAbsent || variance != null) {
      map['variance'] = Variable<String>(variance);
    }
    if (!nullToAbsent || varianceReason != null) {
      map['variance_reason'] = Variable<String>(varianceReason);
    }
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  PosShiftsCompanion toCompanion(bool nullToAbsent) {
    return PosShiftsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      businessId: Value(businessId),
      branchId: Value(branchId),
      status: Value(status),
      openingFloat: Value(openingFloat),
      closingCounted: closingCounted == null && nullToAbsent
          ? const Value.absent()
          : Value(closingCounted),
      expectedCash: expectedCash == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCash),
      variance: variance == null && nullToAbsent
          ? const Value.absent()
          : Value(variance),
      varianceReason: varianceReason == null && nullToAbsent
          ? const Value.absent()
          : Value(varianceReason),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory PosShift.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PosShift(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      status: serializer.fromJson<String>(json['status']),
      openingFloat: serializer.fromJson<String>(json['openingFloat']),
      closingCounted: serializer.fromJson<String?>(json['closingCounted']),
      expectedCash: serializer.fromJson<String?>(json['expectedCash']),
      variance: serializer.fromJson<String?>(json['variance']),
      varianceReason: serializer.fromJson<String?>(json['varianceReason']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'businessId': serializer.toJson<String>(businessId),
      'branchId': serializer.toJson<String>(branchId),
      'status': serializer.toJson<String>(status),
      'openingFloat': serializer.toJson<String>(openingFloat),
      'closingCounted': serializer.toJson<String?>(closingCounted),
      'expectedCash': serializer.toJson<String?>(expectedCash),
      'variance': serializer.toJson<String?>(variance),
      'varianceReason': serializer.toJson<String?>(varianceReason),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  PosShift copyWith({
    String? id,
    String? profileId,
    String? businessId,
    String? branchId,
    String? status,
    String? openingFloat,
    Value<String?> closingCounted = const Value.absent(),
    Value<String?> expectedCash = const Value.absent(),
    Value<String?> variance = const Value.absent(),
    Value<String?> varianceReason = const Value.absent(),
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    DateTime? cachedAt,
  }) => PosShift(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    businessId: businessId ?? this.businessId,
    branchId: branchId ?? this.branchId,
    status: status ?? this.status,
    openingFloat: openingFloat ?? this.openingFloat,
    closingCounted: closingCounted.present
        ? closingCounted.value
        : this.closingCounted,
    expectedCash: expectedCash.present ? expectedCash.value : this.expectedCash,
    variance: variance.present ? variance.value : this.variance,
    varianceReason: varianceReason.present
        ? varianceReason.value
        : this.varianceReason,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  PosShift copyWithCompanion(PosShiftsCompanion data) {
    return PosShift(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      status: data.status.present ? data.status.value : this.status,
      openingFloat: data.openingFloat.present
          ? data.openingFloat.value
          : this.openingFloat,
      closingCounted: data.closingCounted.present
          ? data.closingCounted.value
          : this.closingCounted,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      variance: data.variance.present ? data.variance.value : this.variance,
      varianceReason: data.varianceReason.present
          ? data.varianceReason.value
          : this.varianceReason,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PosShift(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('status: $status, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('closingCounted: $closingCounted, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('variance: $variance, ')
          ..write('varianceReason: $varianceReason, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    businessId,
    branchId,
    status,
    openingFloat,
    closingCounted,
    expectedCash,
    variance,
    varianceReason,
    openedAt,
    closedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PosShift &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.businessId == this.businessId &&
          other.branchId == this.branchId &&
          other.status == this.status &&
          other.openingFloat == this.openingFloat &&
          other.closingCounted == this.closingCounted &&
          other.expectedCash == this.expectedCash &&
          other.variance == this.variance &&
          other.varianceReason == this.varianceReason &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.cachedAt == this.cachedAt);
}

class PosShiftsCompanion extends UpdateCompanion<PosShift> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> businessId;
  final Value<String> branchId;
  final Value<String> status;
  final Value<String> openingFloat;
  final Value<String?> closingCounted;
  final Value<String?> expectedCash;
  final Value<String?> variance;
  final Value<String?> varianceReason;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const PosShiftsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.status = const Value.absent(),
    this.openingFloat = const Value.absent(),
    this.closingCounted = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.variance = const Value.absent(),
    this.varianceReason = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PosShiftsCompanion.insert({
    required String id,
    required String profileId,
    required String businessId,
    required String branchId,
    required String status,
    required String openingFloat,
    this.closingCounted = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.variance = const Value.absent(),
    this.varianceReason = const Value.absent(),
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       businessId = Value(businessId),
       branchId = Value(branchId),
       status = Value(status),
       openingFloat = Value(openingFloat),
       openedAt = Value(openedAt),
       cachedAt = Value(cachedAt);
  static Insertable<PosShift> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? businessId,
    Expression<String>? branchId,
    Expression<String>? status,
    Expression<String>? openingFloat,
    Expression<String>? closingCounted,
    Expression<String>? expectedCash,
    Expression<String>? variance,
    Expression<String>? varianceReason,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (businessId != null) 'business_id': businessId,
      if (branchId != null) 'branch_id': branchId,
      if (status != null) 'status': status,
      if (openingFloat != null) 'opening_float': openingFloat,
      if (closingCounted != null) 'closing_counted': closingCounted,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (variance != null) 'variance': variance,
      if (varianceReason != null) 'variance_reason': varianceReason,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PosShiftsCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? businessId,
    Value<String>? branchId,
    Value<String>? status,
    Value<String>? openingFloat,
    Value<String?>? closingCounted,
    Value<String?>? expectedCash,
    Value<String?>? variance,
    Value<String?>? varianceReason,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return PosShiftsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      status: status ?? this.status,
      openingFloat: openingFloat ?? this.openingFloat,
      closingCounted: closingCounted ?? this.closingCounted,
      expectedCash: expectedCash ?? this.expectedCash,
      variance: variance ?? this.variance,
      varianceReason: varianceReason ?? this.varianceReason,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openingFloat.present) {
      map['opening_float'] = Variable<String>(openingFloat.value);
    }
    if (closingCounted.present) {
      map['closing_counted'] = Variable<String>(closingCounted.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<String>(expectedCash.value);
    }
    if (variance.present) {
      map['variance'] = Variable<String>(variance.value);
    }
    if (varianceReason.present) {
      map['variance_reason'] = Variable<String>(varianceReason.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PosShiftsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('businessId: $businessId, ')
          ..write('branchId: $branchId, ')
          ..write('status: $status, ')
          ..write('openingFloat: $openingFloat, ')
          ..write('closingCounted: $closingCounted, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('variance: $variance, ')
          ..write('varianceReason: $varianceReason, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  $OfflineDatabaseManager get managers => $OfflineDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CatalogCacheStatesTable catalogCacheStates =
      $CatalogCacheStatesTable(this);
  late final $PosShiftsTable posShifts = $PosShiftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    products,
    orders,
    orderItems,
    syncQueue,
    catalogCacheStates,
    posShifts,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String businessId,
  required String name,
  Value<String?> parentId,
  Value<String> status,
  Value<DateTime?> createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> businessId,
  Value<String> name,
  Value<String?> parentId,
  Value<String> status,
  Value<DateTime?> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$OfflineDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$OfflineDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            Category,
            BaseReferences<_$OfflineDatabase, $CategoriesTable, Category>,
          ),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$OfflineDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                businessId: businessId,
                name: name,
                parentId: parentId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                parentId: parentId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  BaseReferences<_$OfflineDatabase, $CategoriesTable, Category>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$OfflineDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String businessId,
  required String branchId,
  required String name,
  Value<String?> sku,
  Value<String?> barcode,
  Value<String?> categoryId,
  Value<String?> brandId,
  Value<String?> unitId,
  required String sellingPrice,
  required String taxRate,
  required bool isWeightBased,
  required bool trackBatch,
  required String reorderLevel,
  required String stock,
  required String status,
  Value<String?> imageUrl,
  Value<String?> description,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> businessId,
  Value<String> branchId,
  Value<String> name,
  Value<String?> sku,
  Value<String?> barcode,
  Value<String?> categoryId,
  Value<String?> brandId,
  Value<String?> unitId,
  Value<String> sellingPrice,
  Value<String> taxRate,
  Value<bool> isWeightBased,
  Value<bool> trackBatch,
  Value<String> reorderLevel,
  Value<String> stock,
  Value<String> status,
  Value<String?> imageUrl,
  Value<String?> description,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$OfflineDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandId => $composableBuilder(
    column: $table.brandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWeightBased => $composableBuilder(
    column: $table.isWeightBased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackBatch => $composableBuilder(
    column: $table.trackBatch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandId => $composableBuilder(
    column: $table.brandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitId => $composableBuilder(
    column: $table.unitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWeightBased => $composableBuilder(
    column: $table.isWeightBased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackBatch => $composableBuilder(
    column: $table.trackBatch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brandId =>
      $composableBuilder(column: $table.brandId, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get sellingPrice => $composableBuilder(
    column: $table.sellingPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<bool> get isWeightBased => $composableBuilder(
    column: $table.isWeightBased,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackBatch => $composableBuilder(
    column: $table.trackBatch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$OfflineDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$OfflineDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> brandId = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                Value<String> sellingPrice = const Value.absent(),
                Value<String> taxRate = const Value.absent(),
                Value<bool> isWeightBased = const Value.absent(),
                Value<bool> trackBatch = const Value.absent(),
                Value<String> reorderLevel = const Value.absent(),
                Value<String> stock = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                name: name,
                sku: sku,
                barcode: barcode,
                categoryId: categoryId,
                brandId: brandId,
                unitId: unitId,
                sellingPrice: sellingPrice,
                taxRate: taxRate,
                isWeightBased: isWeightBased,
                trackBatch: trackBatch,
                reorderLevel: reorderLevel,
                stock: stock,
                status: status,
                imageUrl: imageUrl,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String branchId,
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> brandId = const Value.absent(),
                Value<String?> unitId = const Value.absent(),
                required String sellingPrice,
                required String taxRate,
                required bool isWeightBased,
                required bool trackBatch,
                required String reorderLevel,
                required String stock,
                required String status,
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                name: name,
                sku: sku,
                barcode: barcode,
                categoryId: categoryId,
                brandId: brandId,
                unitId: unitId,
                sellingPrice: sellingPrice,
                taxRate: taxRate,
                isWeightBased: isWeightBased,
                trackBatch: trackBatch,
                reorderLevel: reorderLevel,
                stock: stock,
                status: status,
                imageUrl: imageUrl,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  BaseReferences<_$OfflineDatabase, $ProductsTable, Product>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$OfflineDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required String businessId,
  required String branchId,
  required String shiftId,
  required String cashierId,
  Value<String?> customerId,
  required String idempotencyKey,
  Value<String?> invoiceNumber,
  required String subtotal,
  required String discountTotal,
  required String taxTotal,
  required String grandTotal,
  required String amountPaid,
  required String changeDue,
  Value<String> status,
  Value<String> syncStatus,
  Value<String?> note,
  required String rpcPayload,
  required DateTime capturedAt,
  Value<DateTime?> createdAt,
  Value<DateTime?> serverSoldAt,
  Value<DateTime?> serverCreatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> serverSaleId,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<String> businessId,
  Value<String> branchId,
  Value<String> shiftId,
  Value<String> cashierId,
  Value<String?> customerId,
  Value<String> idempotencyKey,
  Value<String?> invoiceNumber,
  Value<String> subtotal,
  Value<String> discountTotal,
  Value<String> taxTotal,
  Value<String> grandTotal,
  Value<String> amountPaid,
  Value<String> changeDue,
  Value<String> status,
  Value<String> syncStatus,
  Value<String?> note,
  Value<String> rpcPayload,
  Value<DateTime> capturedAt,
  Value<DateTime?> createdAt,
  Value<DateTime?> serverSoldAt,
  Value<DateTime?> serverCreatedAt,
  Value<DateTime?> syncedAt,
  Value<String?> serverSaleId,
  Value<int> rowid,
});

final class $$OrdersTableReferences
    extends BaseReferences<_$OfflineDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
  _orderItemsRefsTable(_$OfflineDatabase db) => MultiTypedResultKey.fromTable(
    db.orderItems,
    aliasName: 'orders__id__order_items__order_id',
  );

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager(
      $_db,
      $_db.orderItems,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyncQueueTable, List<SyncQueueData>>
  _syncQueueRefsTable(_$OfflineDatabase db) => MultiTypedResultKey.fromTable(
    db.syncQueue,
    aliasName: 'orders__id__sync_queue__order_id',
  );

  $$SyncQueueTableProcessedTableManager get syncQueueRefs {
    final manager = $$SyncQueueTableTableManager(
      $_db,
      $_db.syncQueue,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncQueueRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$OfflineDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxTotal => $composableBuilder(
    column: $table.taxTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountPaid => $composableBuilder(
    column: $table.amountPaid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeDue => $composableBuilder(
    column: $table.changeDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rpcPayload => $composableBuilder(
    column: $table.rpcPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverSoldAt => $composableBuilder(
    column: $table.serverSoldAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverCreatedAt => $composableBuilder(
    column: $table.serverCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverSaleId => $composableBuilder(
    column: $table.serverSaleId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> orderItemsRefs(
    Expression<bool> Function($$OrderItemsTableFilterComposer f) f,
  ) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableFilterComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syncQueueRefs(
    Expression<bool> Function($$SyncQueueTableFilterComposer f) f,
  ) {
    final $$SyncQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncQueue,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncQueueTableFilterComposer(
            $db: $db,
            $table: $db.syncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$OfflineDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxTotal => $composableBuilder(
    column: $table.taxTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountPaid => $composableBuilder(
    column: $table.amountPaid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeDue => $composableBuilder(
    column: $table.changeDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rpcPayload => $composableBuilder(
    column: $table.rpcPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverSoldAt => $composableBuilder(
    column: $table.serverSoldAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverCreatedAt => $composableBuilder(
    column: $table.serverCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverSaleId => $composableBuilder(
    column: $table.serverSaleId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<String> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxTotal =>
      $composableBuilder(column: $table.taxTotal, builder: (column) => column);

  GeneratedColumn<String> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get amountPaid => $composableBuilder(
    column: $table.amountPaid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get changeDue =>
      $composableBuilder(column: $table.changeDue, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get rpcPayload => $composableBuilder(
    column: $table.rpcPayload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverSoldAt => $composableBuilder(
    column: $table.serverSoldAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverCreatedAt => $composableBuilder(
    column: $table.serverCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get serverSaleId => $composableBuilder(
    column: $table.serverSaleId,
    builder: (column) => column,
  );

  Expression<T> orderItemsRefs<T extends Object>(
    Expression<T> Function($$OrderItemsTableAnnotationComposer a) f,
  ) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syncQueueRefs<T extends Object>(
    Expression<T> Function($$SyncQueueTableAnnotationComposer a) f,
  ) {
    final $$SyncQueueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncQueue,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncQueueTableAnnotationComposer(
            $db: $db,
            $table: $db.syncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $OrdersTable,
          Order,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (Order, $$OrdersTableReferences),
          Order,
          PrefetchHooks Function({bool orderItemsRefs, bool syncQueueRefs})
        > {
  $$OrdersTableTableManager(_$OfflineDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String> subtotal = const Value.absent(),
                Value<String> discountTotal = const Value.absent(),
                Value<String> taxTotal = const Value.absent(),
                Value<String> grandTotal = const Value.absent(),
                Value<String> amountPaid = const Value.absent(),
                Value<String> changeDue = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> rpcPayload = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> serverSoldAt = const Value.absent(),
                Value<DateTime?> serverCreatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> serverSaleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                businessId: businessId,
                branchId: branchId,
                shiftId: shiftId,
                cashierId: cashierId,
                customerId: customerId,
                idempotencyKey: idempotencyKey,
                invoiceNumber: invoiceNumber,
                subtotal: subtotal,
                discountTotal: discountTotal,
                taxTotal: taxTotal,
                grandTotal: grandTotal,
                amountPaid: amountPaid,
                changeDue: changeDue,
                status: status,
                syncStatus: syncStatus,
                note: note,
                rpcPayload: rpcPayload,
                capturedAt: capturedAt,
                createdAt: createdAt,
                serverSoldAt: serverSoldAt,
                serverCreatedAt: serverCreatedAt,
                syncedAt: syncedAt,
                serverSaleId: serverSaleId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessId,
                required String branchId,
                required String shiftId,
                required String cashierId,
                Value<String?> customerId = const Value.absent(),
                required String idempotencyKey,
                Value<String?> invoiceNumber = const Value.absent(),
                required String subtotal,
                required String discountTotal,
                required String taxTotal,
                required String grandTotal,
                required String amountPaid,
                required String changeDue,
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String rpcPayload,
                required DateTime capturedAt,
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> serverSoldAt = const Value.absent(),
                Value<DateTime?> serverCreatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<String?> serverSaleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                businessId: businessId,
                branchId: branchId,
                shiftId: shiftId,
                cashierId: cashierId,
                customerId: customerId,
                idempotencyKey: idempotencyKey,
                invoiceNumber: invoiceNumber,
                subtotal: subtotal,
                discountTotal: discountTotal,
                taxTotal: taxTotal,
                grandTotal: grandTotal,
                amountPaid: amountPaid,
                changeDue: changeDue,
                status: status,
                syncStatus: syncStatus,
                note: note,
                rpcPayload: rpcPayload,
                capturedAt: capturedAt,
                createdAt: createdAt,
                serverSoldAt: serverSoldAt,
                serverCreatedAt: serverCreatedAt,
                syncedAt: syncedAt,
                serverSaleId: serverSaleId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrdersTable, Order>(table),
                  $$OrdersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({orderItemsRefs = false, syncQueueRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (orderItemsRefs) db.orderItems,
                    if (syncQueueRefs) db.syncQueue,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (orderItemsRefs)
                        await $_getPrefetchedData<
                          Order,
                          $OrdersTable,
                          OrderItem
                        >(
                          currentTable: table,
                          referencedTable: $$OrdersTableReferences
                              ._orderItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrdersTableReferences(
                                db,
                                table,
                                p0,
                              ).orderItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.orderId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syncQueueRefs)
                        await $_getPrefetchedData<
                          Order,
                          $OrdersTable,
                          SyncQueueData
                        >(
                          currentTable: table,
                          referencedTable: $$OrdersTableReferences
                              ._syncQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrdersTableReferences(
                                db,
                                table,
                                p0,
                              ).syncQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.orderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $OrdersTable,
      Order,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (Order, $$OrdersTableReferences),
      Order,
      PrefetchHooks Function({bool orderItemsRefs, bool syncQueueRefs})
    >;
typedef $$OrderItemsTableCreateCompanionBuilder = OrderItemsCompanion Function({
  required String id,
  required String orderId,
  required String productId,
  Value<String?> batchId,
  Value<String?> serverItemId,
  required String nameSnapshot,
  Value<String?> skuSnapshot,
  Value<String?> barcodeSnapshot,
  required String qty,
  required String unitPrice,
  Value<String?> costAtSale,
  Value<String> discount,
  Value<String> taxRate,
  Value<String?> taxAmount,
  Value<String?> lineTotal,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$OrderItemsTableUpdateCompanionBuilder = OrderItemsCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> productId,
  Value<String?> batchId,
  Value<String?> serverItemId,
  Value<String> nameSnapshot,
  Value<String?> skuSnapshot,
  Value<String?> barcodeSnapshot,
  Value<String> qty,
  Value<String> unitPrice,
  Value<String?> costAtSale,
  Value<String> discount,
  Value<String> taxRate,
  Value<String?> taxAmount,
  Value<String?> lineTotal,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

final class $$OrderItemsTableReferences
    extends BaseReferences<_$OfflineDatabase, $OrderItemsTable, OrderItem> {
  $$OrderItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$OfflineDatabase db) =>
      db.orders.createAlias('order_items__order_id__orders__id');

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrderItemsTableFilterComposer
    extends Composer<_$OfflineDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverItemId => $composableBuilder(
    column: $table.serverItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skuSnapshot => $composableBuilder(
    column: $table.skuSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcodeSnapshot => $composableBuilder(
    column: $table.barcodeSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costAtSale => $composableBuilder(
    column: $table.costAtSale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverItemId => $composableBuilder(
    column: $table.serverItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skuSnapshot => $composableBuilder(
    column: $table.skuSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcodeSnapshot => $composableBuilder(
    column: $table.barcodeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costAtSale => $composableBuilder(
    column: $table.costAtSale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxRate => $composableBuilder(
    column: $table.taxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get serverItemId => $composableBuilder(
    column: $table.serverItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameSnapshot => $composableBuilder(
    column: $table.nameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skuSnapshot => $composableBuilder(
    column: $table.skuSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcodeSnapshot => $composableBuilder(
    column: $table.barcodeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get costAtSale => $composableBuilder(
    column: $table.costAtSale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<String> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<String> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $OrderItemsTable,
          OrderItem,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (OrderItem, $$OrderItemsTableReferences),
          OrderItem,
          PrefetchHooks Function({bool orderId})
        > {
  $$OrderItemsTableTableManager(_$OfflineDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> serverItemId = const Value.absent(),
                Value<String> nameSnapshot = const Value.absent(),
                Value<String?> skuSnapshot = const Value.absent(),
                Value<String?> barcodeSnapshot = const Value.absent(),
                Value<String> qty = const Value.absent(),
                Value<String> unitPrice = const Value.absent(),
                Value<String?> costAtSale = const Value.absent(),
                Value<String> discount = const Value.absent(),
                Value<String> taxRate = const Value.absent(),
                Value<String?> taxAmount = const Value.absent(),
                Value<String?> lineTotal = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                orderId: orderId,
                productId: productId,
                batchId: batchId,
                serverItemId: serverItemId,
                nameSnapshot: nameSnapshot,
                skuSnapshot: skuSnapshot,
                barcodeSnapshot: barcodeSnapshot,
                qty: qty,
                unitPrice: unitPrice,
                costAtSale: costAtSale,
                discount: discount,
                taxRate: taxRate,
                taxAmount: taxAmount,
                lineTotal: lineTotal,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String productId,
                Value<String?> batchId = const Value.absent(),
                Value<String?> serverItemId = const Value.absent(),
                required String nameSnapshot,
                Value<String?> skuSnapshot = const Value.absent(),
                Value<String?> barcodeSnapshot = const Value.absent(),
                required String qty,
                required String unitPrice,
                Value<String?> costAtSale = const Value.absent(),
                Value<String> discount = const Value.absent(),
                Value<String> taxRate = const Value.absent(),
                Value<String?> taxAmount = const Value.absent(),
                Value<String?> lineTotal = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderItemsCompanion.insert(
                id: id,
                orderId: orderId,
                productId: productId,
                batchId: batchId,
                serverItemId: serverItemId,
                nameSnapshot: nameSnapshot,
                skuSnapshot: skuSnapshot,
                barcodeSnapshot: barcodeSnapshot,
                qty: qty,
                unitPrice: unitPrice,
                costAtSale: costAtSale,
                discount: discount,
                taxRate: taxRate,
                taxAmount: taxAmount,
                lineTotal: lineTotal,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrderItemsTable, OrderItem>(table),
                  $$OrderItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.orderId,
                        referencedTable: $$OrderItemsTableReferences
                            ._orderIdTable(db),
                        referencedColumn: $$OrderItemsTableReferences
                            ._orderIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $OrderItemsTable,
      OrderItem,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItem, $$OrderItemsTableReferences),
      OrderItem,
      PrefetchHooks Function({bool orderId})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String idempotencyKey,
  required String orderId,
  required String businessId,
  required String cashierId,
  required String payload,
  Value<String> status,
  Value<int> attempts,
  Value<String?> lastError,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> idempotencyKey,
  Value<String> orderId,
  Value<String> businessId,
  Value<String> cashierId,
  Value<String> payload,
  Value<String> status,
  Value<int> attempts,
  Value<String?> lastError,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$SyncQueueTableReferences
    extends BaseReferences<_$OfflineDatabase, $SyncQueueTable, SyncQueueData> {
  $$SyncQueueTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$OfflineDatabase db) =>
      db.orders.createAlias('sync_queue__order_id__orders__id');

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncQueueTableFilterComposer
    extends Composer<_$OfflineDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$OfflineDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierId => $composableBuilder(
    column: $table.cashierId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (SyncQueueData, $$SyncQueueTableReferences),
          SyncQueueData,
          PrefetchHooks Function({bool orderId})
        > {
  $$SyncQueueTableTableManager(_$OfflineDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> cashierId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                idempotencyKey: idempotencyKey,
                orderId: orderId,
                businessId: businessId,
                cashierId: cashierId,
                payload: payload,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idempotencyKey,
                required String orderId,
                required String businessId,
                required String cashierId,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                idempotencyKey: idempotencyKey,
                orderId: orderId,
                businessId: businessId,
                cashierId: cashierId,
                payload: payload,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueData>(table),
                  $$SyncQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.orderId,
                        referencedTable: $$SyncQueueTableReferences
                            ._orderIdTable(db),
                        referencedColumn: $$SyncQueueTableReferences
                            ._orderIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (SyncQueueData, $$SyncQueueTableReferences),
      SyncQueueData,
      PrefetchHooks Function({bool orderId})
    >;
typedef $$CatalogCacheStatesTableCreateCompanionBuilder =
    CatalogCacheStatesCompanion Function({
      required String businessId,
      required String branchId,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$CatalogCacheStatesTableUpdateCompanionBuilder =
    CatalogCacheStatesCompanion Function({
      Value<String> businessId,
      Value<String> branchId,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$CatalogCacheStatesTableFilterComposer
    extends Composer<_$OfflineDatabase, $CatalogCacheStatesTable> {
  $$CatalogCacheStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogCacheStatesTableOrderingComposer
    extends Composer<_$OfflineDatabase, $CatalogCacheStatesTable> {
  $$CatalogCacheStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogCacheStatesTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $CatalogCacheStatesTable> {
  $$CatalogCacheStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CatalogCacheStatesTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $CatalogCacheStatesTable,
          CatalogCacheState,
          $$CatalogCacheStatesTableFilterComposer,
          $$CatalogCacheStatesTableOrderingComposer,
          $$CatalogCacheStatesTableAnnotationComposer,
          $$CatalogCacheStatesTableCreateCompanionBuilder,
          $$CatalogCacheStatesTableUpdateCompanionBuilder,
          (
            CatalogCacheState,
            BaseReferences<
              _$OfflineDatabase,
              $CatalogCacheStatesTable,
              CatalogCacheState
            >,
          ),
          CatalogCacheState,
          PrefetchHooks Function()
        > {
  $$CatalogCacheStatesTableTableManager(
    _$OfflineDatabase db,
    $CatalogCacheStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogCacheStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogCacheStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogCacheStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogCacheStatesCompanion(
                businessId: businessId,
                branchId: branchId,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String branchId,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CatalogCacheStatesCompanion.insert(
                businessId: businessId,
                branchId: branchId,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogCacheStatesTable, CatalogCacheState>(
                    table,
                  ),
                  BaseReferences<
                    _$OfflineDatabase,
                    $CatalogCacheStatesTable,
                    CatalogCacheState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogCacheStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $CatalogCacheStatesTable,
      CatalogCacheState,
      $$CatalogCacheStatesTableFilterComposer,
      $$CatalogCacheStatesTableOrderingComposer,
      $$CatalogCacheStatesTableAnnotationComposer,
      $$CatalogCacheStatesTableCreateCompanionBuilder,
      $$CatalogCacheStatesTableUpdateCompanionBuilder,
      (
        CatalogCacheState,
        BaseReferences<
          _$OfflineDatabase,
          $CatalogCacheStatesTable,
          CatalogCacheState
        >,
      ),
      CatalogCacheState,
      PrefetchHooks Function()
    >;
typedef $$PosShiftsTableCreateCompanionBuilder = PosShiftsCompanion Function({
  required String id,
  required String profileId,
  required String businessId,
  required String branchId,
  required String status,
  required String openingFloat,
  Value<String?> closingCounted,
  Value<String?> expectedCash,
  Value<String?> variance,
  Value<String?> varianceReason,
  required DateTime openedAt,
  Value<DateTime?> closedAt,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$PosShiftsTableUpdateCompanionBuilder = PosShiftsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<String> businessId,
  Value<String> branchId,
  Value<String> status,
  Value<String> openingFloat,
  Value<String?> closingCounted,
  Value<String?> expectedCash,
  Value<String?> variance,
  Value<String?> varianceReason,
  Value<DateTime> openedAt,
  Value<DateTime?> closedAt,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$PosShiftsTableFilterComposer
    extends Composer<_$OfflineDatabase, $PosShiftsTable> {
  $$PosShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingFloat => $composableBuilder(
    column: $table.openingFloat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closingCounted => $composableBuilder(
    column: $table.closingCounted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variance => $composableBuilder(
    column: $table.variance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get varianceReason => $composableBuilder(
    column: $table.varianceReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PosShiftsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $PosShiftsTable> {
  $$PosShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingFloat => $composableBuilder(
    column: $table.openingFloat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closingCounted => $composableBuilder(
    column: $table.closingCounted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variance => $composableBuilder(
    column: $table.variance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get varianceReason => $composableBuilder(
    column: $table.varianceReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PosShiftsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $PosShiftsTable> {
  $$PosShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get openingFloat => $composableBuilder(
    column: $table.openingFloat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closingCounted => $composableBuilder(
    column: $table.closingCounted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variance =>
      $composableBuilder(column: $table.variance, builder: (column) => column);

  GeneratedColumn<String> get varianceReason => $composableBuilder(
    column: $table.varianceReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$PosShiftsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $PosShiftsTable,
          PosShift,
          $$PosShiftsTableFilterComposer,
          $$PosShiftsTableOrderingComposer,
          $$PosShiftsTableAnnotationComposer,
          $$PosShiftsTableCreateCompanionBuilder,
          $$PosShiftsTableUpdateCompanionBuilder,
          (
            PosShift,
            BaseReferences<_$OfflineDatabase, $PosShiftsTable, PosShift>,
          ),
          PosShift,
          PrefetchHooks Function()
        > {
  $$PosShiftsTableTableManager(_$OfflineDatabase db, $PosShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PosShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PosShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PosShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> openingFloat = const Value.absent(),
                Value<String?> closingCounted = const Value.absent(),
                Value<String?> expectedCash = const Value.absent(),
                Value<String?> variance = const Value.absent(),
                Value<String?> varianceReason = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PosShiftsCompanion(
                id: id,
                profileId: profileId,
                businessId: businessId,
                branchId: branchId,
                status: status,
                openingFloat: openingFloat,
                closingCounted: closingCounted,
                expectedCash: expectedCash,
                variance: variance,
                varianceReason: varianceReason,
                openedAt: openedAt,
                closedAt: closedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String businessId,
                required String branchId,
                required String status,
                required String openingFloat,
                Value<String?> closingCounted = const Value.absent(),
                Value<String?> expectedCash = const Value.absent(),
                Value<String?> variance = const Value.absent(),
                Value<String?> varianceReason = const Value.absent(),
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => PosShiftsCompanion.insert(
                id: id,
                profileId: profileId,
                businessId: businessId,
                branchId: branchId,
                status: status,
                openingFloat: openingFloat,
                closingCounted: closingCounted,
                expectedCash: expectedCash,
                variance: variance,
                varianceReason: varianceReason,
                openedAt: openedAt,
                closedAt: closedAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PosShiftsTable, PosShift>(table),
                  BaseReferences<_$OfflineDatabase, $PosShiftsTable, PosShift>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PosShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $PosShiftsTable,
      PosShift,
      $$PosShiftsTableFilterComposer,
      $$PosShiftsTableOrderingComposer,
      $$PosShiftsTableAnnotationComposer,
      $$PosShiftsTableCreateCompanionBuilder,
      $$PosShiftsTableUpdateCompanionBuilder,
      (PosShift, BaseReferences<_$OfflineDatabase, $PosShiftsTable, PosShift>),
      PosShift,
      PrefetchHooks Function()
    >;

class $OfflineDatabaseManager {
  final _$OfflineDatabase _db;
  $OfflineDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CatalogCacheStatesTableTableManager get catalogCacheStates =>
      $$CatalogCacheStatesTableTableManager(_db, _db.catalogCacheStates);
  $$PosShiftsTableTableManager get posShifts =>
      $$PosShiftsTableTableManager(_db, _db.posShifts);
}
