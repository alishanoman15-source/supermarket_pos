import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// Product projection read from `product_pos_view` / `product_full_view`
/// (cost columns are never present here — SPEC §71/D3.3).
class Product {
  final String id;
  final String businessId;
  final String name;
  final String? sku;
  final String? barcode;
  final String? categoryId;
  final String? brandId;
  final String? unitId;
  final Decimal sellingPrice;
  final Decimal taxRate;
  final bool isWeightBased;
  final bool trackBatch;
  final Decimal reorderLevel;
  final Decimal stock;
  final String status;
  final String? imageUrl;
  final String? description;
  final Decimal? purchasePrice; // only present for holders of products.view_cost

  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.sellingPrice,
    required this.taxRate,
    required this.isWeightBased,
    required this.trackBatch,
    required this.reorderLevel,
    required this.stock,
    required this.status,
    this.sku,
    this.barcode,
    this.categoryId,
    this.brandId,
    this.unitId,
    this.imageUrl,
    this.description,
    this.purchasePrice,
  });

  bool get isActive => status == 'active';
  bool get isLowStock => reorderLevel > Decimal.zero && stock <= reorderLevel;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        name: (map['name'] as String?) ?? '',
        sku: map['sku'] as String?,
        barcode: map['barcode'] as String?,
        categoryId: map['category_id'] as String?,
        brandId: map['brand_id'] as String?,
        unitId: map['unit_id'] as String?,
        sellingPrice: decimalFrom(map['selling_price'] ?? map['price']),
        taxRate: decimalFrom(map['tax_rate']),
        isWeightBased: (map['is_weight_based'] as bool?) ?? false,
        trackBatch: (map['track_batch'] as bool?) ?? false,
        reorderLevel: decimalFrom(map['reorder_level']),
        stock: decimalFrom(map['stock']),
        status: (map['status'] as String?) ?? 'active',
        imageUrl: map['image_url'] as String?,
        description: map['description'] as String?,
        purchasePrice: map['purchase_price_visible'] == null &&
                map['purchase_price'] == null
            ? null
            : decimalFrom(map['purchase_price_visible'] ?? map['purchase_price']),
      );
}
