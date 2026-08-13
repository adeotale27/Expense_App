import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const pages = [
    (
      'Your money.\nRemembered.',
      'Track expenses without constantly opening an expense app.',
    ),
    (
      'Smart reminders',
      'We notice meaningful places and remind you to log expenses.',
    ),
    (
      'Location',
      'Location helps us understand when you visit places where you may have spent money. You can skip this and track manually.',
    ),
    (
      'Notifications',
      'We remind you at the right moments — never constantly.',
    ),
    (
      "You're ready.",
      'Add your first expense in a few seconds.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        'SpendPing',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pages[i].$1,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pages[i].$2,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < pages.length; i++)
                    Container(
                      width: i == _page ? 18 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_page < pages.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  } else {
                    context.go('/auth');
                  }
                },
                child: Text(_page == pages.length - 1 ? 'Get started' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
