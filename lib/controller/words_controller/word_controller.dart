import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/services/background_task_services.dart';
import '../../core/services/seen_saved_words_services.dart';
import '../../core/services/words_services.dart';
import '../../model/word_model.dart';
import '../../model/saved_seen_word_model.dart';
import '../../model/user_model.dart';
import '../../view/Home/home_widget_service.dart';
import '../AuthController/auth_controller.dart';
import '../SettingController/topic_controller.dart';

class WordController extends GetxController {
  final authController = Get.find<AuthController>();
  final topicController = Get.find<TopicController>();
  final WordService _wordService = WordService();
  final SeenSavedWordsService _seenSavedWordsService = SeenSavedWordsService();
  final box = GetStorage();
  String? currentPath;
  String? currentCategoryId;
  String? currentCategoryName;

  RxList<WordModel> wordsList = <WordModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;

  // ✅ NEW: Daily progress tracking
  RxInt totalWordsToShowToday = 0.obs;
  RxInt wordsShownSoFar = 0.obs;
  RxDouble dailyProgressPercentage = 0.0.obs;

  // ✅ Seen and Saved words tracking
  RxSet<String> seenWordIds = <String>{}.obs;
  RxSet<String> savedWordIds = <String>{}.obs;

  // ✅ Store full objects, not just IDs
  RxList<SavedSeenWordModel> seenWordsList = <SavedSeenWordModel>[].obs;
  RxList<SavedSeenWordModel> savedWordsList = <SavedSeenWordModel>[].obs;

  // ✅ Current category progress tracking
  Rx<CategoryProgressModel?> currentCategoryProgress = Rx<CategoryProgressModel?>(null);

  // ✅ Flag to prevent multiple simultaneous fetches
  bool _isFetching = false;

  // ✅ Debounce timer for reactive updates
  Worker? _authWorker;
  Worker? _topicWorker;

  @override
  Future<void> onInit() async {
    super.onInit();
    Log.debug("🚀 WordController initialized — syncing with AuthController...");

   await _initializeWordFetch();
   await loadSeenAndSavedWords();
   _updateDailyProgress();
    Future.delayed(const Duration(seconds: 5), () {
      getDailyProgressStats();
    });
  }

  /// ✅ NEW: Update daily progress based on current time slot
  void _updateDailyProgress() {
    try {
      final displayTime = box.read('displayTime');
      final totalWords = wordsList.length;

      if (totalWords == 0) {
        wordsShownSoFar.value = 0;
        dailyProgressPercentage.value = 0.0;
        return;
      }

      // Get current time slot
      final currentSlot = BackgroundTaskService.getCurrentTimeSlot(
        totalWords,
        displayTime: displayTime,
      );

      if (currentSlot < 0) {
        // Outside display time range
        wordsShownSoFar.value = 0;
        dailyProgressPercentage.value = 0.0;
        return;
      }

      // Words shown = current slot + 1 (because slots are 0-indexed)
      wordsShownSoFar.value = (currentSlot + 1).clamp(0, totalWords);

      // // Calculate percentage
      // if (totalWordsToShowToday.value > 0) {
      //   dailyProgressPercentage.value =
      //       (wordsShownSoFar.value / totalWordsToShowToday.value * 100).clamp(0.0, 100.0);
      // } else {
      //   dailyProgressPercentage.value = 0.0;
      // }

      Log.debug("📊 Daily progress updated:");
      Log.debug("   - Current slot: $currentSlot");
      Log.debug("   - Words shown: ${wordsShownSoFar.value}/${totalWordsToShowToday.value}");
      Log.debug("   - Progress: ${dailyProgressPercentage.value.toStringAsFixed(1)}%");
    } catch (e) {
      Log.debug("❌ Error updating daily progress: $e");
    }
  }

  /// ✅ NEW: Get daily progress stats
  Map<String, dynamic> getDailyProgressStats() {
    return {
      'totalWordsToday': wordsList.length,
      'wordsShownSoFar': wordsShownSoFar.value,
      'wordsRemaining': (totalWordsToShowToday.value - wordsShownSoFar.value).clamp(0, totalWordsToShowToday.value),
      'progressPercentage': dailyProgressPercentage.value,
      'isCompleted': wordsShownSoFar.value >= totalWordsToShowToday.value,
    };
  }

  /// ✅ NEW: Manually refresh daily progress (call this from UI when needed)
  void refreshDailyProgress() {
    _updateDailyProgress();
  }


  /// ✅ FINAL FIX: Updated handleLanguageSwitch method
  Future<void> handleLanguageSwitch() async {
    Log.debug("🔄 Handling language switch...");

    try {
      // ✅ CRITICAL: Force reset the fetching flag
      _isFetching = false;

      // Clear error state
      hasError.value = false;
      errorMessage.value = '';

      // Clear current words list
      wordsList.clear();

      // Load seen/saved words for new language
      await loadSeenAndSavedWords();

      // Build new query path
      buildQueryPath();

      // Get user data
      final user = authController.currentUser.value;
      if (user?.currentLearning == null) {
        Log.debug("❌ No user or learning data");
        hasError.value = true;
        errorMessage.value = "Unable to load learning data";
        return;
      }

      final currentLearning = user!.currentLearning!;
      final currentLevel = currentLearning.currentLevel;

      if (currentLevel == null) {
        Log.debug("❌ No current level");
        hasError.value = true;
        errorMessage.value = "Please select a learning level";
        return;
      }

      // ✅ Check if this is a new language (no lastPracticeAt)
      final lastPracticeAt = currentLearning.lastPracticeAt;
      final isNewLanguage = lastPracticeAt == null;

      Log.debug("📅 Last practice: $lastPracticeAt");
      Log.debug("📅 Is new language: $isNewLanguage");

      if (!isNewLanguage) {
        // ✅ Check if already practiced TODAY
        final now = DateTime.now();
        final lastPracticeDate = DateTime(
          lastPracticeAt.year,
          lastPracticeAt.month,
          lastPracticeAt.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        final alreadyPracticedToday = today.isAtSameMomentAs(lastPracticeDate);

        Log.debug("📅 Already practiced today: $alreadyPracticedToday");

        if (alreadyPracticedToday) {
          // Try to get cached words for current language
          final cachedWords = authController.getCachedTodayWords();

          if (cachedWords.isNotEmpty) {
            Log.debug("✅ Found ${cachedWords.length} cached words");
            wordsList.assignAll(cachedWords);
            await _updateWidget(cachedWords);
            return;
          }

          // Try to fetch today's learned words
          Log.debug("📥 No cache - fetching learned words");
          final learnedWords = await _fetchTodayLearnedWordsSimple();

          if (learnedWords.isNotEmpty) {
            Log.debug("✅ Retrieved ${learnedWords.length} learned words");
            wordsList.assignAll(learnedWords);
            authController.cacheTodayWords(learnedWords);
            await _updateWidget(learnedWords);
            return;
          }

          // Already practiced in another language today
          Log.debug("⚠️ User practiced in another language today");
          hasError.value = true;
          errorMessage.value = "You've already practiced today! Come back tomorrow for more words.";
          wordsList.clear();
          return;
        }
      }

      // ✅ NEW LANGUAGE or HAVEN'T PRACTICED TODAY
      Log.debug("🆕 Fetching fresh words for switched language");

      // Check if categories are selected
      final levelProgress = currentLearning.getLevelProgress(currentLevel);

      if (levelProgress == null || levelProgress.selectedCategories.isEmpty) {
        Log.debug("⚠️ No categories selected - auto-selecting");
        await _autoSelectInitialCategories();
        // After auto-selection, try fetching again
        await Future.delayed(Duration(milliseconds: 500));
        await handleLanguageSwitch(); // Recursive call after setup
        return;
      }

      // ✅ Fetch fresh words
      await fetchWordList();

      Log.debug("✅ Language switch complete - ${wordsList.length} words loaded");

    } catch (e, st) {
      Log.debug("❌ Error handling language switch: $e\n$st");
      hasError.value = true;
      errorMessage.value = "Failed to load words";
      _isFetching = false; // Reset on error
    }
  }

  /// ✅ SIMPLIFIED ALTERNATIVE: Just fetch based on current category progress
  /// Use this if the above logic is too complex
  Future<List<WordModel>> _fetchTodayLearnedWordsSimple() async {
    try {
      final user = authController.currentUser.value;
      if (user?.currentLearning == null) {
        Log.debug("⚠️ No learning data available");
        return [];
      }

      final currentLearning = user!.currentLearning!;
      final wordsPerDay = currentLearning.wordsPerDay ?? 3;

      // Check if practiced today
      final lastPracticeAt = currentLearning.lastPracticeAt;
      if (lastPracticeAt == null) return [];

      final now = DateTime.now();
      final lastPracticeDate = DateTime(lastPracticeAt.year, lastPracticeAt.month, lastPracticeAt.day);
      final today = DateTime(now.year, now.month, now.day);

      if (!today.isAtSameMomentAs(lastPracticeDate)) {
        Log.debug("⚠️ Last practice was not today");
        return [];
      }

      // Get current category progress
      final categoryProgress = currentCategoryProgress.value;
      if (categoryProgress == null || categoryProgress.lastWordIndex == 0) {
        Log.debug("⚠️ No category progress found");
        return [];
      }

      if (currentPath == null || currentPath!.isEmpty) {
        Log.debug("❌ Invalid path");
        return [];
      }

      // ✅ Fetch the last N words learned (where N = wordsPerDay)
      final lastWordIndex = categoryProgress.lastWordIndex;
      final startIndex = (lastWordIndex - wordsPerDay + 1).clamp(1, lastWordIndex);
      final endIndex = lastWordIndex;

      Log.debug("📥 Fetching today's learned words:");
      Log.debug("   - Range: $startIndex to $endIndex");
      Log.debug("   - Path: $currentPath");

      final words = await _wordService.fetchWordsRange(
        path: currentPath!,
        startIndex: startIndex,
        endIndex: endIndex,
      );

      Log.debug("✅ Fetched ${words.length} already-learned words");
      return words;

    } catch (e, st) {
      Log.debug("❌ Error fetching today's learned words: $e\n$st");
      return [];
    }
  }

  /// ✅ FIX: Updated fetchWordList with proper widget initialization
  Future<void> fetchWordList({bool upgradedToPremium = false}) async {
    _logStackTrace('fetchWordList');

    try {
      final isSetupDone = box.read('isSetupDone') ?? false;
      Log.debug('Can Fetch Words - Setup Done: $isSetupDone');

      if (!isSetupDone) {
        Log.debug('⚠️ Setup not done yet. Exiting fetchWordList.');
        return;
      }
    } catch (e) {
      Log.debug("❌ Error reading setup status: $e");
      return;
    }

    Log.debug('🚀 Starting word fetch process...');

    if (currentPath == null || currentPath!.isEmpty) {
      Log.debug("❌ Cannot fetch words - invalid path");
      hasError.value = true;
      errorMessage.value = "Invalid query path";
      return;
    }

    if (_isFetching) {
      Log.debug("⏳ Already fetching words - waiting...");
      int waitCount = 0;
      while (_isFetching && waitCount < 50) {
        await Future.delayed(Duration(milliseconds: 100));
        waitCount++;
      }

      if (_isFetching) {
        Log.debug("⚠️ Previous fetch still running - forcing reset");
        _isFetching = false;
      } else {
        Log.debug("✅ Previous fetch completed - proceeding");
      }
    }

    _isFetching = true;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final user = authController.currentUser.value;
      if (user?.currentLearning == null) {
        throw Exception("No learning data available");
      }

      final alreadyPracticedToday = _hasAlreadyPracticedToday();

      final currentLearningLang = user!.currentLearning!.languageName ?? 'german';
      final nativeLang = user.nativeLanguage?.name ?? 'english';

      Log.debug("🌍 Languages: Learning=$currentLearningLang, Native=$nativeLang");

      // ✅ FIX: Always save language preferences before fetching
      await BackgroundTaskService.saveLanguagePreferences(
        sourceLang: currentLearningLang,
        targetLang: nativeLang,
      );

      // ✅ FIX: Ensure default display time is set
      final displayTime = box.read(BackgroundTaskService.DISPLAY_TIME_KEY);
      if (displayTime == null || displayTime.isEmpty) {
        await BackgroundTaskService.saveDisplayTime(BackgroundTaskService.DEFAULT_DISPLAY_TIME);
        Log.debug("✅ Set default display time: ${BackgroundTaskService.DEFAULT_DISPLAY_TIME}");
      }

      final wordsPerDay = user.currentLearning!.wordsPerDay ?? 1;

      Log.debug("📊 Fetch configuration:");
      Log.debug("   - Words per day: $wordsPerDay");
      Log.debug("   - Path: $currentPath");
      Log.debug("   - Category: $currentCategoryName");
      Log.debug("   - Already practiced today: $alreadyPracticedToday");
      Log.debug("   - Upgraded to Premium: $upgradedToPremium");

      if (alreadyPracticedToday && !upgradedToPremium) {
        Log.debug("🔒 User already practiced today — loading cached/learned words");

        final cachedWords = authController.getCachedTodayWords();

        if (cachedWords.isNotEmpty) {
          Log.debug("✅ Using ${cachedWords.length} words from cache");
          wordsList.assignAll(cachedWords);

          // ✅ FIX: Force widget update with cached words
          await _updateWidgetAfterFetch(cachedWords, currentLearningLang, nativeLang);

          isLoading.value = false;
          _isFetching = false;
          return;
        }

        Log.debug("📥 No cache found — fetching already-learned words from Firestore");

        final learnedWords = await _fetchTodayLearnedWords();

        if (learnedWords.isNotEmpty) {
          Log.debug("✅ Retrieved ${learnedWords.length} already-learned words");
          wordsList.assignAll(learnedWords);

          // ✅ FIX: Force widget update with learned words
          await _updateWidgetAfterFetch(learnedWords, currentLearningLang, nativeLang);

          isLoading.value = false;
          _isFetching = false;
          return;
        } else {
          Log.debug("⚠️ No learned words found for today");
          hasError.value = true;
          errorMessage.value = "You've already practiced today!";
          wordsList.clear();
          isLoading.value = false;
          _isFetching = false;
          return;
        }
      }

      Log.debug("🆕 New day detected — fetching fresh words");
      authController.clearTodayWordsCache();

      final allFetchedWords = await _fetchWordsAcrossCategories(wordsPerDay);

      if (allFetchedWords.isEmpty) {
        Log.debug("⚠️ No words available across all categories");
        hasError.value = true;
        errorMessage.value = "No words available. Please select more categories.";
        wordsList.clear();
        isLoading.value = false;
        _isFetching = false;
        return;
      }

      Log.debug("✅ Total words fetched across categories: ${allFetchedWords.length}");
      wordsList.assignAll(allFetchedWords);

      authController.cacheTodayWords(allFetchedWords);
      Log.debug("💾 Cached ${allFetchedWords.length} words for today");

      // ✅ FIX: Force widget update with fetched words
      await _updateWidgetAfterFetch(allFetchedWords, currentLearningLang, nativeLang);

      Log.debug("🎨 Home widget updated with latest words");

      // ✅ FIX: Initialize background service AFTER widget is updated
      await BackgroundTaskService.initialize();
      Log.debug("🔄 Background service initialized");

      await markWordsAsSeen(allFetchedWords);

    } catch (e, st) {
      Log.debug("❌ Error fetching words: $e\n$st");
      hasError.value = true;
      errorMessage.value = "Error loading words: ${e.toString()}";
      wordsList.clear();
    } finally {
      isLoading.value = false;
      _isFetching = false;
    }
  }

