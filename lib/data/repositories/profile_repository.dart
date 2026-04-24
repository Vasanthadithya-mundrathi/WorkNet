import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

// ════════════════════════════════════════════════════════════════════
// Isar instance provider
// ════════════════════════════════════════════════════════════════════

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [UserProfileSchema],
    directory: dir.path,
  );
});

// ════════════════════════════════════════════════════════════════════
// ProfileRepository
// ════════════════════════════════════════════════════════════════════

class ProfileRepository {
  final Isar _isar;
  static const _uuid = Uuid();

  ProfileRepository(this._isar);

  Future<UserProfile?> getMyProfile() async {
    return _isar.userProfiles.where().findFirst();
  }

  Stream<UserProfile?> watchMyProfile() {
    return _isar.userProfiles
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  Future<UserProfile> createOrUpdateProfile(UserProfile profile) async {
    await _isar.writeTxn(() async {
      if (profile.userId.isEmpty) {
        profile.userId = _uuid.v4();
      }
      profile.lastUpdated = DateTime.now();
      await _isar.userProfiles.put(profile);
    });
    return profile;
  }

  Future<void> completeOnboarding() async {
    final profile = await getMyProfile();
    if (profile == null) return;
    await _isar.writeTxn(() async {
      profile.onboardingComplete = true;
      await _isar.userProfiles.put(profile);
    });
  }

  Future<void> setStealthMode(bool active) async {
    final profile = await getMyProfile();
    if (profile == null) return;
    await _isar.writeTxn(() async {
      profile.stealthMode = active;
      await _isar.userProfiles.put(profile);
    });
  }

  Future<bool> isOnboardingComplete() async {
    final profile = await getMyProfile();
    return profile?.onboardingComplete ?? false;
  }
}

// ════════════════════════════════════════════════════════════════════
// Riverpod Providers
// ════════════════════════════════════════════════════════════════════

final profileRepositoryProvider = FutureProvider<ProfileRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return ProfileRepository(isar);
});

final myProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final repo = await ref.watch(profileRepositoryProvider.future);
  yield* repo.watchMyProfile();
});
