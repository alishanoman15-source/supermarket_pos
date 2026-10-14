import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/team.dart';
import '../../../data/providers.dart';

final teamProvider = FutureProvider.autoDispose<List<TeamMember>>(
  (ref) => ref.watch(teamRepositoryProvider).fetchTeam(),
);

final rolesProvider = FutureProvider.autoDispose<List<AppRole>>(
  (ref) => ref.watch(teamRepositoryProvider).fetchRoles(),
);

final permissionsProvider = FutureProvider.autoDispose<List<AppPermission>>(
  (ref) => ref.watch(teamRepositoryProvider).fetchPermissions(),
);

final rolePermissionKeysProvider =
    FutureProvider.autoDispose.family<Set<String>, String>(
  (ref, roleId) => ref.watch(teamRepositoryProvider).fetchRolePermissionKeys(roleId),
);