  /// ✅ NEW: Centralized widget update after fetch
  Future<void> _updateWidgetAfterFetch(
      List<WordModel> words,
      String sourceLang,
      String targetLang,
      ) async {
    try {
      Log.debug('\n🎨 Updating widget after fetch...');
      Log.debug('   - Words count: ${words.length}');
      Log.debug('   - Source: $sourceLang');
      Log.debug('   - Target: $targetLang');

      // Get display time
      final displayTime = box.read(BackgroundTaskService.DISPLAY_TIME_KEY) ??
          BackgroundTaskService.DEFAULT_DISPLAY_TIME;

      Log.debug('   - Display time: $displayTime');

      // Update widget with words list
      await HomeWidgetService.updateWidgetWithWordsList(
        words: words,
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: displayTime,
      );

      Log.debug('✅ Widget update after fetch complete');

      // ✅ FIX: Force additional update for iOS
      if (Platform.isIOS) {
        await Future.delayed(Duration(milliseconds: 500));
        await HomeWidgetService.forceUpdate();
        Log.debug('✅ iOS: Additional force update complete');
      }

    } catch (e, st) {
      Log.debug('❌ Error updating widget after fetch: $e\n$st');
    }
  }

// ✅ ALSO UPDATE: Your existing _updateWidget method
  Future<void> _updateWidget(List<WordModel> words) async {
    try {
      final user = authController.currentUser.value;
      if (user == null) return;

      final currentLearningLang = user.currentLearning?.languageName ?? 'german';
      final nativeLang = user.nativeLanguage?.name ?? 'english';

      // ✅ FIX: Always get display time from storage
      final displayTime = box.read(BackgroundTaskService.DISPLAY_TIME_KEY) ??
          BackgroundTaskService.DEFAULT_DISPLAY_TIME;

      Log.debug('🎨 Updating widget:');
      Log.debug('   - Words: ${words.length}');
      Log.debug('   - Languages: $currentLearningLang → $nativeLang');
      Log.debug('   - Display time: $displayTime');

      await HomeWidgetService.updateWidgetWithWordsList(
        words: words,
        sourceLang: currentLearningLang,
        targetLang: nativeLang,
        displayTime: displayTime,
      );

      Log.debug('✅ Widget update complete');
    } catch (e, st) {
      Log.debug("❌ Error updating widget: $e\n$st");
    }
  }



// ✅ ADD TO YOUR MAIN.DART:
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // ✅ Initialize widgets before running app
  final wordController = Get.put(WordController());
  await wordController.initializeWidgetsOnAppStart();

