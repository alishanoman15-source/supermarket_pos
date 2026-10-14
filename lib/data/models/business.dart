class Business {
  final String id;
  final String name;
  final String? legalName;
  final String? phone;
  final String? address;
  final String currency;
  final String timezone;
  final String? logoUrl;
  final String status;
  final Map<String, dynamic> settings;

  const Business({
    required this.id,
    required this.name,
    required this.currency,
    required this.timezone,
    required this.status,
    this.legalName,
    this.phone,
    this.address,
    this.logoUrl,
    this.settings = const {},
  });

  /// Tax is added on top unless the business opted into inclusive pricing
  /// (SPEC §30; `complete_sale` reads the same setting).
  bool get taxInclusive => (settings['tax_inclusive'] as bool?) ?? false;

  /// Receipt footer configured in business settings (SPEC §30).
  String? get receiptFooter => settings['receipt_footer'] as String?;

  factory Business.fromMap(Map<String, dynamic> map) => Business(
        id: map['id'] as String,
        name: map['name'] as String,
        currency: ((map['currency'] as String?) ?? 'PKR').trim(),
        timezone: (map['timezone'] as String?) ?? 'Asia/Karachi',
        status: (map['status'] as String?) ?? 'active',
        legalName: map['legal_name'] as String?,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
        logoUrl: map['logo_url'] as String?,
        settings: map['settings'] == null
            ? const {}
            : Map<String, dynamic>.from(map['settings'] as Map),
      );
}
