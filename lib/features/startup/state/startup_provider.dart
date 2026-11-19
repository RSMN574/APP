import 'package:flutter/foundation.dart';

import '../data/onboarding_repository.dart';

class StartupProvider extends ChangeNotifier {
  StartupProvider({
    OnboardingRepository? repository,
    this.minimumSplashDuration = const Duration(milliseconds: 450),
  }) : _repository = repository ?? const OnboardingRepository();

  final Duration minimumSplashDuration;

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
      // QA B21：原本強制等待 1100ms。原生 Splash 已涵蓋引擎啟動，
      // Flutter Splash 只需短暫顯示品牌動畫，避免額外延遲進入首頁。
      Future<void>.delayed(minimumSplashDuration),
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