  runApp(MyApp());
}
*/

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

  /// ✅ NEW: Fetch words across multiple categories if current category runs out
  Future<List<WordModel>> _fetchWordsAcrossCategories(int totalNeeded) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return [];

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return [];

    List<WordModel> allWords = [];
    int remainingNeeded = totalNeeded;

    // ✅ Get all selected categories in order
    final selectedCategories = user.currentLearning!.getSelectedCategories();

    if (selectedCategories.isEmpty) {
      Log.debug("⚠️ No selected categories found - auto-selecting from allTopics");
      await _autoSelectNextCategory();
      return [];
    }

    // ✅ Start with current active category
    final startCategoryIndex = selectedCategories.indexWhere((c) => c.isActive);
    final orderedCategories = [
      ...selectedCategories.sublist(startCategoryIndex >= 0 ? startCategoryIndex : 0),
      if (startCategoryIndex > 0) ...selectedCategories.sublist(0, startCategoryIndex),
    ];

    Log.debug("📚 Fetching from ${orderedCategories.length} categories in order");

    for (var category in orderedCategories) {
      if (remainingNeeded <= 0) break;

      Log.debug("📖 Checking category: ${category.categoryName} (isCompleted: ${category.isCompleted})");

      // Skip completed categories
      if (category.isCompleted) {
        Log.debug("   ⏭️ Skipping completed category");
        continue;
      }

      // Build path for this category
      final categoryPath = _wordService.buildPath(
        learningLang: user.currentLearning!.languageName ?? 'german',
        level: currentLevel,
        topic: category.categoryName,
        contentType: user.currentLearning!.contentType ?? 1,
      );

      if (categoryPath == null) {
        Log.debug("   ❌ Failed to build path for category");
        continue;
      }

      // Get progress for this category
      final categoryProgress = user.currentLearning!.getCategoryProgress(
        currentLevel,
        category.categoryId,
      );

      final lastWordIndex = categoryProgress?.lastWordIndex ?? 0;
      final startIndex = lastWordIndex + 1;

      Log.debug("   📍 Start index: $startIndex");

      // Check how many words are available
      final totalAvailable = await _wordService.getTotalWordCount(categoryPath);
      final availableWords = totalAvailable - lastWordIndex;

      Log.debug("   📊 Available words: $availableWords (total: $totalAvailable)");

      if (availableWords <= 0) {
        Log.debug("   ⚠️ No words available - marking as completed");
        await _markCategoryAsCompletedAndMoveNext(
          categoryId: category.categoryId,
          categoryName: category.categoryName,
          totalWords: totalAvailable,
        );
        continue;
      }

      // Fetch words from this category
      final wordsToFetch = remainingNeeded < availableWords ? remainingNeeded : availableWords;

      Log.debug("   🔍 Fetching $wordsToFetch words from this category");

      final fetchedWords = await _wordService.fetchWords(
        path: categoryPath,
        limit: wordsToFetch,
        startAfterIndex: startIndex,
      );

      if (fetchedWords.isEmpty) {
        Log.debug("   ⚠️ No words fetched - might be end of category");
        continue;
      }

      Log.debug("   ✅ Fetched ${fetchedWords.length} words");
      allWords.addAll(fetchedWords);
      remainingNeeded -= fetchedWords.length;

      // Update progress for this category
      final newLastWordIndex = startIndex + fetchedWords.length - 1;
      await _updateCategoryProgressForMultiFetch(
        categoryId: category.categoryId,
        categoryName: category.categoryName,
        newLastWordIndex: newLastWordIndex,
        fetchedWordsCount: fetchedWords.length,
      );

      // If category is now complete, mark it and activate next
      if (newLastWordIndex >= totalAvailable) {
        Log.debug("   🎉 Category completed during fetch!");
        await _markCategoryAsCompletedAndMoveNext(
          categoryId: category.categoryId,
          categoryName: category.categoryName,
          totalWords: totalAvailable,
        );
      }
    }

    // ✅ If still need more words and all selected categories exhausted
    if (remainingNeeded > 0) {
      Log.debug("⚠️ Still need $remainingNeeded words - all selected categories exhausted");
      Log.debug("🔄 Auto-selecting next category from allTopics");

      await _autoSelectNextCategory();

      // Retry fetch after auto-selection
      if (remainingNeeded > 0 && allWords.isNotEmpty) {
        Log.debug("✅ Continuing with ${allWords.length} words fetched so far");
      }
    }

    Log.debug("✅ Total words fetched: ${allWords.length}");
    return allWords;
  }

  /// ✅ Update progress for a specific category during multi-fetch
  Future<void> _updateCategoryProgressForMultiFetch({
    required String categoryId,
    required String categoryName,
    required int newLastWordIndex,
    required int fetchedWordsCount,
  }) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return;

    try {
      final existingProgress = user.currentLearning!.getCategoryProgress(
        currentLevel,
        categoryId,
      ) ?? CategoryProgressModel(
        categoryName: categoryName,
        categoryId: categoryId,
        startedAt: DateTime.now(),
      );

      final newWordsCount = existingProgress.learnedWordsCount + fetchedWordsCount;

      final updatedCategoryProgress = existingProgress.copyWith(
        lastWordIndex: newLastWordIndex,
        learnedWordsCount: newWordsCount,
      );

      var updatedLearning = user.currentLearning!.updateCategoryProgress(
        levelName: currentLevel,
        categoryProgress: updatedCategoryProgress,
      );

      // Update lastPracticeAt only once at language level
      updatedLearning = updatedLearning.copyWith(
        lastPracticeAt: DateTime.now(),
      );

      await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      Log.debug("✅ Updated progress for category: $categoryName");
      Log.debug("   - Last word index: $newLastWordIndex");
      Log.debug("   - Words learned: $newWordsCount");
    } catch (e, st) {
      Log.debug("❌ Error updating category progress: $e\n$st");
    }
  }


  /// ✅ Auto-select next category from allTopics when selected categories are exhausted
  Future<void> _autoSelectNextCategory() async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return;

    try {
      final topicController = Get.find<TopicController>();
      final allTopics = topicController.allTopics;
      final selectedCategories = user.currentLearning!.getSelectedCategories();

      // Find topics not yet selected
      final selectedTopicNames = selectedCategories.map((c) => c.categoryName).toSet();
      final availableTopics = allTopics.where((topic) => !selectedTopicNames.contains(topic)).toList();

      if (availableTopics.isEmpty) {
        Log.debug("🏆 All topics completed!");
        hasError.value = true;
        errorMessage.value = "Congratulations! You've completed all categories!";
        return;
      }

      final nextTopic = availableTopics.first;
      Log.debug("🆕 Auto-selecting next topic: $nextTopic");

      // Add the new topic
      final newCategory = SelectedCategoryModel(
        categoryName: nextTopic,
        categoryId: _generateCategoryId(nextTopic),
        orderIndex: selectedCategories.length,
        isActive: true,
        isCompleted: false,
        addedAt: DateTime.now(),
      );

      // Deactivate all current categories
      final updatedCategories = selectedCategories.map((cat) {
        return cat.copyWith(isActive: false);
      }).toList();

      updatedCategories.add(newCategory);

      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
      if (levelProgress == null) return;

      levelProgress = levelProgress.copyWith(selectedCategories: updatedCategories);

      final updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress).copyWith(
        currentCategory: nextTopic,
      );

      await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      // Update local state
      currentCategoryId = newCategory.categoryId;
      currentCategoryName = newCategory.categoryName;
      buildQueryPath();

      // Update topic controller
      topicController.selectedTopics.add(nextTopic);

      Log.debug("✅ Auto-selected new topic: $nextTopic");

    } catch (e, st) {
      Log.debug("❌ Error auto-selecting next category: $e\n$st");
    }
  }

  Future<void> _markCategoryAsCompleted(int totalWords) async {
    if (currentCategoryId == null || currentCategoryName == null) {
      Log.debug("⚠️ Cannot mark category as completed - no category information");
      return;
    }

    final success = await completeCategoryAndMoveNext(totalWordsInCategory: totalWords);

    if (success) {
      final nextInfo = getSelectedCategoriesInfo();
      final nextCategory = nextInfo['nextCategory'];

      if (nextCategory != null) {
        Log.debug("📚 Moving to next category: ${nextCategory['name']}");

        hasError.value = false;
        errorMessage.value = "🎉 Category completed! Moving to: ${nextCategory['name']}";

        await Future.delayed(Duration(seconds: 1));
        await fetchWordList();
      } else {
        Log.debug("🏆 All categories completed!");
        hasError.value = true;
        errorMessage.value = "🏆 Congratulations! You've completed all selected categories in this level!";
      }
    }
  }



  /// ✅ Check if user practiced TODAY - ONLY from user model
  bool _hasAlreadyPracticedToday() {
    // ✅ ALWAYS get from user model's currentLearning
    final lastPractice = authController.currentUser.value?.currentLearning?.lastPracticeAt;

    if (lastPractice == null) {
      Log.debug("📅 No lastPractice found — User can practice");
      return false;
    }

    final now = DateTime.now();
    final lastPracticeDate = DateTime(lastPractice.year, lastPractice.month, lastPractice.day);
    final today = DateTime(now.year, now.month, now.day);

    final isPracticedToday = today.isAtSameMomentAs(lastPracticeDate);

    Log.debug("📅 Last practice: ${lastPracticeDate.toString()}");
    Log.debug("📅 Today: ${today.toString()}");
    Log.debug("📅 Already practiced today: $isPracticedToday");

    return isPracticedToday;
  }

  /// ✅ Fetch already learned words from Firestore for today
  Future<List<WordModel>> _fetchTodayLearnedWords() async {
    try {
      final user = authController.currentUser.value;
      if (user?.currentLearning == null) {
        Log.debug("⚠️ No learning data available");
        return [];
      }

      final wordsPerDay = user!.currentLearning!.wordsPerDay ?? 1;
      final categoryProgress = currentCategoryProgress.value;

      if (categoryProgress == null) {
        Log.debug("⚠️ No category progress found");
        return [];
      }

      final lastWordIndex = categoryProgress.lastWordIndex;

      if (lastWordIndex < wordsPerDay) {
        Log.debug("⚠️ Not enough words learned yet");
        return [];
      }

      // Calculate the range of words learned today
      // If lastWordIndex = 15 and wordsPerDay = 3, get words 13, 14, 15
      final startIndex = lastWordIndex - wordsPerDay + 1;
      final endIndex = lastWordIndex;

      Log.debug("📥 Fetching already-learned words:");
      Log.debug("   - Range: $startIndex to $endIndex");
      Log.debug("   - Path: $currentPath");

      if (currentPath == null || currentPath!.isEmpty) {
        Log.debug("❌ Invalid path");
        return [];
      }

      // Fetch the exact words user learned today
      final words = await _wordService.fetchWordsRange(
        path: currentPath!,
        startIndex: startIndex,
        endIndex: endIndex,
      );

      Log.debug("✅ Fetched ${words.length} already-learned words");
      return words;

    } catch (e, st) {
      Log.debug("❌ Error fetching today's learned words: $e\n$st");
      return [];
    }
  }

  Future<void> loadSeenAndSavedWords() async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";
    if (userId == null || userId.isEmpty) {
      Log.debug("⚠️ Cannot load seen/saved words - no userId");
      return;
    }

    try {
      final seenWords = await _seenSavedWordsService.getSeenWords(userId: userId, language: language);
      seenWordsList.assignAll(seenWords);
      seenWordIds.value = seenWords.map((w) => w.id).toSet();
      Log.debug("✅ Loaded ${seenWordsList.length} seen words");

      final savedWords = await _seenSavedWordsService.getSavedWords(userId: userId, language: language);
      savedWordsList.assignAll(savedWords);
      savedWordIds.value = savedWords.map((w) => w.id).toSet();
      Log.debug("✅ Loaded ${savedWordsList.length} saved words");
    } catch (e, st) {
      Log.debug("❌ Error loading seen/saved words: $e\n$st");
    }
  }

  Future<void> refreshSeenSavedStatus() async {
    await loadSeenAndSavedWords();
  }

  Future<bool> markWordAsSeen(WordModel word) async {
    final userId = authController.currentUser.value?.uid;
    final level = authController.currentUser.value?.currentLearning?.currentLevel;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";

    if (userId == null || userId.isEmpty) {
      Log.debug("❌ Cannot mark word as seen - missing userId");
      return false;
    }

    if (level == null || level.isEmpty) {
      Log.debug("❌ Cannot mark word as seen - missing level");
      return false;
    }

    if (word.id.isEmpty) {
      Log.debug("❌ Cannot mark word as seen - invalid word ID");
      return false;
    }

    if (seenWordIds.contains(word.id)) {
      Log.debug("⚠️ Word '${word.id}' already marked as seen");
      return true;
    }

    final success = await _seenSavedWordsService.addSeenWord(
      userId: userId,
      word: word,
      level: level,
      language: language,
    );

    if (success) {
      seenWordIds.add(word.id);
      Log.debug("✅ Marked word '${word.id}' as seen");
    } else {
      Log.debug("❌ Failed to mark word '${word.id}' as seen");
    }

    return success;
  }

  Future<bool> markWordsAsSeen(List<WordModel> words) async {
    if (words.isEmpty) {
      Log.debug("⚠️ No words to mark as seen");
      return true;
    }

    final userId = authController.currentUser.value?.uid;
    final level = authController.currentUser.value?.currentLearning?.currentLevel;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";

    if (userId == null || userId.isEmpty) {
      Log.debug("❌ Cannot mark words as seen - missing userId");
      return false;
    }

    if (level == null || level.isEmpty) {
      Log.debug("❌ Cannot mark words as seen - missing level");
      return false;
    }

    final unseenWords = words
        .where((w) => w.id.isNotEmpty && !seenWordIds.contains(w.id))
        .toList();

    if (unseenWords.isEmpty) {
      Log.debug("⚠️ All words already marked as seen or invalid");
      return true;
    }

    Log.debug("📝 Marking ${unseenWords.length} words as seen (out of ${words.length} total)");

    final success = await _seenSavedWordsService.addMultipleSeenWords(
      userId: userId,
      words: unseenWords,
      level: level,
      language: language,
    );

    if (success) {
      seenWordIds.addAll(unseenWords.map((w) => w.id));
      Log.debug("✅ Marked ${unseenWords.length} words as seen");
    } else {
      Log.debug("❌ Failed to mark words as seen");
    }

    return success;
  }

  Future<bool> saveWord(WordModel word) async {
    final userId = authController.currentUser.value?.uid;
    final level = authController.currentUser.value?.currentLearning?.currentLevel;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";

    if (userId == null || userId.isEmpty) {
      Log.debug("❌ Cannot save word - missing userId");
      return false;
    }

    if (level == null || level.isEmpty) {
      Log.debug("❌ Cannot save word - missing level");
      return false;
    }

    if (word.id.isEmpty) {
      Log.debug("❌ Cannot save word - invalid word ID");
      return false;
    }

    if (savedWordIds.contains(word.id)) {
      Log.debug("⚠️ Word '${word.id}' already saved");
      return true;
    }

    final success = await _seenSavedWordsService.saveWord(
      userId: userId,
      word: word,
      level: level,
      language: language,
    );

    if (success) {
      savedWordIds.add(word.id);
      Log.debug("✅ Saved word '${word.id}'");
    } else {
      Log.debug("❌ Failed to save word '${word.id}'");
    }

    return success;
  }

  Future<bool> unsaveWord(String wordId) async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";

    if (userId == null || userId.isEmpty) {
      Log.debug("❌ Cannot unsave word - missing userId");
      return false;
    }

    if (wordId.isEmpty) {
      Log.debug("❌ Cannot unsave word - invalid wordId");
      return false;
    }

    final success = await _seenSavedWordsService.unsaveWord(
      userId: userId,
      wordId: wordId,
      language: language,
    );

    if (success) {
      savedWordIds.remove(wordId);
      Log.debug("✅ Unsaved word '$wordId'");
    } else {
      Log.debug("❌ Failed to unsave word '$wordId'");
    }

    return success;
  }

  Future<bool> toggleSaveWord(WordModel word) async {
    if (word.id.isEmpty) {
      Log.debug("❌ Cannot toggle save - invalid word ID");
      return false;
    }

    if (savedWordIds.contains(word.id)) {
      return await unsaveWord(word.id);
    } else {
      return await saveWord(word);
    }
  }

  bool isWordSaved(String wordId) {
    return savedWordIds.contains(wordId);
  }

  bool isWordSeen(String wordId) {
    return seenWordIds.contains(wordId);
  }

  Future<List<SavedSeenWordModel>> getSavedWords({String? level, int? limit}) async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";
    if (userId == null || userId.isEmpty) {
      Log.debug("⚠️ Cannot get saved words - no userId");
      return [];
    }

    try {
      return await _seenSavedWordsService.getSavedWords(
        userId: userId,
        level: level,
        limit: limit,
        language: language,
      );
    } catch (e, st) {
      Log.debug("❌ Error getting saved words: $e\n$st");
      return [];
    }
  }

  Future<List<SavedSeenWordModel>> getSeenWords({String? level, int? limit}) async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";
    if (userId == null || userId.isEmpty) {
      Log.debug("⚠️ Cannot get seen words - no userId");
      return [];
    }

    try {
      return await _seenSavedWordsService.getSeenWords(
        userId: userId,
        level: level,
        limit: limit,
        language: language,
      );
    } catch (e, st) {
      Log.debug("❌ Error getting seen words: $e\n$st");
      return [];
    }
  }

  Future<Map<String, int>> getWordCounts() async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";
    if (userId == null || userId.isEmpty) {
      return {'seen': 0, 'saved': 0};
    }

    try {
      final seenCount = await _seenSavedWordsService.getSeenWordsCount(userId: userId, language: language);
      final savedCount = await _seenSavedWordsService.getSavedWordsCount(userId: userId, language: language);

      return {
        'seen': seenCount,
        'saved': savedCount,
      };
    } catch (e) {
      Log.debug("❌ Error getting word counts: $e");
      return {'seen': 0, 'saved': 0};
    }
  }

  Future<bool> clearAllSavedWords() async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";
    if (userId == null || userId.isEmpty) {
      Log.debug("❌ Cannot clear saved words - no userId");
      return false;
    }

    final success = await _seenSavedWordsService.clearSavedWords(userId: userId, language: language);
    if (success) {
      savedWordIds.clear();
      Log.debug("✅ Cleared all saved words");
    }
    return success;
  }

  Future<bool> clearAllSeenWords() async {
    final userId = authController.currentUser.value?.uid;
    final language = authController.currentUser.value?.currentLearning?.languageName ?? "";
    if (userId == null || userId.isEmpty) {
      Log.debug("❌ Cannot clear seen words - no userId");
      return false;
    }

    final success = await _seenSavedWordsService.clearSeenWords(userId: userId, language: language);
    if (success) {
      seenWordIds.clear();
      Log.debug("✅ Cleared all seen words");
    }
    return success;
  }

  Future<void> _initializeWordFetch() async {
    _logStackTrace('initializeWordFetch');
    if (_isFetching) {
      Log.debug("⏳ Already fetching, skipping...");
      return;
    }

    buildQueryPath();

    if (currentPath != null) {
      await fetchWordList();
    } else {
      Log.debug("⚠️ Cannot fetch words - no valid path");
      hasError.value = true;
      errorMessage.value = "Unable to build query path";
    }
  }

  String _generateCategoryId(String categoryName) {
    return categoryName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _loadCurrentCategoryProgress() {
    if (currentCategoryId == null) {
      currentCategoryProgress.value = null;
      return;
    }

    final level = authController.currentUser.value?.currentLearning?.currentLevel;
    if (level == null) {
      currentCategoryProgress.value = null;
      return;
    }

    currentCategoryProgress.value = authController.currentUser.value?.currentLearning
        ?.getCategoryProgress(level, currentCategoryId!);

    Log.debug("📊 Loaded category progress: ${currentCategoryProgress.value?.toMap()}");
  }




  /// ✅ Update learning progress (manual completion)
  Future<void> updateProgress({
    int? learnedWordsCount,
    int? previousDayLastWord,
    int? previousDayLastSentence,
  }) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("⚠️ Cannot update progress - no learning data");
      return;
    }

    try {
      final updatedLearning = user!.currentLearning!.copyWith(
        previousDayLastWord: previousDayLastWord ?? user.currentLearning!.previousDayLastWord,
        previousDayLastSentence: previousDayLastSentence ?? user.currentLearning!.previousDayLastSentence,
        lastPracticeAt: DateTime.now(),
      );

      await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      Log.debug("✅ Learning progress updated");
    } catch (e, st) {
      Log.debug("❌ Error updating progress: $e\n$st");
    }
  }


  /// ✅ Get all categories progress for current level
  List<Map<String, dynamic>> getAllCategoriesProgress() {
    final currentLearning = authController.currentUser.value?.currentLearning;
    if (currentLearning == null) return [];

    final level = currentLearning.currentLevel;
    if (level == null) return [];

    final levelProgress = currentLearning.getLevelProgress(level);
    if (levelProgress == null) return [];

    return levelProgress.categoryProgress.map((cat) => cat.toMap()).toList();
  }

  /// ✅ Get all levels progress
  List<Map<String, dynamic>> getAllLevelsProgress() {
    final currentLearning = authController.currentUser.value?.currentLearning;
    if (currentLearning == null) return [];

    return currentLearning.levelProgress?.map((level) => level.toMap()).toList() ?? [];
  }


  /// ✅ Force fetch new words (admin/testing purposes)
  Future<void> forceRefetchNewWords() async {
    Log.debug("🔄 Force refetching new words...");

    // Clear cache
    authController.clearTodayWordsCache();

    // Reset fetching flag
    _isFetching = false;

    // Fetch new words
    buildQueryPath();
    await fetchWordList();

    Log.debug("✅ Forced new word fetch completed");
  }

  /// ✅ Get specific word by ID
  Future<WordModel?> getWordById(int docId) async {
    if (currentPath == null || currentPath!.isEmpty) {
      Log.debug("❌ Cannot get word - no valid path");
      return null;
    }

    try {
      return await _wordService.fetchWordById(
        path: currentPath!,
        docId: docId,
      );
    } catch (e) {
      Log.debug("❌ Error getting word by ID: $e");
      return null;
    }
  }

  /// ✅ Check if more words available
  Future<bool> checkHasMoreWords() async {
    if (currentPath == null || currentPath!.isEmpty) {
      return false;
    }

    try {
      final lastIndex = currentCategoryProgress.value?.lastWordIndex ?? 0;

      return await _wordService.hasMoreWords(
        path: currentPath!,
        currentIndex: lastIndex,
      );
    } catch (e) {
      Log.debug("❌ Error checking for more words: $e");
      return false;
    }
  }

  /// ✅ Get total available words in current category
  Future<int> getTotalWordsCount() async {
    if (currentPath == null || currentPath!.isEmpty) {
      return 0;
    }

    try {
      return await _wordService.getTotalWordCount(currentPath!);
    } catch (e) {
      Log.debug("❌ Error getting total word count: $e");
      return 0;
    }
  }

  /// ✅ Get progress percentage for current category
  Future<double> getProgressPercentage() async {
    if (currentPath == null || currentCategoryProgress.value == null) {
      return 0.0;
    }

    try {
      final totalWords = await getTotalWordsCount();
      if (totalWords == 0) return 0.0;

      final learnedWords = currentCategoryProgress.value!.learnedWordsCount;
      return (learnedWords / totalWords * 100).clamp(0.0, 100.0);
    } catch (e) {
      Log.debug("❌ Error calculating progress: $e");
      return 0.0;
    }
  }

  /// ✅ Switch to different category
  Future<void> switchCategory(String categoryName) async {
    Log.debug("🔄 Switching to category: $categoryName");

    // Update current category in learning model
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("⚠️ Cannot switch category - no learning data");
      return;
    }

    final updatedLearning = user!.currentLearning!.copyWith(
      currentCategory: categoryName,
    );

    await authController.updateUserData(
      currentLearning: updatedLearning,
      showLoading: false,
    );

    // Rebuild query and fetch new words
    buildQueryPath();
    await fetchWordList();

    Log.debug("✅ Switched to category: $categoryName");
  }

  /// ✅ Switch to different level
  Future<void> switchLevel(String levelName) async {
    Log.debug("🔄 Switching to level: $levelName");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("⚠️ Cannot switch level - no learning data");
      return;
    }

    final updatedLearning = user!.currentLearning!.copyWith(
      currentLevel: levelName,
    );

    await authController.updateUserData(
      currentLearning: updatedLearning,
      showLoading: false,
    );

    // Rebuild query and fetch new words
    buildQueryPath();
    await fetchWordList();

    Log.debug("✅ Switched to level: $levelName");
  }

  @override
  void onClose() {
    Log.debug("🛑 WordController disposed");

    // Cancel workers to prevent memory leaks
    _authWorker?.dispose();
    _topicWorker?.dispose();

    super.onClose();
  }

  /// ✅ Check if current category is completed
  bool isCurrentCategoryCompleted() {
    return currentCategoryProgress.value?.isCompleted ?? false;
  }

  /// ✅ Create initial category progress
  Future<void> _createInitialCategoryProgress(
      String levelName,
      SelectedCategoryModel category,
      ) async {
    Log.debug("🆕 Creating initial category progress for: ${category.categoryName}");

    final newProgress = CategoryProgressModel(
      categoryName: category.categoryName,
      categoryId: category.categoryId,
      startedAt: DateTime.now(),
    );

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final updatedLearning = user!.currentLearning!.updateCategoryProgress(
      levelName: levelName,
      categoryProgress: newProgress,
    );

    final success = await authController.updateUserData(
      currentLearning: updatedLearning,
      showLoading: false,
    );

    if (success) {
      Log.debug("✅ Created initial category progress");
      currentCategoryProgress.value = newProgress;

      // Fetch words
      await fetchWordList();
    }
  }

  /// ✅ Get selected categories info
  Map<String, dynamic> getSelectedCategoriesInfo() {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      return {
        'total': 0,
        'completed': 0,
        'remaining': 0,
        'categories': [],
        'activeCategory': null,
        'nextCategory': null,
      };
    }

    final selectedCategories = user!.currentLearning!.getSelectedCategories();
    final completedCount = user.currentLearning!.getCompletedCategoriesCount();
    final activeCategory = user.currentLearning!.getActiveCategory();
    final nextCategory = user.currentLearning!.getNextCategory();

    return {
      'total': selectedCategories.length,
      'completed': completedCount,
      'remaining': selectedCategories.length - completedCount,
      'categories': selectedCategories.map((c) => {
        'name': c.categoryName,
        'id': c.categoryId,
        'orderIndex': c.orderIndex,
        'isActive': c.isActive,
        'isCompleted': c.isCompleted,
        'addedAt': c.addedAt,
      }).toList(),
      'activeCategory': activeCategory != null ? {
        'name': activeCategory.categoryName,
        'id': activeCategory.categoryId,
        'orderIndex': activeCategory.orderIndex,
      } : null,
      'nextCategory': nextCategory != null ? {
        'name': nextCategory.categoryName,
        'id': nextCategory.categoryId,
        'orderIndex': nextCategory.orderIndex,
      } : null,
    };
  }

  /// ✅ Add selected categories
  Future<bool> addSelectedCategories(List<String> categoryNames) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("⚠️ Cannot add categories - no learning data");
      return false;
    }

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) {
      Log.debug("⚠️ Cannot add categories - no level information");
      return false;
    }

    try {
      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel) ??
          LevelProgressModel(
            levelName: currentLevel,
            startedAt: DateTime.now(),
          );

      final selectedCategories = categoryNames.asMap().entries.map((entry) {
        final index = entry.key;
        final name = entry.value;
        return SelectedCategoryModel(
          categoryName: name,
          categoryId: _generateCategoryId(name),
          orderIndex: index,
          isActive: index == 0,
          isCompleted: false,
          addedAt: DateTime.now(),
        );
      }).toList();

      levelProgress = levelProgress.copyWith(
        selectedCategories: selectedCategories,
      );

      final updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress).copyWith(
        currentCategory: categoryNames.isNotEmpty ? categoryNames.first : null,
      );

      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        Log.debug("✅ Added ${categoryNames.length} selected categories");
        Log.debug("   Categories: ${categoryNames.join(', ')}");
        buildQueryPath();
        return true;
      }

      return false;
    } catch (e, st) {
      Log.debug("❌ Error adding selected categories: $e\n$st");
      return false;
    }
  }

  /// ✅ Get learning stats
  Map<String, dynamic> getLearningStats() {
    final currentLearning = authController.currentUser.value?.currentLearning;
    int wordsPerDay = authController.currentUser.value?.currentLearning?.wordsPerDay ?? 1;

    if (currentLearning == null) {
      return {
        'languageName': 'Not set',
        'currentLevel': 'N/A',
        'currentCategory': 'N/A',
        'wordsPerDay': 0,
        'totalWordsLearned': 0,
        'totalSentencesLearned': 0,
        'contentType': 1,
        'canPracticeToday': true,
        'currentPath': null,
        'hasError': hasError.value,
        'errorMessage': errorMessage.value,
        'seenWordsCount': seenWordIds.length,
        'savedWordsCount': savedWordIds.length,
        'categoryProgress': null,
        'alreadyPracticedToday': false,
      };
    }

    return {
      'languageName': currentLearning.languageName ?? 'Unknown',
      'currentLevel': currentLearning.currentLevel ?? 'A1',
      'currentCategory': currentCategoryName ?? 'N/A',
      'wordsPerDay': currentLearning.wordsPerDay ?? 1,
      'totalWordsLearned': currentLearning.totalWordsLearned ?? 0,
      'totalSentencesLearned': currentLearning.totalSentencesLearned ?? 0,
      'contentType': currentLearning.contentType ?? 1,
      'startedAt': currentLearning.startedAt,
      'lastPracticeAt': currentLearning.lastPracticeAt,
      'canPracticeToday': !_hasAlreadyPracticedToday(),
      'alreadyPracticedToday': _hasAlreadyPracticedToday(),
      'todayWordsCount': wordsList.length,
      'currentPath': currentPath,
      'hasError': hasError.value,
      'errorMessage': errorMessage.value,
      'wordIds': wordsList.map((w) => w.id).toList(),
      'seenWordsCount': seenWordIds.length,
      'savedWordsCount': savedWordIds.length,
      'categoryProgress': currentCategoryProgress.value?.toMap(),
      'categoryWordsLearned': currentCategoryProgress.value?.learnedWordsCount ?? 0,
      'categoryIsCompleted': currentCategoryProgress.value?.isCompleted ?? false,
      'levelProgress': currentLearning.levelProgress?.map((l) => l.toMap()).toList() ?? [],
    };
  }


  /// ✅ CRITICAL FIX: Initialize after language switch
  /// This handles the case where user switches languages mid-day
  Future<void> initializeAfterLanguageSwitch() async {
    Log.debug("🔄 Initializing after language switch...");

    try {
      final user = authController.currentUser.value;

      if (user == null || user.currentLearning == null) {
        Log.debug("⚠️ No user or learning data");
        hasError.value = true;
        errorMessage.value = "Please log in to continue";
        return;
      }

      final currentLearning = user.currentLearning!;
      final languageName = currentLearning.languageName ?? 'unknown';

      Log.debug("📚 Initializing for language: $languageName");
      Log.debug("   - Last practice: ${currentLearning.lastPracticeAt}");
      Log.debug("   - Words per day: ${currentLearning.wordsPerDay}");

      // ✅ CRITICAL: Check if user already practiced TODAY
      final alreadyPracticedToday = _hasAlreadyPracticedToday();
      Log.debug("   - Already practiced today: $alreadyPracticedToday");

      // ✅ Load seen and saved words for this language
      await loadSeenAndSavedWords();
      Log.debug("✅ Loaded seen words: ${seenWordIds.length}");
      Log.debug("✅ Loaded saved words: ${savedWordIds.length}");

      // ✅ Build query path
      buildQueryPath();

      if (currentPath == null || currentPath!.isEmpty) {
        Log.debug("❌ Failed to build query path");
        hasError.value = true;
        errorMessage.value = "Unable to load learning content";
        return;
      }

      Log.debug("✅ Query path built: $currentPath");

      // ✅ CRITICAL DECISION POINT:
      // If user practiced today, try to get cached words for THIS language
      if (alreadyPracticedToday) {
        Log.debug("🔒 User practiced today - checking for cached words");

        final cachedWords = authController.getCachedTodayWords();

        if (cachedWords.isNotEmpty) {
          // ✅ Cache exists for this language
          Log.debug("✅ Found ${cachedWords.length} cached words for $languageName");
          wordsList.assignAll(cachedWords);

          // Update widget
          final currentLearningLang = currentLearning.languageName ?? 'german';
          final nativeLang = user.nativeLanguage?.name ?? 'english';

         _updateWidget(cachedWords);

          hasError.value = false;
          errorMessage.value = '';
          Log.debug("✅ Language switch complete - showing cached words");
          return;
        } else {
          // ✅ No cache for this language - try to fetch learned words
          Log.debug("📥 No cache found - fetching today's learned words");

          final learnedWords = await _fetchTodayLearnedWords();

          if (learnedWords.isNotEmpty) {
            Log.debug("✅ Retrieved ${learnedWords.length} learned words");
            wordsList.assignAll(learnedWords);

            // Cache them
            authController.cacheTodayWords(learnedWords);

            // Update widget
            final currentLearningLang = currentLearning.languageName ?? 'german';
            final nativeLang = user.nativeLanguage?.name ?? 'english';

          _updateWidget(learnedWords);

            hasError.value = false;
            errorMessage.value = '';
            Log.debug("✅ Language switch complete - showing learned words");
            return;
          } else {
            // ✅ EDGE CASE: User practiced today but no words found
            // This means they switched from a language where they practiced to one they haven't
            Log.debug("⚠️ User practiced in another language today");
            Log.debug("📅 Showing message: Complete today's practice in other language first");

            hasError.value = true;
            errorMessage.value = "You've already practiced today! Come back tomorrow for more words.";
            wordsList.clear();
            return;
          }
        }
      }

      // ✅ User hasn't practiced today - fetch fresh words
      Log.debug("🆕 User hasn't practiced today - fetching fresh words");

      await initializeAfterLogin();

      Log.debug("✅ Language switch initialization completed!");

    } catch (e, st) {
      Log.debug("❌ Error initializing after language switch: $e\n$st");
      hasError.value = true;
      errorMessage.value = "Failed to initialize learning session";
    }
  }


