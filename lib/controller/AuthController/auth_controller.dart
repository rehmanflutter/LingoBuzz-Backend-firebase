import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/model/level_assessment_model.dart';
import '../../Routes/app_routes.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/common/snackbar_utils.dart';
import '../../core/services/auth_services.dart';
import '../../model/user_model.dart';
import '../../model/language_model.dart';
import '../../model/word_model.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();

  final showPassword = false.obs;
  RxBool isLoading = false.obs;
  RxDouble progressValue = 0.1.obs;

  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isLogin = false.obs;

  // Text Editing Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final resetEmailController = TextEditingController();
  final passwordController = TextEditingController();

  // Level Assessment
  RxInt selectedAssessmentLevel = 5.obs;
  final List<LevelAssessmentModel> levelAssessmentList = [
    LevelAssessmentModel(name: 'A1', title: 'A1 - Beginner', description: "I'm just starting out"),
    LevelAssessmentModel(name: 'A2', title: 'A2 - Elementary', description: 'I know some basic words and phrases'),
    LevelAssessmentModel(name: 'B1', title: 'B1 - Intermediate', description: 'I can handle simple conversations'),
    LevelAssessmentModel(name: 'B2', title: 'B2 - Upper Intermediate', description: 'I can discuss complex topics'),
  ];

  // Learning Preferences
  RxInt wordsPerDaySelect = 0.obs;
  final List<String> wordsPerDay = ['1 word or phrase per day', '2 words or phrases per day', '3 words or phrases per day'];
  RxInt contentTypeSelect = 2.obs;
  final List<String> contentType = ['Words only', 'Sentences only', 'Mix of words and sentences'];

// Replace the onInit method in AuthController

  @override
  void onInit() async {
    super.onInit();
    _logStackTrace('onInit');

    // Load user from cache first
    await _loadUserFromCache();
    Log.debug('✅ Loaded user from cache: ${currentUser.value?.toMap()}');

    // Fetch fresh user data from Firestore
    await getUser();

    // ✅ CRITICAL: Initialize word controller ONLY if user has learning data
    if (currentUser.value?.currentLearning != null) {
      try {
        // Small delay to ensure all controllers are initialized
        await Future.delayed(Duration(milliseconds: 500));

        final wordController = Get.find<WordController>();
        await wordController.initializeAfterLogin();
        Log.debug("✅ Post-init word controller initialization completed");
      } catch (e, st) {
        Log.debug("⚠️ Error during post-init word controller setup: $e\n$st");
        // Don't throw - this is not critical for app to function
      }
    }
  }

