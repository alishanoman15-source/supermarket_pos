import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart.dart';

/// A held cart parked by the cashier (SPEC §10 step 8, §62). Held carts are
/// per-device only — no server conflict surface (SPEC §62).
class HeldCart {
  final String id;
  final String label;
  final String? customerName;
  final DateTime heldAt;
  final CartState cart;

  const HeldCart({
    required this.id,
    required this.label,
    required this.heldAt,
    required this.cart,
    this.customerName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'customer_name': customerName,
        'held_at': heldAt.toIso8601String(),
        'cart': cart.toJson(),
      };

  factory HeldCart.fromJson(Map<String, dynamic> map) => HeldCart(
        id: map['id'] as String,
        label: (map['label'] as String?) ?? '',
        customerName: map['customer_name'] as String?,
        heldAt: DateTime.parse(map['held_at'] as String).toLocal(),
        cart: CartState.fromJson(Map<String, dynamic>.from(map['cart'] as Map)),
      );
}

/// Persists held carts in `shared_preferences`, scoped per profile id so two
/// cashiers sharing a terminal never see each other's parked carts.
class HeldCartStore {
  const HeldCartStore();

  String _key(String profileId) => 'held_carts_$profileId';

  Future<List<HeldCart>> load(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(profileId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => HeldCart.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String profileId, List<HeldCart> carts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(profileId),
      jsonEncode(carts.map((c) => c.toJson()).toList()),
    );
  }
}