// ============================================
// FIXED: initializeAfterLogin in WordController
// ============================================

  Future<void> initializeAfterLogin() async {
    Log.debug("🚀 Initializing learning session after login...");

    try {
      final user = authController.currentUser.value;

      if (user == null) {
        Log.debug("⚠️ No user found - cannot initialize");
        hasError.value = true;
        errorMessage.value = "Please log in to continue";
        return;
      }

      if (user.currentLearning == null) {
        Log.debug("⚠️ No learning data found - user needs to complete setup");
        hasError.value = true;
        errorMessage.value = "Please complete initial setup";
        return;
      }

      final currentLearning = user.currentLearning!;

      Log.debug("📚 Current Learning Data:");
      Log.debug("   - Language: ${currentLearning.languageName}");
      Log.debug("   - Level: ${currentLearning.currentLevel}");
      Log.debug("   - Category: ${currentLearning.currentCategory}");
      Log.debug("   - Words per day: ${currentLearning.wordsPerDay}");
      Log.debug("   - Last practice: ${currentLearning.lastPracticeAt}");
      Log.debug("   - Total words learned: ${currentLearning.totalWordsLearned}");

      final currentLevel = currentLearning.currentLevel;
      if (currentLevel == null || currentLevel.isEmpty) {
        Log.debug("⚠️ No level set");
        hasError.value = true;
        errorMessage.value = "Please select a learning level";
        return;
      }

      final levelProgress = currentLearning.getLevelProgress(currentLevel);

      if (levelProgress == null) {
        Log.debug("⚠️ No progress found for level: $currentLevel");
        await _createInitialLevelProgress(currentLevel);
        return;
      }

      Log.debug("📊 Level Progress ($currentLevel):");
      Log.debug("   - Total words learned: ${levelProgress.totalWordsLearned}");
      Log.debug("   - Selected categories: ${levelProgress.selectedCategories.length}");
      Log.debug("   - Category progress count: ${levelProgress.categoryProgress.length}");

      // ✅ FIX: Validate totalWordsLearned against actual category progress
      final actualWordsLearned = levelProgress.categoryProgress
          .fold<int>(0, (sum, cat) => sum + cat.learnedWordsCount);

      Log.debug("   - Actual words from categories: $actualWordsLearned");
      Log.debug("   - Recorded total: ${levelProgress.totalWordsLearned}");

      // If mismatch detected, fix it
      if (actualWordsLearned != levelProgress.totalWordsLearned) {
        Log.debug("⚠️ Word count mismatch detected! Fixing...");
        await _fixWordCountMismatch(currentLevel, actualWordsLearned);
      }

      // ✅ CRITICAL FIX: If no selected categories, auto-select from allTopics
      if (levelProgress.selectedCategories.isEmpty) {
        Log.debug("⚠️ No categories selected - auto-selecting from allTopics");
        await _autoSelectInitialCategories();
        return;
      }

      // ✅ CRITICAL FIX: Use currentCategory from user model, not just isActive flag
      SelectedCategoryModel? activeCategory;

      // First, try to find by currentCategory name
      if (currentLearning.currentCategory != null && currentLearning.currentCategory!.isNotEmpty) {
        try {
          activeCategory = levelProgress.selectedCategories.firstWhere(
                (c) => c.categoryName == currentLearning.currentCategory,
          );
          Log.debug("✅ Found active category by name: ${activeCategory.categoryName}");
        } catch (e) {
          Log.debug("⚠️ Current category not found in selected categories");
        }
      }

      // If not found, try to find by isActive flag
      if (activeCategory == null) {
        try {
          activeCategory = levelProgress.selectedCategories.firstWhere((c) => c.isActive);
          Log.debug("✅ Found active category by isActive flag: ${activeCategory.categoryName}");
        } catch (e) {
          Log.debug("⚠️ No category marked as active");
        }
      }

      // If still not found, find first incomplete
      if (activeCategory == null) {
        activeCategory = _findFirstIncompleteCategory(levelProgress);
      }

      if (activeCategory == null) {
        Log.debug("⚠️ No valid active category found - activating first incomplete");
        await _activateFirstIncompleteCategory(levelProgress);
        return;
      }

      Log.debug("📂 Active Category:");
      Log.debug("   - Name: ${activeCategory.categoryName}");
      Log.debug("   - Order Index: ${activeCategory.orderIndex}");
      Log.debug("   - Is completed: ${activeCategory.isCompleted}");

      // ✅ Get category progress
      final categoryProgress = levelProgress.getCategoryProgress(activeCategory.categoryId);

      if (categoryProgress != null) {
        Log.debug("📈 Category Progress:");
        Log.debug("   - Words learned: ${categoryProgress.learnedWordsCount}");
        Log.debug("   - Last word index: ${categoryProgress.lastWordIndex}");
        Log.debug("   - Is completed: ${categoryProgress.isCompleted}");
        Log.debug("   - Progress percentage: ${categoryProgress.progressPercentage}");
      }

      // ✅ FIX: Verify category completion status
      if (categoryProgress != null && !categoryProgress.isCompleted) {
        // Check if category should be marked as completed
        final categoryPath = _wordService.buildPath(
          learningLang: currentLearning.languageName ?? 'german',
          level: currentLevel,
          topic: activeCategory.categoryName,
          contentType: currentLearning.contentType ?? 1,
        );

        if (categoryPath != null) {
          final totalWordsInCategory = await _wordService.getTotalWordCount(categoryPath);

          Log.debug("   - Total words in category: $totalWordsInCategory");
          Log.debug("   - Last word index: ${categoryProgress.lastWordIndex}");

          // ✅ If user has completed all words but category not marked complete
          if (categoryProgress.lastWordIndex >= totalWordsInCategory && !categoryProgress.isCompleted) {
            Log.debug("🔧 Category should be completed but isn't marked - fixing...");
            await _markCategoryAsCompletedAndMoveNext(
              categoryId: activeCategory.categoryId,
              categoryName: activeCategory.categoryName,
              totalWords: totalWordsInCategory,
            );
            // After fixing, reinitialize
            await initializeAfterLogin();
            return;
          }
        }
      }

      // ✅ If current category is completed, move to next
      if (categoryProgress?.isCompleted ?? activeCategory.isCompleted) {
        Log.debug("🎉 Current category is completed!");

        final nextCategory = _findNextIncompleteCategory(levelProgress);
        if (nextCategory != null) {
          Log.debug("➡️ Moving to next category: ${nextCategory.categoryName}");
          await switchToCategory(nextCategory.categoryName);
          return;
        } else {
          Log.debug("⚠️ All selected categories completed - auto-selecting new category");
          await _autoSelectNextCategory();
          return;
        }
      }

      // ✅ CRITICAL FIX: Ensure currentCategory in user model matches active category
      if (currentLearning.currentCategory != activeCategory.categoryName) {
        Log.debug("🔧 Fixing currentCategory mismatch:");
        Log.debug("   - User model: ${currentLearning.currentCategory}");
        Log.debug("   - Active category: ${activeCategory.categoryName}");

        final updatedLearning = currentLearning.copyWith(
          currentCategory: activeCategory.categoryName,
        );

        await authController.updateUserData(
          currentLearning: updatedLearning,
          showLoading: false,
        );
      }

      // ✅ Update local state with correct active category
      currentCategoryId = activeCategory.categoryId;
      currentCategoryName = activeCategory.categoryName;
      currentCategoryProgress.value = categoryProgress;

      // ✅ Load seen and saved words
      await loadSeenAndSavedWords();
      Log.debug("✅ Loaded seen words: ${seenWordIds.length}");
      Log.debug("✅ Loaded saved words: ${savedWordIds.length}");

      // ✅ Build query path
      buildQueryPath();

      if (currentPath == null || currentPath!.isEmpty) {
        Log.debug("❌ Failed to build query path");
        hasError.value = true;
        errorMessage.value = "Unable to load learning content";
        return;
      }

      Log.debug("✅ Query path built: $currentPath");

      // ✅ Check if user practiced today
      final alreadyPracticedToday = _hasAlreadyPracticedToday();
      Log.debug("📅 Already practiced today: $alreadyPracticedToday");

      if (alreadyPracticedToday) {
        // Try to get cached words first
        final cachedWords = authController.getCachedTodayWords();

        if (cachedWords.isNotEmpty) {
          Log.debug("✅ Using ${cachedWords.length} cached words");
          wordsList.assignAll(cachedWords);
          await _updateWidget(cachedWords);
          return;
        }

        // No cache - fetch today's learned words
        Log.debug("📥 Fetching today's learned words");
        final learnedWords = await _fetchTodayLearnedWords();

        if (learnedWords.isNotEmpty) {
          Log.debug("✅ Retrieved ${learnedWords.length} learned words");
          wordsList.assignAll(learnedWords);
          authController.cacheTodayWords(learnedWords);
          await _updateWidget(learnedWords);
          return;
        }

        // Already practiced but no words found
        hasError.value = true;
        errorMessage.value = "You've already practiced today! Come back tomorrow.";
        wordsList.clear();
        return;
      }

      // ✅ User hasn't practiced today - fetch fresh words
      await fetchWordList();

      Log.debug("✅ Learning session initialized successfully!");
      Log.debug("   - Current words: ${wordsList.length}");
      Log.debug("   - Current category: $currentCategoryName");

    } catch (e, st) {
      Log.debug("❌ Error initializing after login: $e\n$st");
      hasError.value = true;
      errorMessage.value = "Failed to initialize learning session";
    }
  }

