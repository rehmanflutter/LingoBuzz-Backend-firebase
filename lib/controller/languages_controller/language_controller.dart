import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/common/helpers/app_logger.dart';
import 'package:lingobuzz/core/services/auth_services.dart';
import 'package:lingobuzz/core/services/languages_services/language_services.dart';
import 'package:lingobuzz/model/language_model.dart';
import 'package:lingobuzz/model/user_model.dart';

import '../words_controller/word_controller.dart';

class LanguageController extends GetxController {
  final LanguageService _languageService = LanguageService();
  final authController = Get.find<AuthController>();

  RxList<LanguageModel> languagesAvailable = <LanguageModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSwitchingLanguage = false.obs;

  Rx<LanguageModel?> nativeLanguage = LanguageModel(
      id: "u7H9tJG2ZBQv6gVfQD1J",
      name: 'English',
      code: 'en-Us'
  ).obs;
  Rx<LanguageModel?> learnLanguage = Rx<LanguageModel?>(null);

  // List of languages user has learned or is learning
  RxList<String> userLanguages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initLanguages();
  }

  Future<void> _initLanguages() async {
    await fetchLanguages();
    _loadUserLanguages();
    await loadUserLanguagesList();
  }

  Future<void> fetchLanguages() async {
    try {
      if (languagesAvailable.isNotEmpty) return;
      isLoading.value = true;

      final langs = await _languageService.fetchLanguages();

      // Filter out native language (English)
      final filtered = langs.where(
            (lang) => lang.name?.toLowerCase() != 'english',
      ).toList();

      languagesAvailable.assignAll(filtered);
      Log.debug('✅ Loaded ${filtered.length} learning languages.');
    } catch (e, st) {
      Log.debug('❌ Error fetching languages: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Load user's current languages
  void _loadUserLanguages() {
    final user = authController.currentUser.value;
    if (user == null) return;

    if (user.nativeLanguage != null) {
      nativeLanguage.value = user.nativeLanguage;
      Log.debug('✅ Loaded native language: ${user.nativeLanguage?.name}');
    }

    if (user.currentLearning != null) {
      learnLanguage.value = LanguageModel(
        id: user.currentLearning!.id,
        name: user.currentLearning!.languageName,
      );
      Log.debug('✅ Loaded learning language: ${user.currentLearning?.languageName}');
    }
  }

  /// ✅ Load list of all languages user has interacted with
  Future<void> loadUserLanguagesList() async {
    try {
      final languages = await AuthServices.getUserLanguages();
      userLanguages.assignAll(languages);
      Log.debug('✅ User has learned/learning ${languages.length} languages: $languages');
    } catch (e) {
      Log.debug('❌ Error loading user languages list: $e');
    }
  }

  /// ✅ Check if user has previous learning data for a language
  Future<bool> hasLearnedLanguageBefore(String languageName) async {
    return userLanguages.contains(languageName);
  }

  /// ✅ CRITICAL FIX: Select and switch to a new learning language
  /// This handles language switching WITHOUT clearing cache or resetting lastPracticeAt
  Future<bool> selectNewLearnLanguage(
      LanguageModel language, {
        String? defaultLevel,
        int? defaultWordsPerDay,
        int? defaultContentType,
      }) async {
    try {
      if (language.name == null) {
        Log.debug('❌ Language name is null');
        return false;
      }

      // Check if already learning this language
      if (learnLanguage.value?.name == language.name) {
        Log.debug('ℹ️ Already learning ${language.name}');
        return true;
      }

      isSwitchingLanguage.value = true;
      Log.debug('🔄 Starting language switch to: ${language.name}');

      // ✅ CRITICAL: Get current user to check subscription status
      final currentUser = authController.currentUser.value;
      final currentSubscription = currentUser?.subscription;
      final isPremium = currentSubscription != null &&
          currentSubscription.isNotEmpty &&
          (currentSubscription.first.isActive ?? false);

      // ✅ Determine words per day based on subscription
      final effectiveWordsPerDay = isPremium ? 10 : (defaultWordsPerDay ?? 3);

      Log.debug('📊 User subscription status:');
      Log.debug('   - Is Premium: $isPremium');
      Log.debug('   - Words per day: $effectiveWordsPerDay');

      // ✅ CRITICAL: Call the service WITHOUT clearing cache or resetting practice date
      final result = await AuthServices.switchLearningLanguage(
        languageId: language.id ?? '',
        languageName: language.name!,
        defaultLevel: defaultLevel ?? 'A1',
        defaultWordsPerDay: effectiveWordsPerDay,
        defaultContentType: defaultContentType ?? 2,
        preserveLastPractice: true, // ✅ NEW PARAMETER
      );

      if (result['success']) {
        // Update local state
        learnLanguage.value = language;

        // Update auth controller's user model
        final updatedUser = result['user'] as UserModel?;
        if (updatedUser != null) {
          authController.saveUserToCache(updatedUser);
        }

        // Reload user languages list
        await loadUserLanguagesList();

        // ✅ CRITICAL: DON'T initialize word controller here
        // Let the word controller handle it based on lastPracticeAt
        Log.debug('✅ Language switched successfully to ${language.name}');
        Log.debug('   - Cache preserved: ${result['cachePreserved']}');
        Log.debug('   - Is new language: ${result['isNewLanguage']}');
        Log.debug('   - Last practice preserved: ${updatedUser?.currentLearning?.lastPracticeAt}');

        isSwitchingLanguage.value = false;
        return true;
      } else {
        Log.debug('❌ Language switch failed: ${result['message']}');
        isSwitchingLanguage.value = false;
        return false;
      }
    } catch (e, st) {
      Log.debug('❌ Error in selectNewLearnLanguage: $e\n$st');
      isSwitchingLanguage.value = false;
      return false;
    }
  }

  /// ✅ Set native language and update Firestore
  Future<void> setNativeLanguage(
      LanguageModel language, {
        bool showLoading = false
      }) async {
    nativeLanguage.value = language;
    if (!showLoading) isLoading.value = true;

    final success = await authController.updateUserData(
      nativeLanguage: language,
      showLoading: showLoading,
    );

    isLoading.value = false;
    Log.debug(success
        ? '✅ Native language updated successfully.'
        : '⚠️ Failed to update native language.');
  }

  Future<void> setLearnLanguage(
      LanguageModel language, {
        bool showLoading = false,
        String? currentLevel,
        int? wordsPerDay,
      }) async {
    await selectNewLearnLanguage(
      language,
      defaultLevel: currentLevel,
      defaultWordsPerDay: wordsPerDay,
    );
  }

  /// ✅ Get current learning model
  LearningLanguageModel? getCurrentLearningModel() {
    final user = authController.currentUser.value;
    return user?.currentLearning;
  }

  /// ✅ Update only provided learning progress fields
  Future<bool> updateLearningProgress({
    String? currentLevel,
    int? wordsPerDay,
    int? learnedWordsCount,
  }) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return false;

    final updatedLearning = user!.currentLearning!.copyWith(
      currentLevel: currentLevel,
      wordsPerDay: wordsPerDay,
    );

    return await authController.updateUserData(
      currentLearning: updatedLearning,
      showLoading: false,
    );
  }

  /// ✅ Get learning progress for a specific language (from subcollection)
  Future<LearningLanguageModel?> getLanguageLearningData(String languageName) async {
    try {
      return await AuthServices.getPreviousLanguageLearning(
        languageName: languageName,
      );
    } catch (e) {
      Log.debug('❌ Error getting language learning data: $e');
      return null;
    }
  }
}