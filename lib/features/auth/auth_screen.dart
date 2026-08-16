import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController(text: 'You');
  bool register = false;
  String? error;
  bool busy = false;

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await fn();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => error = _friendly(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signedIn(UserProfile user) async {
    ref.read(sessionProfileProvider.notifier).state = user;
    try {
      await ref.read(syncEngineProvider).syncAll();
    } catch (_) {}
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('Firebase') || s.contains('needs Firebase')) {
      return 'Cloud restore is optional. Google sign-in still works on this device.';
    }
    if (s.contains('password')) return 'Check your email and password.';
    if (s.contains('cancelled')) return 'Sign-in was cancelled.';
    return 'We could not sign you in. Try continuing locally.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Your data belongs to your account, not this phone.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            defaultTargetPlatform == TargetPlatform.android
                ? 'Google login works on a local debug install. You do not need to publish on Play. Add this computer’s SHA-1 in Firebase (see docs/PLAY_STORE.md).'
                : 'Sign in with Apple on iPhone. Google works here too if you set it up.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (defaultTargetPlatform == TargetPlatform.iOS) ...[
            FilledButton(
              onPressed: busy
                  ? null
                  : () => _run(() async {
                        final user = await auth.signInApple();
                        await _signedIn(user);
                      }),
              child: const Text('Sign in with Apple'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: busy
                ? null
                : () => _run(() async {
                      final user = await auth.signInGoogle();
                      await _signedIn(user);
                    }),
            child: const Text('Continue with Google'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => _run(() async {
                      final user = register
                          ? await auth.registerEmail(
                              email.text.trim(),
                              password.text,
                              name.text.trim().isEmpty ? 'You' : name.text.trim(),
                            )
                          : await auth.signInEmail(email.text.trim(), password.text);
                      await _signedIn(user);
                    }),
            child: Text(register ? 'Create email account' : 'Sign in with email'),
          ),
          TextButton(
            onPressed: () => setState(() => register = !register),
            child: Text(register ? 'Have an account? Sign in' : 'Need an account? Register'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy
                ? null
                : () => _run(() async {
                      final user = await auth.continueLocal(
                        name: name.text.trim().isEmpty ? 'You' : name.text.trim(),
                      );
                      ref.read(sessionProfileProvider.notifier).state = user;
                    }),
            child: const Text('Continue on this device'),
          ),
        ],
      ),
    );
  }
}