// ============================================
// NEW: Helper method to find first incomplete category
// ============================================
  SelectedCategoryModel? _findFirstIncompleteCategory(LevelProgressModel levelProgress) {
    Log.debug("🔍 Finding first incomplete category...");

    // Sort categories by orderIndex
    final sortedCategories = levelProgress.selectedCategories.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    Log.debug("   - Total selected categories: ${sortedCategories.length}");

    // Find the first incomplete category
    for (var category in sortedCategories) {
      Log.debug("   - Checking category: ${category.categoryName} (Order: ${category.orderIndex})");

      // Get the actual progress for this category
      final progress = levelProgress.getCategoryProgress(category.categoryId);

      if (progress == null) {
        // No progress means this category hasn't been started
        Log.debug("     ✅ Found first incomplete category (no progress yet): ${category.categoryName}");
        return category;
      }

      Log.debug("     - Progress: ${progress.learnedWordsCount} words, isCompleted: ${progress.isCompleted}");

      // If category is not completed, it's the first incomplete one
      if (!progress.isCompleted) {
        Log.debug("     ✅ Found first incomplete category: ${category.categoryName}");
        return category;
      }

      Log.debug("     - Category is completed, checking next...");
    }

    // If all categories are completed, return null
    Log.debug("⚠️ All selected categories are completed");
    return null;
  }