// ✅ UPDATED: getUser method
  Future<void> getUser() async {
    _logStackTrace('getUser');
    final uid = currentUser.value?.uid ?? '';
    if (uid.isEmpty) {
      Log.debug('⚠️ No UID found for current user.');
      return;
    }

    try {
      final user = await AuthServices.getUserModel(uid);
      Log.debug('✅ Fetched user from AuthServices: ${user?.toMap()}');

      if (user != null) {
        saveUserToCache(user);

        // Don't reinitialize here - let onInit handle it
        Log.debug('✅ User data refreshed from Firestore');
      }
    } catch (e, st) {
      Log.debug('❌ Error fetching user: $e\n$st');
    }
  }

  /// ✅ Stack trace logger
  void _logStackTrace(String functionName) {
    try {
      final traceLines = StackTrace.current.toString().split('\n');
      if (traceLines.length > 2) {
        final match = RegExp(r'(\w+\.dart):(\d+):(\d+)').firstMatch(traceLines[2]);
        if (match != null) {
          final file = match.group(1);
          final line = match.group(2);
          Log.debug('📍 [$functionName] called from $file:$line');
          return;
        }
      }
      Log.debug('📍 [$functionName] call trace not available.');
    } catch (e) {
      Log.debug('⚠️ Stack trace parse error in $functionName: $e');
    }
  }

  Future<void> _loadUserFromCache() async {
    _logStackTrace('_loadUserFromCache');
    final cachedUser = _storage.read('currentUser');
    if (cachedUser == null) return;

    try {
      final userMap = Map<String, dynamic>.from(cachedUser);
      currentUser.value = UserModel.fromMap(userMap);
      Log.debug('✅ Loaded user from cache: ${currentUser.value?.toMap()}');
      final user = currentUser.value;
      if (user?.uid != null && user?.email != null) {
        isLogin.value = true;
      }
    } catch (e, st) {
      Log.debug('❌ Error loading cached user: $e\n$st');
      _storage.remove('currentUser');
    }
  }

  void saveUserToCache(UserModel user) {
    _logStackTrace('saveUserToCache');
    Log.debug('💾 Saving user to cache: ${user.toMap()}');
    _storage.write('currentUser', user.toMap());
    currentUser.value = user;
    if (user.uid != null && user.email != null) {
      isLogin.value = true;
    }
  }

  /// ✅ UPDATED: Cache key now includes language name for language-specific caching
  void cacheTodayWords(List<WordModel> words) {
    _logStackTrace('cacheTodayWords');
    if (words.isEmpty) {
      Log.debug('⚠️ Attempted to cache empty word list');
      return;
    }

    final today = DateTime.now();
    final languageName = currentUser.value?.currentLearning?.languageName ?? 'unknown';
    final cacheKey = 'today_words_${currentUser.value?.uid}_$languageName';
    final dateCacheKey = 'today_words_date_${currentUser.value?.uid}_$languageName';
    final metaKey = 'today_words_meta_${currentUser.value?.uid}_$languageName';

    _storage.write(cacheKey, words.map((w) => w.toJson()).toList());
    _storage.write(dateCacheKey, today.toIso8601String());
    _storage.write(metaKey, {
      'count': words.length,
      'languageName': languageName,
      'firstWordId': words.first.id,
      'lastWordId': words.last.id,
      'cachedAt': today.toIso8601String(),
    });

    Log.debug('💾 Cached ${words.length} words for today ($languageName)');
  }

  /// ✅ UPDATED: Get cached words for specific language
  List<WordModel> getCachedTodayWords() {
    _logStackTrace('getCachedTodayWords');
    final languageName = currentUser.value?.currentLearning?.languageName ?? 'unknown';
    final cacheKey = 'today_words_${currentUser.value?.uid}_$languageName';
    final dateCacheKey = 'today_words_date_${currentUser.value?.uid}_$languageName';
    final metaKey = 'today_words_meta_${currentUser.value?.uid}_$languageName';

    final cachedWords = _storage.read(cacheKey);
    final cachedDate = _storage.read(dateCacheKey);
    final cachedMeta = _storage.read(metaKey);

    if (cachedWords == null || cachedDate == null) {
      Log.debug('⚠️ No cached words found for $languageName');
      return [];
    }

    try {
      final cacheDateTime = DateTime.parse(cachedDate);
      final now = DateTime.now();
      final cacheDate = DateTime(cacheDateTime.year, cacheDateTime.month, cacheDateTime.day);
      final today = DateTime(now.year, now.month, now.day);

      if (!cacheDate.isAtSameMomentAs(today)) {
        Log.debug('📅 Cached words are from a previous day — clearing cache');
        clearTodayWordsCache();
        return [];
      }

      final wordsList = (cachedWords as List)
          .map((w) {
        final wordMap = Map<String, dynamic>.from(w);
        final wordId = wordMap['id'] ?? '0';
        return WordModel.fromJson(wordMap, wordId);
      })
          .toList();

      Log.debug('✅ Retrieved ${wordsList.length} cached words from today ($languageName)');
      if (cachedMeta != null) Log.debug('   - Cache metadata: $cachedMeta');
      return wordsList;
    } catch (e, st) {
      Log.debug('❌ Error retrieving cached words: $e\n$st');
      clearTodayWordsCache();
      return [];
    }
  }

  /// ✅ UPDATED: Clear cache for current language
  void clearTodayWordsCache() {
    _logStackTrace('clearTodayWordsCache');
    final languageName = currentUser.value?.currentLearning?.languageName ?? 'unknown';
    final cacheKey = 'today_words_${currentUser.value?.uid}_$languageName';
    final dateCacheKey = 'today_words_date_${currentUser.value?.uid}_$languageName';
    final metaKey = 'today_words_meta_${currentUser.value?.uid}_$languageName';

    _storage.remove(cacheKey);
    _storage.remove(dateCacheKey);
    _storage.remove(metaKey);

    Log.debug('🗑️ Cleared today\'s words cache for $languageName');
  }

  void clearAllLanguageCaches() {
    _logStackTrace('clearAllLanguageCaches');
    try {
      // Get all keys first as a separate list to avoid concurrent modification
      final keys = _storage.getKeys().toList();

      // Filter out the language-related keys you want to remove
      final languageKeys = keys.where((key) {
        return key.startsWith('today_words_') ||
            key.startsWith('last_practice_') ||
            key.startsWith('word_cache_') ||
            key.startsWith('learning_progress_') ||
            key.startsWith('language_');
      }).toList();

      Log.debug('🗑️ Found ${languageKeys.length} language cache keys to remove');

      // Remove keys safely
      for (final key in languageKeys) {
        _storage.remove(key);
      }

      Log.debug('✅ Cleared all language caches safely');
    } catch (e, st) {
      Log.debug('⚠️ Error clearing language caches: $e\n$st');
    }
  }


  bool hasCachedWordsForToday() {
    _logStackTrace('hasCachedWordsForToday');
    final cachedWords = getCachedTodayWords();
    return cachedWords.isNotEmpty;
  }

  Future<bool> createAccount() async {
    _logStackTrace('createAccount');
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if ([firstName, lastName, email, password].any((e) => e.isEmpty)) {
      SnackBarUtils.showErrorSnackbar('Please fill all required fields.');
      return false;
    }
    if (!email.isEmail) {
      SnackBarUtils.showErrorSnackbar('Please enter a valid email.');
      return false;
    }
    if (password.length < 6) {
      SnackBarUtils.showErrorSnackbar('Password must be at least 6 characters.');
      return false;
    }

    String fcmToken = _storage.read('fcm_token') ?? '';

    isLoading.value = true;
    final result = await AuthServices.createAccount(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        fcmToken: fcmToken
    );
    isLoading.value = false;

    if (result['success']) {
      final user = result['user'] as UserModel?;
      if (user != null) saveUserToCache(user);
      return true;
    } else {
      SnackBarUtils.showErrorSnackbar(result['message']);
      return false;
    }
  }

  Future<bool> login() async {
    _logStackTrace('login');
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      SnackBarUtils.showErrorSnackbar('Please enter email and password.');
      return false;
    }

    isLoading.value = true;
    final result = await AuthServices.login(email: email, password: password);

    if (result['success']) {
      final user = result['user'] as UserModel?;
      if (user != null) {
        saveUserToCache(user);
        _storage.write('isSetupDone', true);

        // ✅ Initialize word learning session after login
        try {
          final wordController = Get.find<WordController>();
          await wordController.initializeAfterLogin();
          Log.debug("✅ Post-login initialization completed");
        } catch (e, st) {
          Log.debug("⚠️ Error during post-login initialization: $e\n$st");
        }

        isLoading.value = false;
        return true;
      }
    }

    isLoading.value = false;
    SnackBarUtils.showErrorSnackbar(result['message']);
    return false;
  }


  Future<bool> updateUserData({
    String? firstName,
    String? lastName,
    String? email,
    String? image,
    LanguageModel? nativeLanguage,
    LearningLanguageModel? currentLearning,
    List<LearningLanguageModel>? learnedLanguages,
    List<SubscriptionModel>? subscription,
    bool showLoading = true,
    String? fcmToken,
  }) async {
    _logStackTrace('updateUserData');
    Log.info('Learning Language Update: ${currentLearning?.toMap()}');
    if (showLoading) isLoading.value = true;

    final result = await AuthServices.updateUserData(
      firstName: firstName,
      lastName: lastName,
      email: email,
      image: image,
      nativeLanguage: nativeLanguage,
      currentLearning: currentLearning,
      learnedLanguages: learnedLanguages,
      subscription: subscription,
      fcmToken: fcmToken,
    );

    isLoading.value = false;

    if (result['success']) {
      final updatedUser = result['user'] as UserModel?;
      if (updatedUser != null) {
        saveUserToCache(updatedUser);
        if (currentLearning != null) {
          _handleLearningProgressUpdate(currentLearning);
        }
      }
      return true;
    } else {
      SnackBarUtils.showErrorSnackbar(result['message']);
      return false;
    }
  }

  void _handleLearningProgressUpdate(LearningLanguageModel updatedLearning) {
    _logStackTrace('_handleLearningProgressUpdate');
    final previousLearning = currentUser.value?.currentLearning;
    if (previousLearning?.lastPracticeAt != null &&
        updatedLearning.lastPracticeAt != null) {
      final prevDate = DateTime(
        previousLearning!.lastPracticeAt!.year,
        previousLearning.lastPracticeAt!.month,
        previousLearning.lastPracticeAt!.day,
      );
      final newDate = DateTime(
        updatedLearning.lastPracticeAt!.year,
        updatedLearning.lastPracticeAt!.month,
        updatedLearning.lastPracticeAt!.day,
      );
      if (newDate.isAfter(prevDate)) {
        Log.debug('📅 New practice day detected — cache will be refreshed.');
      }
    }
  }

  Map<String, dynamic> getLearningStreak() {
    _logStackTrace('getLearningStreak');
    final lastPractice = currentUser.value?.currentLearning?.lastPracticeAt;
    if (lastPractice == null) {
      return {'streak': 0, 'lastPractice': null, 'practicedToday': false};
    }

    final now = DateTime.now();
    final lastPracticeDate = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
    final today = DateTime(now.year, now.month, now.day);

    final daysDifference = today.difference(lastPracticeDate).inDays;
    final practicedToday = daysDifference == 0;

    return {
      'streak': practicedToday ? 1 : 0,
      'lastPractice': lastPractice,
      'practicedToday': practicedToday,
      'daysSinceLastPractice': daysDifference,
    };
  }

  Future<String?> uploadProfileImage(String filePath) async {
    _logStackTrace('uploadProfileImage');
    try {
      isLoading.value = true;
      final imageUrl = await AuthServices.uploadProfileImage(filePath);
      isLoading.value = false;
      if (imageUrl == null) {
        Log.debug("❌ Controller: Image upload failed — returning null");
        return null;
      }
      Log.debug("✅ Controller: Image upload success — $imageUrl");
      return imageUrl;
    } catch (e) {
      isLoading.value = false;
      SnackBarUtils.showErrorSnackbar('Error uploading image: $e');
      return null;
    }
  }

  /// Send password reset email
  RxString resetPasswordErrorMessage = ''.obs;
  Future<bool> sendPasswordResetEmail() async {
    _logStackTrace('sendPasswordResetEmail');

    final email = resetEmailController.text.trim();

    if (email.isEmpty) {
      resetPasswordErrorMessage.value='Please enter your email address.';
      //SnackBarUtils.showErrorSnackbar('Please enter your email address.',);
      return false;
    }

    if (!email.isEmail) {
      resetPasswordErrorMessage.value='Please enter a valid email address.';
      //SnackBarUtils.showErrorSnackbar('Please enter a valid email address.');
      return false;
    }

    try {
      isLoading.value = true;

      await AuthServices.sendPasswordResetEmail(email);

      isLoading.value = false;
      resetPasswordErrorMessage.value='';
      SnackBarUtils.showSuccessSnackbar('Password reset link sent to your email!');
      emailController.clear();
      return true;

    } catch (e, st) {
      isLoading.value = false;
      Log.debug('❌ Error sending password reset email: $e');
      resetPasswordErrorMessage.value='Error: $e';
      //SnackBarUtils.showErrorSnackbar('Failed to send reset email. Please try again.');
      return false;
    }
  }

