import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  const ProfileRepository(this._client);

  /// Returns the caller's profile, or null when the auth trigger has not
  /// created it yet (first login race).
  Future<Profile?> fetchMyProfile() async {
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .eq('auth_user_id', _client.auth.currentUser?.id ?? '')
          .limit(1);
      if (rows.isEmpty) return null;
      return Profile.fromMap(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Updates the caller's own profile row (RLS: `profiles_update_self`).
  Future<void> updateMyProfile({
    required String profileId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      await _client.from('profiles').update({
        'name': ?name,
        'phone': ?phone,
        'avatar_url': ?avatarUrl,
      }).eq('id', profileId);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