// ============================================
// FIXED: buildQueryPath in WordController
// ============================================
  void buildQueryPath() {
    final currentLearning = authController.currentUser.value?.currentLearning;

    if (currentLearning == null) {
      Log.debug("⚠️ No current learning data available");
      currentPath = null;
      currentCategoryId = null;
      currentCategoryName = null;
      return;
    }

    final language = currentLearning.languageName;
    final level = currentLearning.currentLevel;
    final contentType = currentLearning.contentType ?? 1;

    if (language == null || language.isEmpty || level == null || level.isEmpty) {
      Log.debug("⚠️ Missing language or level information");
      currentPath = null;
      currentCategoryId = null;
      currentCategoryName = null;
      return;
    }

    // ✅ CRITICAL FIX: Use currentCategory from user model, not from topicController
    final categoryName = currentLearning.currentCategory;

    if (categoryName == null || categoryName.isEmpty) {
      Log.debug("⚠️ No current category set");
      currentPath = null;
      currentCategoryId = null;
      currentCategoryName = null;
      return;
    }

    currentCategoryId = _generateCategoryId(categoryName);
    currentCategoryName = categoryName;

    currentPath = _wordService.buildPath(
      learningLang: language,
      level: level,
      topic: categoryName,
      contentType: contentType,
    );

    if (currentPath == null) {
      Log.debug("❌ Failed to build path via WordService");
      return;
    }

    _loadCurrentCategoryProgress();

    Log.debug("✅ Built query path: $currentPath");
    Log.debug("   - Language: $language");
    Log.debug("   - Level: $level");
    Log.debug("   - Topic: $categoryName");
    Log.debug("   - Category ID: $currentCategoryId");
    Log.debug("   - Content Type: $contentType");
  }

  // ============================================
// NEW: Find actual active category
// ============================================
  /// Finds the actual active category based on completion status
  /// Returns the first incomplete category in order
  /// Returns null if all categories are completed
  SelectedCategoryModel? _findActualActiveCategory(LevelProgressModel levelProgress) {
    Log.debug("🔍 Finding actual active category...");

    // Sort categories by orderIndex to process them in correct order
    final sortedCategories = levelProgress.selectedCategories.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    Log.debug("   - Total selected categories: ${sortedCategories.length}");

    // Find the first incomplete category
    for (var category in sortedCategories) {
      Log.debug("   - Checking category: ${category.categoryName} (Order: ${category.orderIndex})");

      // Get the actual progress for this category
      final progress = levelProgress.getCategoryProgress(category.categoryId);

      if (progress == null) {
        // No progress means this category hasn't been started
        Log.debug("     ✅ Found active category (no progress yet): ${category.categoryName}");
        return category;
      }

      Log.debug("     - Progress: ${progress.learnedWordsCount} words, isCompleted: ${progress.isCompleted}");

      // If category is not completed, it's the active one
      if (!progress.isCompleted) {
        Log.debug("     ✅ Found active category (incomplete): ${category.categoryName}");
        return category;
      }

      Log.debug("     - Category is completed, checking next...");
    }

    // If all categories are completed, return null
    Log.debug("⚠️ All selected categories are completed");
    return null;
  }

// ============================================
// NEW: Find next incomplete category
// ============================================
  /// Finds the next incomplete category after the current one
  /// Used when a category is completed to determine what comes next
  /// Returns null if no incomplete categories remain
  SelectedCategoryModel? _findNextIncompleteCategory(LevelProgressModel levelProgress) {
    Log.debug("🔍 Finding next incomplete category...");

    // Sort categories by orderIndex
    final sortedCategories = levelProgress.selectedCategories.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    Log.debug("   - Total categories to check: ${sortedCategories.length}");

    // Find the first incomplete category
    for (var i = 0; i < sortedCategories.length; i++) {
      final category = sortedCategories[i];
      final progress = levelProgress.getCategoryProgress(category.categoryId);

      Log.debug("   - Category ${i + 1}/${sortedCategories.length}: ${category.categoryName}");

      if (progress == null) {
        // No progress = not started = this is next
        Log.debug("     ✅ Next incomplete category (not started): ${category.categoryName}");
        return category;
      }

      Log.debug("     - Status: ${progress.isCompleted ? 'Completed' : 'In Progress'}");
      Log.debug("     - Words: ${progress.learnedWordsCount}");

      if (!progress.isCompleted) {
        // Found incomplete category
        Log.debug("     ✅ Next incomplete category: ${category.categoryName}");
        return category;
      }
    }

    // All categories are completed
    Log.debug("⚠️ No incomplete categories found - all are completed");
    return null;
  }

// ============================================
// NEW: Fix word count mismatch
// ============================================
  /// Fixes mismatches between recorded word counts and actual category progress
  /// This can happen when:
  /// 1. User logs in from a different device
  /// 2. Data sync issues occurred
  /// 3. App crashed during progress update
  Future<void> _fixWordCountMismatch(String levelName, int actualWordsLearned) async {
    Log.debug("🔧 Starting word count mismatch fix...");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("❌ Cannot fix mismatch - no user or learning data");
      return;
    }

    try {
      final currentLearning = user!.currentLearning!;
      final oldLevelTotal = currentLearning.getLevelProgress(levelName)?.totalWordsLearned ?? 0;
      final oldGlobalTotal = currentLearning.totalWordsLearned ?? 0;

      Log.debug("📊 Word Count Mismatch Details:");
      Log.debug("   - Level: $levelName");
      Log.debug("   - Old level total: $oldLevelTotal");
      Log.debug("   - Old global total: $oldGlobalTotal");
      Log.debug("   - Actual words learned: $actualWordsLearned");
      Log.debug("   - Difference: ${actualWordsLearned - oldLevelTotal}");

      // Get the level progress
      var levelProgress = currentLearning.getLevelProgress(levelName);
      if (levelProgress == null) {
        Log.debug("❌ Cannot fix mismatch - level progress not found");
        return;
      }

      // Log each category's contribution
      Log.debug("📋 Category breakdown:");
      for (var categoryProg in levelProgress.categoryProgress) {
        Log.debug("   - ${categoryProg.categoryName}: ${categoryProg.learnedWordsCount} words");
      }

      // Update level progress with correct total
      levelProgress = levelProgress.copyWith(
        totalWordsLearned: actualWordsLearned,
      );

      // Update learning language model with corrected level progress
      var updatedLearning = currentLearning.updateLevelProgress(levelProgress);

      // Calculate correct global total (sum of all levels)
      // For now, we're only fixing the current level
      // In a multi-level scenario, you'd need to sum all levels
      final correctedGlobalTotal = actualWordsLearned;

      // Update the main totalWordsLearned counter
      updatedLearning = updatedLearning.copyWith(
        totalWordsLearned: correctedGlobalTotal,
      );

      Log.debug("📝 Applying fixes:");
      Log.debug("   - New level total: $actualWordsLearned");
      Log.debug("   - New global total: $correctedGlobalTotal");

      // Save to Firestore
      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        Log.debug("✅ Word count mismatch fixed successfully!");
        Log.debug("   - Level ${levelName} total: $oldLevelTotal → $actualWordsLearned");
        Log.debug("   - Global total: $oldGlobalTotal → $correctedGlobalTotal");
      } else {
        Log.debug("❌ Failed to save word count fix");
      }

    } catch (e, st) {
      Log.debug("❌ Error fixing word count mismatch: $e");
      Log.debug("Stack trace: $st");
    }
  }


  // ============================================
