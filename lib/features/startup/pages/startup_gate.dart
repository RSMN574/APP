import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/onboarding_repository.dart';
import '../state/startup_provider.dart';
import 'onboarding_page.dart';
import 'splash_page.dart';

class StartupGate extends StatelessWidget {
  const StartupGate({
    super.key,
    required this.home,
  });

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StartupProvider()..load(),
      child: _StartupContent(home: home),
    );
  }
}

class _StartupContent extends StatelessWidget {
  const _StartupContent({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final startup = context.watch<StartupProvider>();

    if (startup.isLoading) return const SplashPage();
    if (startup.shouldShowOnboarding) {
      return OnboardingPage(
        onCompleted: startup.completeOnboarding,
      );
    }
    return home;
  }
}

class OnboardingLauncher {
  const OnboardingLauncher._();

  static Future<void> open(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingPage(
          onCompleted: () async {
            await const OnboardingRepository().markOnboardingCompleted();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
