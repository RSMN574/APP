import 'package:flutter_test/flutter_test.dart';
import 'package:com.rsmn574.app/features/startup/data/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingRepository', () {
    late OnboardingRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = OnboardingRepository();
    });

    test('defaults to showing onboarding for a new installation', () async {
      expect(await repository.hasCompletedOnboarding(), isFalse);
    });

    test('persists and clears onboarding completion', () async {
      await repository.markOnboardingCompleted();
      expect(await repository.hasCompletedOnboarding(), isTrue);

      await repository.resetOnboarding();
      expect(await repository.hasCompletedOnboarding(), isFalse);
    });
  });
}