// UPDATED: _updateCategoryProgress
// ============================================
  Future<void> _updateCategoryProgress({
    required int newLastWordIndex,
    required List<WordModel> fetchedWords,
  }) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("⚠️ Cannot update progress - no learning data");
      return;
    }

    if (currentCategoryId == null || currentCategoryName == null) {
      Log.debug("⚠️ Cannot update progress - no category information");
      return;
    }

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) {
      Log.debug("⚠️ Cannot update progress - no level information");
      return;
    }

    try {
      // Get existing category progress or create new one
      final existingProgress = currentCategoryProgress.value ??
          CategoryProgressModel(
            categoryName: currentCategoryName!,
            categoryId: currentCategoryId!,
            startedAt: DateTime.now(),
          );

      // ✅ FIX: Only count NEW words, not total
      final newWordsCount = fetchedWords.length;
      final updatedTotalWords = existingProgress.learnedWordsCount + newWordsCount;

      Log.debug("📊 Updating category progress:");
      Log.debug("   - Previous words: ${existingProgress.learnedWordsCount}");
      Log.debug("   - New words fetched: $newWordsCount");
      Log.debug("   - Updated total: $updatedTotalWords");

      // ✅ Update category progress
      final updatedCategoryProgress = existingProgress.copyWith(
        lastWordIndex: newLastWordIndex,
        learnedWordsCount: updatedTotalWords,
      );

      // Update in learning language model
      var updatedLearning = user.currentLearning!.updateCategoryProgress(
        levelName: currentLevel,
        categoryProgress: updatedCategoryProgress,
      );

      // ✅ FIX: Update level's total words learned correctly
      final levelProgress = updatedLearning.getLevelProgress(currentLevel);
      if (levelProgress != null) {
        final actualTotalWords = levelProgress.categoryProgress
            .fold<int>(0, (sum, cat) => sum + cat.learnedWordsCount);

        var updatedLevelProgress = levelProgress.copyWith(
          totalWordsLearned: actualTotalWords,
        );

        updatedLearning = updatedLearning.updateLevelProgress(updatedLevelProgress);
      }

      // ✅ Update lastPracticeAt in LearningLanguageModel
      updatedLearning = updatedLearning.copyWith(
        lastPracticeAt: DateTime.now(),
        currentCategory: currentCategoryName,
        totalWordsLearned: updatedLearning.getLevelProgress(currentLevel)?.totalWordsLearned ?? 0,
      );

      // Save to Firestore
      await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      // Update local state
      currentCategoryProgress.value = updatedCategoryProgress;

      Log.debug("✅ Category progress updated:");
      Log.debug("   - Category: $currentCategoryName");
      Log.debug("   - Level: $currentLevel");
      Log.debug("   - Last word index: $newLastWordIndex");
      Log.debug("   - Words learned in category: $updatedTotalWords");
      Log.debug("   - Total words in level: ${updatedLearning.getLevelProgress(currentLevel)?.totalWordsLearned}");
    } catch (e, st) {
      Log.debug("❌ Error updating category progress: $e\n$st");
    }
  }

  /// ✅ Auto-select initial categories from allTopics (for first-time or no categories)
  Future<void> _autoSelectInitialCategories() async {
    Log.debug("🆕 Auto-selecting initial categories from allTopics");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("❌ No user or learning data");
      return;
    }

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) {
      Log.debug("❌ No current level set");
      return;
    }

    try {
      final topicController = Get.find<TopicController>();

      // Get suggested categories based on level, or default to first topic
      final suggestedTopics = topicController.getSuggestedCategories(currentLevel);
      final initialCategory = suggestedTopics.isNotEmpty
          ? suggestedTopics.first
          : topicController.allTopics.first;

      Log.debug("📚 Auto-selecting initial category: $initialCategory");

      final newCategory = SelectedCategoryModel(
        categoryName: initialCategory,
        categoryId: _generateCategoryId(initialCategory),
        orderIndex: 0,
        isActive: true,
        isCompleted: false,
        addedAt: DateTime.now(),
      );

      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel) ??
          LevelProgressModel(
            levelName: currentLevel,
            startedAt: DateTime.now(),
          );

      levelProgress = levelProgress.copyWith(
        selectedCategories: [newCategory],
      );

      final updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress).copyWith(
        currentCategory: initialCategory,
      );

      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        // Update topic controller state
        topicController.selectedTopics.assignAll([initialCategory]);
        topicController.isInitialSetup.value = false;

        Log.debug("✅ Auto-selected initial category: $initialCategory");

        // Retry initialization now that we have a category
        await initializeAfterLogin();
      } else {
        Log.debug("❌ Failed to save auto-selected category");
        hasError.value = true;
        errorMessage.value = "Failed to initialize categories";
      }

    } catch (e, st) {
      Log.debug("❌ Error auto-selecting initial categories: $e\n$st");
      hasError.value = true;
      errorMessage.value = "Failed to auto-select categories";
    }
  }

  /// ✅ Create initial level progress when user first starts a level
  Future<void> _createInitialLevelProgress(String levelName) async {
    Log.debug("🆕 Creating initial level progress for: $levelName");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("❌ No user or learning data");
      return;
    }

    try {
      final topicController = Get.find<TopicController>();

      // Check if topics are already selected
      final selectedTopics = topicController.selectedTopics.isNotEmpty
          ? topicController.selectedTopics.toList()
          : [topicController.allTopics.first]; // Default to first topic

      Log.debug("📚 Creating level with categories: ${selectedTopics.join(', ')}");

      final selectedCategories = selectedTopics.asMap().entries.map((entry) {
        final index = entry.key;
        final name = entry.value;
        return SelectedCategoryModel(
          categoryName: name,
          categoryId: _generateCategoryId(name),
          orderIndex: index,
          isActive: index == 0,
          isCompleted: false,
          addedAt: DateTime.now(),
        );
      }).toList();

      final levelProgress = LevelProgressModel(
        levelName: levelName,
        selectedCategories: selectedCategories,
        startedAt: DateTime.now(),
      );

      final updatedLearning = user!.currentLearning!.updateLevelProgress(levelProgress).copyWith(
        currentCategory: selectedCategories.first.categoryName,
      );

      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        // Update topic controller
        topicController.selectedTopics.assignAll(selectedTopics);
        topicController.isInitialSetup.value = false;

        Log.debug("✅ Created initial level progress with ${selectedCategories.length} categories");

        // Retry initialization
        await initializeAfterLogin();
      } else {
        Log.debug("❌ Failed to create initial level progress");
        hasError.value = true;
        errorMessage.value = "Failed to initialize level";
      }
    } catch (e, st) {
      Log.debug("❌ Error creating initial level progress: $e\n$st");
      hasError.value = true;
      errorMessage.value = "Failed to create level progress";
    }
  }

  /// ✅ Activate first incomplete category when no active category found
  Future<void> _activateFirstIncompleteCategory(LevelProgressModel levelProgress) async {
    Log.debug("🔄 Activating first incomplete category");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return;

    try {
      final incompleteCategories = levelProgress.selectedCategories
          .where((c) => !c.isCompleted)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      if (incompleteCategories.isEmpty) {
        Log.debug("🏆 All selected categories completed - auto-selecting new one");
        await _autoSelectNextCategory();
        return;
      }

      final firstIncomplete = incompleteCategories.first;
      Log.debug("✅ Activating category: ${firstIncomplete.categoryName}");

      // Deactivate all, activate first incomplete
      final updatedCategories = levelProgress.selectedCategories.map((cat) {
        return cat.copyWith(isActive: cat.categoryId == firstIncomplete.categoryId);
      }).toList();

      var updatedLevelProgress = levelProgress.copyWith(selectedCategories: updatedCategories);

      final updatedLearning = user.currentLearning!.updateLevelProgress(updatedLevelProgress).copyWith(
        currentCategory: firstIncomplete.categoryName,
      );

      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        // Update local state
        currentCategoryId = firstIncomplete.categoryId;
        currentCategoryName = firstIncomplete.categoryName;

        Log.debug("✅ Activated category: ${firstIncomplete.categoryName}");

        // Retry initialization
        await initializeAfterLogin();
      }
    } catch (e, st) {
      Log.debug("❌ Error activating first incomplete category: $e\n$st");
    }
  }

  /// ✅ Get next available topic from allTopics (not yet selected)
  String? getNextAvailableTopic() {
    try {
      final topicController = Get.find<TopicController>();
      final allTopics = topicController.allTopics;
      final selectedCategories = authController.currentUser.value?.currentLearning?.getSelectedCategories() ?? [];

      final selectedTopicNames = selectedCategories.map((c) => c.categoryName).toSet();
      final availableTopics = allTopics.where((topic) => !selectedTopicNames.contains(topic)).toList();

      return availableTopics.isNotEmpty ? availableTopics.first : null;
    } catch (e) {
      Log.debug("❌ Error getting next available topic: $e");
      return null;
    }
  }

  /// ✅ Check if all topics from allTopics are completed
  bool areAllTopicsCompleted() {
    try {
      final topicController = Get.find<TopicController>();
      final allTopics = topicController.allTopics;
      final selectedCategories = authController.currentUser.value?.currentLearning?.getSelectedCategories() ?? [];

      // Check if all topics are selected
      if (selectedCategories.length < allTopics.length) {
        return false;
      }

      // Check if all selected categories are completed
      return selectedCategories.every((cat) => cat.isCompleted);
    } catch (e) {
      Log.debug("❌ Error checking if all topics completed: $e");
      return false;
    }
  }

  Future<bool> switchToCategory(String categoryName, {bool forceSwitch = false}) async {
    Log.debug("🔄 Switching to category: $categoryName");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return false;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return false;

    try {
      final selectedCategories = user.currentLearning!.getSelectedCategories();
      final targetCategory = selectedCategories.firstWhere(
            (c) => c.categoryName == categoryName,
        orElse: () => throw Exception("Category not found"),
      );

      if (targetCategory.isCompleted && !forceSwitch) {
        Log.debug("⚠️ Category already completed");
        return false;
      }

      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
      if (levelProgress == null) return false;

      final updatedCategories = levelProgress.selectedCategories.map((cat) {
        return cat.copyWith(isActive: cat.categoryId == targetCategory.categoryId);
      }).toList();

      levelProgress = levelProgress.copyWith(selectedCategories: updatedCategories);

      final updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress).copyWith(
        currentCategory: categoryName,
      );

      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        authController.clearTodayWordsCache();
        buildQueryPath();
        await fetchWordList();

        Log.debug("✅ Successfully switched to category: $categoryName");
        return true;
      }

      return false;
    } catch (e, st) {
      Log.debug("❌ Error switching to category: $e\n$st");
      return false;
    }
  }

  Future<void> refreshWords() async {
    if (_isFetching) {
      Log.debug("⏳ Already fetching, skipping refresh...");
      return;
    }

    Log.debug("🔄 Refreshing words...");
    buildQueryPath();
    await fetchWordList();
  }


  /// ✅ WORDCONTROLLER: Handle premium upgrade and fetch additional words
  Future<bool> handlePremiumUpgrade() async {
    Log.debug("🌟 WordController: Handling premium upgrade...");

    final user = authController.currentUser.value;

    if (user?.currentLearning == null) {
      Log.debug("❌ No user or learning data found");
      return false;
    }

    try {
      final currentLearning = user!.currentLearning!;
      final currentWordsPerDay = currentLearning.wordsPerDay ?? 1;
      final totalWordsLearned = currentLearning.totalWordsLearned ?? 0;

      Log.debug("📊 Current status before premium upgrade:");
      Log.debug("   - Words per day: $currentWordsPerDay");
      Log.debug("   - Total words learned: $totalWordsLearned");
      Log.debug("   - Today's words count: ${wordsList.length}");

      // ✅ Check if user practiced today
      final alreadyPracticedToday = _hasAlreadyPracticedToday();
      Log.debug("   - Already practiced today: $alreadyPracticedToday");

      // ✅ Calculate how many additional words needed
      const premiumWordsPerDay = 10;
      final currentWordsToday = alreadyPracticedToday ? wordsList.length : 0;
      final additionalWordsNeeded = premiumWordsPerDay - currentWordsToday;

      Log.debug("🎯 Premium upgrade calculation:");
      Log.debug("   - Premium words per day: $premiumWordsPerDay");
      Log.debug("   - Current words today: $currentWordsToday");
      Log.debug("   - Additional words needed: $additionalWordsNeeded");

      // ✅ Update user model with new wordsPerDay
      // Keep lastPracticeAt as is - don't reset it
      final updatedLearning = currentLearning.copyWith(
        wordsPerDay: premiumWordsPerDay,
      );

      final updateSuccess = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (!updateSuccess) {
        Log.debug("❌ Failed to update learning data with premium wordsPerDay");
        return false;
      }

      Log.debug("✅ Updated wordsPerDay to $premiumWordsPerDay");

      // ✅ If user already practiced today and needs more words
      if (alreadyPracticedToday && additionalWordsNeeded > 0) {
        Log.debug("🔄 User practiced today - fetching $additionalWordsNeeded additional words");

        // Clear today's cache so we can fetch fresh combined words
        authController.clearTodayWordsCache();

        // Fetch additional words to reach 10
        await _fetchAdditionalWordsForPremium(
          currentWordsToday: currentWordsToday,
          additionalNeeded: additionalWordsNeeded,
        );

      } else if (!alreadyPracticedToday) {
        // User hasn't practiced today - fetch fresh 10 words
        Log.debug("🆕 User hasn't practiced today - fetching fresh 10 words");

        authController.clearTodayWordsCache();
        await fetchWordList();

      } else {
        // User already has 10+ words today (edge case)
        Log.debug("✅ User already has sufficient words for today");
      }

      Log.debug("🎉 Premium upgrade completed successfully!");
      Log.debug("   - New words per day: $premiumWordsPerDay");
      Log.debug("   - Total words now: ${wordsList.length}");

      return true;

    } catch (e, st) {
      Log.debug("❌ Error during premium upgrade in WordController: $e\n$st");
      return false;
    }
  }

  /// ✅ Fetch additional words after premium upgrade
  Future<void> _fetchAdditionalWordsForPremium({
    required int currentWordsToday,
    required int additionalNeeded,
  }) async {
    try {
      Log.debug("📥 Fetching $additionalNeeded additional words for premium upgrade");

      final user = authController.currentUser.value;
      if (user?.currentLearning == null) {
        Log.debug("❌ No user or learning data");
        return;
      }

      final currentLevel = user!.currentLearning!.currentLevel;
      if (currentLevel == null) {
        Log.debug("❌ No current level");
        return;
      }

      // Get current category progress
      final activeCategory = user.currentLearning!.getActiveCategory();
      if (activeCategory == null) {
        Log.debug("❌ No active category found");
        return;
      }

      final categoryProgress = user.currentLearning!.getCategoryProgress(
        currentLevel,
        activeCategory.categoryId,
      );

      // ✅ Calculate where to start fetching from
      // If user learned 3 words today, lastWordIndex = previous + 3
      // We need to fetch from (lastWordIndex + 1) onwards
      final lastWordIndex = categoryProgress?.lastWordIndex ?? 0;
      final startIndex = lastWordIndex + 1;

      Log.debug("📍 Fetching additional words:");
      Log.debug("   - Last word index: $lastWordIndex");
      Log.debug("   - Start fetching from: $startIndex");
      Log.debug("   - Need to fetch: $additionalNeeded words");

      // Build path for current category
      final categoryPath = _wordService.buildPath(
        learningLang: user.currentLearning!.languageName ?? 'german',
        level: currentLevel,
        topic: activeCategory.categoryName,
        contentType: user.currentLearning!.contentType ?? 1,
      );

      if (categoryPath == null) {
        Log.debug("❌ Failed to build category path");
        return;
      }

      // Check total available words in category
      final totalAvailable = await _wordService.getTotalWordCount(categoryPath);
      final remainingInCategory = totalAvailable - lastWordIndex;

      Log.debug("📊 Category availability:");
      Log.debug("   - Total words in category: $totalAvailable");
      Log.debug("   - Remaining in category: $remainingInCategory");

      List<WordModel> additionalWords = [];

      if (remainingInCategory >= additionalNeeded) {
        // ✅ Enough words in current category
        Log.debug("✅ Fetching $additionalNeeded words from current category");

        additionalWords = await _wordService.fetchWords(
          path: categoryPath,
          limit: additionalNeeded,
          startAfterIndex: startIndex,
        );

        if (additionalWords.isNotEmpty) {
          // Update category progress
          final newLastWordIndex = lastWordIndex + additionalWords.length;
          await _updateCategoryProgressForPremiumUpgrade(
            categoryId: activeCategory.categoryId,
            categoryName: activeCategory.categoryName,
            newLastWordIndex: newLastWordIndex,
            additionalWordsCount: additionalWords.length,
          );
        }

      } else {
        // ✅ Need to fetch from multiple categories
        Log.debug("⚠️ Not enough words in current category - fetching across categories");

        // Fetch remaining from current category
        if (remainingInCategory > 0) {
          final wordsFromCurrent = await _wordService.fetchWords(
            path: categoryPath,
            limit: remainingInCategory,
            startAfterIndex: startIndex,
          );

          additionalWords.addAll(wordsFromCurrent);

          // Update progress for these words
          await _updateCategoryProgressForPremiumUpgrade(
            categoryId: activeCategory.categoryId,
            categoryName: activeCategory.categoryName,
            newLastWordIndex: totalAvailable,
            additionalWordsCount: wordsFromCurrent.length,
          );

          // Mark current category as completed
          await _markCategoryAsCompletedAndMoveNext(
            categoryId: activeCategory.categoryId,
            categoryName: activeCategory.categoryName,
            totalWords: totalAvailable,
          );
        }

        // Fetch remaining from next categories
        final stillNeeded = additionalNeeded - additionalWords.length;
        if (stillNeeded > 0) {
          Log.debug("🔄 Still need $stillNeeded more words - fetching from next categories");

          final moreWords = await _fetchWordsAcrossCategories(stillNeeded);
          additionalWords.addAll(moreWords);
        }
      }

      if (additionalWords.isEmpty) {
        Log.debug("⚠️ No additional words could be fetched");
        return;
      }

      Log.debug("✅ Fetched ${additionalWords.length} additional words");

      // ✅ Combine with existing words
      final existingWords = wordsList.toList();
      final allWords = [...existingWords, ...additionalWords];

      Log.debug("📊 Final word count:");
      Log.debug("   - Previous: ${existingWords.length}");
      Log.debug("   - Additional: ${additionalWords.length}");
      Log.debug("   - Total: ${allWords.length}");

      // Update word list
      wordsList.assignAll(allWords);

      // Cache all words for today
      authController.cacheTodayWords(allWords);

      _updateWidget(allWords);

      // Mark new words as seen
      await markWordsAsSeen(additionalWords);

      Log.debug("🎉 Premium upgrade word fetch completed!");

    } catch (e, st) {
      Log.debug("❌ Error fetching additional words: $e\n$st");
    }
  }

  /// ✅ Update category progress after premium upgrade fetch
  Future<void> _updateCategoryProgressForPremiumUpgrade({
    required String categoryId,
    required String categoryName,
    required int newLastWordIndex,
    required int additionalWordsCount,
  }) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return;

    try {
      final existingProgress = user.currentLearning!.getCategoryProgress(
        currentLevel,
        categoryId,
      );

      if (existingProgress == null) {
        Log.debug("⚠️ No existing progress found for category");
        return;
      }

      final newWordsCount = existingProgress.learnedWordsCount + additionalWordsCount;

      final updatedCategoryProgress = existingProgress.copyWith(
        lastWordIndex: newLastWordIndex,
        learnedWordsCount: newWordsCount,
      );

      final updatedLearning = user.currentLearning!.updateCategoryProgress(
        levelName: currentLevel,
        categoryProgress: updatedCategoryProgress,
      );

      // Don't update lastPracticeAt here - keep it as is
      await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      Log.debug("✅ Updated category progress after premium upgrade:");
      Log.debug("   - Category: $categoryName");
      Log.debug("   - New last word index: $newLastWordIndex");
      Log.debug("   - Total words learned: $newWordsCount");

    } catch (e, st) {
      Log.debug("❌ Error updating category progress: $e\n$st");
    }
  }




  // ✅ Check and handle level completion after category completion
  Future<void> _checkAndHandleLevelCompletion() async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return;

    try {
      Log.debug("🎯 Checking if level $currentLevel is completed...");

      // Check if current level is completed
      final isLevelCompleted = user.currentLearning!.isCurrentLevelCompleted();

      if (!isLevelCompleted) {
        Log.debug("📊 Level $currentLevel not yet completed");
        return;
      }

      Log.debug("🎉 Level $currentLevel completed!");

      // Mark level as completed in Firestore
      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
      if (levelProgress == null) return;

      levelProgress = levelProgress.markAsCompleted();
      var updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress);

      // Get next level
      final nextLevel = user.currentLearning!.getNextLevel();

      if (nextLevel != null) {
        Log.debug("⬆️ Moving to next level: $nextLevel");

        // Update to next level
        updatedLearning = updatedLearning.copyWith(
          currentLevel: nextLevel,
          currentCategory: null, // Will be set when categories are selected
        );

        await authController.updateUserData(
          currentLearning: updatedLearning,
          showLoading: false,
        );

        // Show success message
        hasError.value = false;
        errorMessage.value = "🎉 Level $currentLevel completed! Welcome to $nextLevel!";

        // Auto-select initial categories for new level
        await _autoSelectInitialCategoriesForNewLevel(nextLevel);

        // Short delay to show message
        await Future.delayed(Duration(seconds: 2));

        // Fetch words for new level
        await initializeAfterLogin();

      } else {
        // All levels completed!
        Log.debug("🏆 All levels completed for this language!");

        final languageName = user.currentLearning!.languageName ?? 'this language';

        hasError.value = true;
        errorMessage.value =
        "🏆 Congratulations! You've completed all levels in $languageName!\n\n"
            "You've mastered:\n"
            "✅ Level A1 - Beginner\n"
            "✅ Level A2 - Elementary\n"
            "✅ Level B1 - Intermediate\n"
            "✅ Level B2 - Upper Intermediate\n\n"
            "Try learning a new language to continue your journey!";

        wordsList.clear();

        // Mark learning as fully completed
        updatedLearning = updatedLearning.copyWith(
          currentLevel: 'B2', // Keep at highest level
        );

        await authController.updateUserData(
          currentLearning: updatedLearning,
          showLoading: false,
        );
      }

    } catch (e, st) {
      Log.debug("❌ Error checking level completion: $e\n$st");
    }
  }

  /// ✅ Auto-select initial categories for new level
  Future<void> _autoSelectInitialCategoriesForNewLevel(String newLevel) async {
    Log.debug("🆕 Auto-selecting categories for new level: $newLevel");

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    try {
      final topicController = Get.find<TopicController>();

      // Get suggested categories for this level
      final suggestedCategories = topicController.getSuggestedCategories(newLevel);

      // If no suggestions, use first few topics
      final categoriesToSelect = suggestedCategories.isNotEmpty
          ? suggestedCategories.take(3).toList()  // Take first 3 suggested
          : topicController.allTopics.take(3).toList(); // Or first 3 from all

      Log.debug("📚 Selecting ${categoriesToSelect.length} categories for $newLevel");
      Log.debug("   Categories: ${categoriesToSelect.join(', ')}");

      // Create selected category models
      final selectedCategories = categoriesToSelect.asMap().entries.map((entry) {
        final index = entry.key;
        final name = entry.value;
        return SelectedCategoryModel(
          categoryName: name,
          categoryId: _generateCategoryId(name),
          orderIndex: index,
          isActive: index == 0, // First category is active
          isCompleted: false,
          addedAt: DateTime.now(),
        );
      }).toList();

      // Create level progress for new level
      var levelProgress = LevelProgressModel(
        levelName: newLevel,
        selectedCategories: selectedCategories,
        startedAt: DateTime.now(),
      );

      // Update learning model
      var updatedLearning = user?.currentLearning!.updateLevelProgress(levelProgress).copyWith(
        currentCategory: categoriesToSelect.first,
        currentLevel: newLevel,
      );

      // Save to Firestore
      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        // Update topic controller
        topicController.selectedTopics.assignAll(categoriesToSelect);

        // Update local state
        currentCategoryName = categoriesToSelect.first;
        currentCategoryId = selectedCategories.first.categoryId;

        Log.debug("✅ Auto-selected categories for $newLevel");
      }
    } catch (e, st) {
      Log.debug("❌ Error auto-selecting categories for new level: $e\n$st");
    }
  }

