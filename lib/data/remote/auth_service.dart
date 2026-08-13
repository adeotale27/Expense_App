import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/logging/app_log.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/enums.dart';
import '../local/app_database.dart';

class FirebaseBootstrap {
  static bool available = false;

  static Future<bool> tryInit() async {
    try {
      await Firebase.initializeApp();
      available = true;
      return true;
    } catch (e) {
      AppLog.sync('Firebase not configured; running local-first.');
      available = false;
      return false;
    }
  }
}

class SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _userKey = 'spendping.userId';
  static const _deviceKey = 'spendping.deviceId';
  static const _nameKey = 'spendping.displayName';
  static const _emailKey = 'spendping.email';
  static const _providerKey = 'spendping.provider';

  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null) return existing;
    final id = newId();
    await _storage.write(key: _deviceKey, value: id);
    return id;
  }

  Future<UserProfile?> current() async {
    final id = await _storage.read(key: _userKey);
    if (id == null) return null;
    return UserProfile(
      id: id,
      displayName: await _storage.read(key: _nameKey) ?? 'You',
      email: await _storage.read(key: _emailKey),
      provider: AuthProviderType.values.byName(
        await _storage.read(key: _providerKey) ?? 'local',
      ),
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<void> save(UserProfile user) async {
    await _storage.write(key: _userKey, value: user.id);
    await _storage.write(key: _nameKey, value: user.displayName);
    if (user.email != null) {
      await _storage.write(key: _emailKey, value: user.email);
    }
    await _storage.write(key: _providerKey, value: user.provider.name);
  }

  Future<void> clear() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _providerKey);
  }
}

class AuthService {
  AuthService(this.db, this.session);
  final AppDatabase db;
  final SessionStore session;

  Future<UserProfile> continueLocal({String name = 'You'}) async {
    final existing = await session.current();
    if (existing != null) return existing;
    final user = UserProfile(
      id: newId(),
      displayName: name,
      provider: AuthProviderType.local,
      createdAt: DateTime.now().toUtc(),
    );
    await session.save(user);
    return user;
  }

  Future<UserProfile> registerEmail(String email, String password, String name) async {
    if (FirebaseBootstrap.available) {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserProfile(
        id: cred.user!.uid,
        displayName: name,
        email: email,
        provider: AuthProviderType.email,
        createdAt: DateTime.now().toUtc(),
      );
      await session.save(user);
      return user;
    }
    final salt = newId();
    final hash = sha256.convert(utf8.encode('$salt:$password')).toString();
    final id = newId();
    await db.into(db.localAccounts).insert(
          LocalAccountsCompanion.insert(
            id: id,
            email: email.toLowerCase(),
            passwordHash: hash,
            salt: salt,
            displayName: name,
            createdAt: DateTime.now().toUtc(),
          ),
        );
    final user = UserProfile(
      id: id,
      displayName: name,
      email: email,
      provider: AuthProviderType.email,
      createdAt: DateTime.now().toUtc(),
    );
    await session.save(user);
    return user;
  }

  Future<UserProfile> signInEmail(String email, String password) async {
    if (FirebaseBootstrap.available) {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserProfile(
        id: cred.user!.uid,
        displayName: cred.user!.displayName ?? email.split('@').first,
        email: email,
        provider: AuthProviderType.email,
        createdAt: DateTime.now().toUtc(),
      );
      await session.save(user);
      return user;
    }
    final row = await (db.select(db.localAccounts)
          ..where((t) => t.email.equals(email.toLowerCase())))
        .getSingleOrNull();
    if (row == null) {
      throw Exception('No account for that email');
    }
    final hash = sha256.convert(utf8.encode('${row.salt}:$password')).toString();
    if (hash != row.passwordHash) {
      throw Exception('Incorrect password');
    }
    final user = UserProfile(
      id: row.id,
      displayName: row.displayName,
      email: row.email,
      provider: AuthProviderType.email,
      createdAt: row.createdAt,
    );
    await session.save(user);
    return user;
  }

  Future<UserProfile> signInGoogle() async {
    if (!FirebaseBootstrap.available) {
      throw Exception(
        'Google Sign-In needs Firebase. Use email or continue locally for now.',
      );
    }
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
    final user = UserProfile(
      id: userCred.user!.uid,
      displayName: userCred.user!.displayName ?? googleUser.displayName ?? 'You',
      email: userCred.user!.email,
      provider: AuthProviderType.google,
      createdAt: DateTime.now().toUtc(),
    );
    await session.save(user);
    return user;
  }

  Future<UserProfile> signInApple() async {
    if (!FirebaseBootstrap.available) {
      throw Exception(
        'Sign in with Apple needs Firebase. Use email or continue locally for now.',
      );
    }
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      accessToken: apple.authorizationCode,
    );
    final userCred = await FirebaseAuth.instance.signInWithCredential(oauth);
    final user = UserProfile(
      id: userCred.user!.uid,
      displayName: [
        apple.givenName,
        apple.familyName,
      ].whereType<String>().join(' ').trim().isEmpty
          ? 'You'
          : [apple.givenName, apple.familyName].whereType<String>().join(' '),
      email: userCred.user!.email,
      provider: AuthProviderType.apple,
      createdAt: DateTime.now().toUtc(),
    );
    await session.save(user);
    return user;
  }

  Future<void> signOut() async {
    if (FirebaseBootstrap.available) {
      await FirebaseAuth.instance.signOut();
    }
    await session.clear();
  }
}
