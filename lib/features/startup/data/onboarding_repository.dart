import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  const OnboardingRepository();

  static const onboardingCompletedKey = 'onboarding_completed';

  Future<bool> hasCompletedOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(onboardingCompletedKey) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(onboardingCompletedKey, true);
  }

  Future<void> resetOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(onboardingCompletedKey);
  }
}