// ============================================
// UPDATE: Modify _markCategoryAsCompletedAndMoveNext in word_controller.dart
// ============================================

// Replace the existing _markCategoryAsCompletedAndMoveNext method with this updated version:

  /// ✅ Mark category as completed and activate next one
  Future<void> _markCategoryAsCompletedAndMoveNext({
    required String categoryId,
    required String categoryName,
    required int totalWords,
  }) async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return;

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return;

    try {
      Log.debug("🎉 Marking category as completed: $categoryName");

      final existingProgress = user.currentLearning!.getCategoryProgress(
        currentLevel,
        categoryId,
      ) ?? CategoryProgressModel(
        categoryName: categoryName,
        categoryId: categoryId,
        startedAt: DateTime.now(),
      );

      final completedCategoryProgress = existingProgress.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        progressPercentage: 100.0,
        lastWordIndex: totalWords,
        learnedWordsCount: totalWords,
      );

      var updatedLearning = user.currentLearning!.updateCategoryProgress(
        levelName: currentLevel,
        categoryProgress: completedCategoryProgress,
      );

      // Mark category as completed and activate next
      updatedLearning = updatedLearning.markCategoryCompletedAndMoveToNext(
        levelName: currentLevel,
        categoryId: categoryId,
      );

      final nextCategory = updatedLearning.getActiveCategory();

      if (nextCategory != null) {
        Log.debug("✅ Auto-activating next category: ${nextCategory.categoryName}");
        updatedLearning = updatedLearning.copyWith(
          currentCategory: nextCategory.categoryName,
        );
      } else {
        Log.debug("⚠️ No more selected categories in this level");
      }

      await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      // Update local state
      if (nextCategory != null) {
        currentCategoryId = nextCategory.categoryId;
        currentCategoryName = nextCategory.categoryName;
        buildQueryPath();
      }

      // ✅ CRITICAL: Check if level is now completed
      await _checkAndHandleLevelCompletion();

    } catch (e, st) {
      Log.debug("❌ Error marking category as completed: $e\n$st");
    }
  }

// ============================================
// UPDATE: Modify completeCategoryAndMoveNext in word_controller.dart
// ============================================

// Replace the existing completeCategoryAndMoveNext method with this updated version:

  /// ✅ Complete category and move to next (public method)
  Future<bool> completeCategoryAndMoveNext({required int totalWordsInCategory}) async {
    if (currentCategoryId == null || currentCategoryName == null) {
      Log.debug("⚠️ Cannot complete category - no category information");
      return false;
    }

    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      Log.debug("⚠️ Cannot complete category - no learning data");
      return false;
    }

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) {
      Log.debug("⚠️ Cannot complete category - no level information");
      return false;
    }

    try {
      Log.debug("🎉 Completing category: $currentCategoryName");

      final existingProgress = currentCategoryProgress.value ??
          CategoryProgressModel(
            categoryName: currentCategoryName!,
            categoryId: currentCategoryId!,
            startedAt: DateTime.now(),
          );

      final completedCategoryProgress = existingProgress.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        progressPercentage: 100.0,
        lastWordIndex: totalWordsInCategory,
        learnedWordsCount: totalWordsInCategory,
      );

      var updatedLearning = user.currentLearning!.updateCategoryProgress(
        levelName: currentLevel,
        categoryProgress: completedCategoryProgress,
      );

      updatedLearning = updatedLearning.markCategoryCompletedAndMoveToNext(
        levelName: currentLevel,
        categoryId: currentCategoryId!,
      );

      final nextCategory = updatedLearning.getActiveCategory();

      if (nextCategory != null) {
        Log.debug("✅ Auto-switching to next category: ${nextCategory.categoryName}");

        updatedLearning = updatedLearning.copyWith(
          currentCategory: nextCategory.categoryName,
          lastPracticeAt: DateTime.now(),
        );

        final success = await authController.updateUserData(
          currentLearning: updatedLearning,
          showLoading: false,
        );

        if (success) {
          authController.clearTodayWordsCache();
          currentCategoryProgress.value = completedCategoryProgress;
          buildQueryPath();

          Log.debug("🎉 Category completed and moved to: ${nextCategory.categoryName}");

          // ✅ Check if level is now completed
          await _checkAndHandleLevelCompletion();

          return true;
        }
      } else {
        Log.debug("⚠️ No more categories in this level");

        await authController.updateUserData(
          currentLearning: updatedLearning,
          showLoading: false,
        );

        // ✅ Check if level is now completed
        await _checkAndHandleLevelCompletion();
      }

      return false;
    } catch (e, st) {
      Log.debug("❌ Error completing category and moving to next: $e\n$st");
      return false;
    }
  }

// ============================================
// FILE 4: Add these helper methods to WordController
// ============================================

  /// ✅ Get learning progress summary (for UI display)
  Map<String, dynamic> getLearningProgressSummary() {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      return {
        'hasData': false,
        'message': 'No learning data available',
      };
    }

    final summary = user!.currentLearning!.getCompletionSummary();

    return {
      'hasData': true,
      ...summary,
      'currentCategory': currentCategoryName,
      'todayWordsCount': wordsList.length,
    };
  }

  /// ✅ Check if user can continue learning (not completed all levels)
  bool canContinueLearning() {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return false;

    return !user!.currentLearning!.areAllLevelsCompleted();
  }

  /// ✅ Get next milestone info (for motivation)
  Map<String, dynamic> getNextMilestone() {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      return {'type': 'none', 'message': 'Start learning!'};
    }

    final currentLearning = user!.currentLearning!;
    final currentLevel = currentLearning.currentLevel;

    if (currentLevel == null) {
      return {'type': 'none', 'message': 'Select a level to start'};
    }

    // Check if current level is completed
    if (currentLearning.isCurrentLevelCompleted()) {
      final nextLevel = currentLearning.getNextLevel();
      if (nextLevel != null) {
        return {
          'type': 'level',
          'message': 'Ready to move to $nextLevel!',
          'nextLevel': nextLevel,
        };
      } else {
        return {
          'type': 'language',
          'message': 'All levels completed! Try a new language!',
        };
      }
    }

    // Get current level progress
    final levelProgress = currentLearning.getLevelProgress(currentLevel);
    if (levelProgress != null) {
      final completedCategories = levelProgress.getCompletedCategoriesCount();
      final totalCategories = levelProgress.selectedCategories.length;
      final remaining = totalCategories - completedCategories;

      if (remaining > 0) {
        return {
          'type': 'category',
          'message': '$remaining ${remaining == 1 ? 'category' : 'categories'} left in $currentLevel',
          'remaining': remaining,
          'total': totalCategories,
        };
      }
    }

    return {'type': 'none', 'message': 'Keep learning!'};
  }



}