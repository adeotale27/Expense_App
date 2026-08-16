import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logging/app_log.dart';
import '../../domain/entities/entities.dart';
import 'account_ownership.dart';
import 'auth_service.dart';

/// Writes the signed-in email next to the stable account id in Firestore.
///
/// Cloud paths stay `users/{uid}/...` (uid is Firebase Auth or a Google id).
/// Email is stored on the profile and in `emailLookups/{email}` so a new
/// phone that signs in with the same Google account can restore spends.
class CloudAccountDirectory {
  static Future<void> bind(UserProfile user) async {
    if (!FirebaseBootstrap.available) return;
    final email = AccountOwnership.normalizeEmail(user.email);
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.id).set(
        {
          'userId': user.id,
          'email': email,
          'displayName': user.displayName,
          'provider': user.provider.name,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      if (email != null) {
        await firestore
            .collection('emailLookups')
            .doc(AccountOwnership.emailLookupId(email))
            .set({
          'userId': user.id,
          'email': email,
        });
      }
    } catch (e) {
      AppLog.sync('Could not bind account email to cloud: $e');
    }
  }
}
