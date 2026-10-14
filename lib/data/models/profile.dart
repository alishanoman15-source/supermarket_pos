/// A staff profile (SPEC §66). `id` equals auth.users.id; a null [businessId]
/// means the user has not completed onboarding yet.
class Profile {
  final String id;
  final String authUserId;
  final String? businessId;
  final String? branchId;
  final String? roleId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String status;

  const Profile({
    required this.id,
    required this.authUserId,
    required this.name,
    required this.status,
    this.businessId,
    this.branchId,
    this.roleId,
    this.phone,
    this.avatarUrl,
  });

  bool get hasBusiness => businessId != null;
  bool get isActive => status == 'active';

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      authUserId: (map['auth_user_id'] ?? map['id']) as String,
      businessId: map['business_id'] as String?,
      branchId: map['branch_id'] as String?,
      roleId: map['role_id'] as String?,
      name: (map['name'] as String?) ?? '',
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      status: (map['status'] as String?) ?? 'active',
    );
  }
}
