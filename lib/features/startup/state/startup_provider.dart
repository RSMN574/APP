import 'package:flutter/foundation.dart';

import '../data/onboarding_repository.dart';

class StartupProvider extends ChangeNotifier {
  StartupProvider({OnboardingRepository? repository})
      : _repository = repository ?? const OnboardingRepository();

  final OnboardingRepository _repository;

  bool _isLoading = true;
  bool _shouldShowOnboarding = false;
  bool _isCompleting = false;

  bool get isLoading => _isLoading;
  bool get shouldShowOnboarding => _shouldShowOnboarding;
  bool get isCompleting => _isCompleting;

  Future<void> load() async {
    if (!_isLoading) return;

    final results = await Future.wait<dynamic>([
      _repository.hasCompletedOnboarding(),
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);

    _shouldShowOnboarding = !(results.first as bool);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_isCompleting) return;

    _isCompleting = true;
    notifyListeners();
    try {
      await _repository.markOnboardingCompleted();
      _shouldShowOnboarding = false;
    } finally {
      _isCompleting = false;
      notifyListeners();
    }
  }
}
