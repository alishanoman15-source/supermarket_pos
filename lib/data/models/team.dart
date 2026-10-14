/// A staff member in the business (SPEC §66). Table `profiles`.
class TeamMember {
  final String id;
  final String name;
  final String? phone;
  final String? roleId;
  final String? roleName;
  final String? branchId;
  final String status;

  const TeamMember({
    required this.id,
    required this.name,
    required this.status,
    this.phone,
    this.roleId,
    this.roleName,
    this.branchId,
  });

  bool get isActive => status == 'active';

  factory TeamMember.fromMap(Map<String, dynamic> map) => TeamMember(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        phone: map['phone'] as String?,
        roleId: map['role_id'] as String?,
        roleName: map['role_name'] as String?,
        branchId: map['branch_id'] as String?,
        status: (map['status'] as String?) ?? 'active',
      );
}

/// A role definition (SPEC §67). Table `roles`.
class AppRole {
  final String id;

  /// Stable template identifier (`cashier`, `manager`, …). System roles always
  /// carry one; custom roles fall back to an empty key and are referenced by id.
  final String key;
  final String name;
  final String? description;
  final bool isSystem;

  const AppRole({
    required this.id,
    required this.name,
    this.key = '',
    this.description,
    this.isSystem = false,
  });

  factory AppRole.fromMap(Map<String, dynamic> map) => AppRole(
        id: map['id'] as String,
        key: (map['key'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        description: map['description'] as String?,
        isSystem: (map['is_system'] as bool?) ?? false,
      );
}

/// A permission catalogue entry (SPEC §67). Table `permissions`.
class AppPermission {
  final String key;
  final String description;
  final String category;

  const AppPermission({
    required this.key,
    required this.description,
    required this.category,
  });

  factory AppPermission.fromMap(Map<String, dynamic> map) => AppPermission(
        key: map['key'] as String,
        description: (map['description'] as String?) ?? '',
        category: (map['category'] as String?) ?? 'other',
      );
}
