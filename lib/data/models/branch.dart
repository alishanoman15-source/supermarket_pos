class Branch {
  final String id;
  final String businessId;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;

  const Branch({
    required this.id,
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
    this.isActive = true,
  });

  factory Branch.fromMap(Map<String, dynamic> map) => Branch(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        name: map['name'] as String,
        address: map['address'] as String?,
        phone: map['phone'] as String?,
        isActive: (map['is_active'] as bool?) ?? true,
      );
}

/// One physical POS counter/device (SPEC §77 `pos_terminals`, §86 screen #59).
class PosTerminal {
  final String id;
  final String businessId;
  final String branchId;
  final String name;
  final String? deviceFingerprint;
  final String status;

  const PosTerminal({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.name,
    this.deviceFingerprint,
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  factory PosTerminal.fromMap(Map<String, dynamic> map) => PosTerminal(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        branchId: map['branch_id'] as String,
        name: map['name'] as String,
        deviceFingerprint: map['device_fingerprint'] as String?,
        status: (map['status'] as String?) ?? 'active',
      );
}