// ============================================
// FIXED: logout method in AuthController
// ============================================
  Future<void> logout(BuildContext context) async {
    _logStackTrace('logout');
    try {
      isLoading.value = true;

      Log.debug('👋 Starting logout process...');

      final user = currentUser.value;

      // ✅ CRITICAL: Save current learning progress before logout
      if (user?.currentLearning != null) {
        Log.debug('💾 Saving current learning progress before logout');

        final currentLearning = user!.currentLearning!;
        final languageName = currentLearning.languageName;

        if (languageName != null && languageName.isNotEmpty) {
          try {
            // Save to language subcollection
            await AuthServices.saveLanguageProgress(
              languageName: languageName,
              learningData: currentLearning,
            );

            Log.debug('✅ Progress saved for $languageName');
            Log.debug('   - Last practice: ${currentLearning.lastPracticeAt}');
            Log.debug('   - Total words: ${currentLearning.totalWordsLearned}');
            Log.debug('   - Current category: ${currentLearning.currentCategory}');
          } catch (e) {
            Log.debug('⚠️ Error saving progress: $e');
            // Continue with logout even if save fails
          }
        }
      }

      // ✅ Clear all language caches (fixed to avoid concurrent modification)
      clearAllLanguageCaches();
      Log.debug('🗑️ Cleared all language caches');

      // ✅ Clear user data and other caches safely
      try {
        // Get all keys first (convert to list)
        final allKeys = _storage.getKeys().toList();

        // Filter keys to remove
        final keysToRemove = allKeys.where((key) {
          return key == 'currentUser' ||
              key == 'isSetupDone' ||
              key == 'fcm_token' ||
              key.startsWith('today_words_') ||
              key.startsWith('last_practice_') ||
              key.startsWith('word_cache_');
        }).toList();

        Log.debug('🗑️ Removing ${keysToRemove.length} cache keys');

        // Remove all keys
        for (var key in keysToRemove) {
          _storage.remove(key);
        }

        Log.debug('✅ Cleared local storage');
      } catch (e, st) {
        Log.debug('⚠️ Error clearing storage: $e\n$st');
        // Try alternative cleanup
        try {
          _storage.remove('currentUser');
          _storage.remove('isSetupDone');
          _storage.remove('fcm_token');
        } catch (e2) {
          Log.debug('⚠️ Error in fallback cleanup: $e2');
        }
      }

      // Reset controller state
      currentUser.value = null;
      isLogin.value = false;
      emailController.clear();
      passwordController.clear();
      firstNameController.clear();
      lastNameController.clear();

      // Sign out from Firebase
      await AuthServices.logout();
      Log.debug('🔓 Signed out from Firebase');

      // ✅ Try to dispose word controller if it exists
      try {
        if (Get.isRegistered<WordController>()) {
          final wordController = Get.find<WordController>();
          wordController.wordsList.clear();
          wordController.hasError.value = false;
          wordController.errorMessage.value = '';
          Log.debug('🗑️ Cleared word controller state');
        }
      } catch (e) {
        Log.debug('⚠️ Error clearing word controller: $e');
      }

      isLoading.value = false;

      // Navigate to onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.oboarding);

      Log.debug('✅ User logged out successfully');

    } catch (e, st) {
      Log.debug('❌ Error during logout: $e\n$st');
      isLoading.value = false;
      SnackBarUtils.showErrorSnackbar('Failed to logout. Please try again.');
    }
  }



  void clearAllUserData() {
    _logStackTrace('clearAllUserData');
    _storage.erase();
    currentUser.value = null;
    isLogin.value = false;
    Log.debug('🗑️ All user data cleared');
  }
}