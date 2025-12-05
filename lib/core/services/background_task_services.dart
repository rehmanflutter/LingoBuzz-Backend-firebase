import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:background_fetch/background_fetch.dart' as bf;
import 'package:workmanager/workmanager.dart';
import 'package:lingobuzz/core/services/push_notifications_services.dart';
import 'package:lingobuzz/model/word_model.dart';

class BackgroundTaskService {
  static const String FETCH_WORDS_TASK = "fetchWordsTask";
  static const String MIDNIGHT_FETCH_TASK = "midnightFetchTask";
  static const String DAILY_WORDS_KEY = "daily_words";
  static const String LAST_FETCH_DATE_KEY = "last_fetch_date";
  static const String CURRENT_WORD_INDEX_KEY = "current_word_index";
  static const String IS_SETUP_DONE_KEY = "isSetupDone";
  static const String SOURCE_LANG_KEY = "sourceLang";
  static const String TARGET_LANG_KEY = "targetLang";
  static const String NATIVE_LANG_KEY = "nativeLang";
  static const String DISPLAY_TIME_KEY = "displayTime";
  static const String LAST_SHOWN_SLOT_KEY = "last_shown_slot";
  static const String LAST_MIDNIGHT_FETCH_KEY = "last_midnight_fetch";

  // ✅ NEW: Default display time
  static const String DEFAULT_DISPLAY_TIME = "8:00AM - 8:00PM";

  /// Initialize background work for both platforms
  static Future<void> initialize() async {
    final storage = GetStorage();
    final isSetupDone = storage.read(IS_SETUP_DONE_KEY) ?? false;

    // ✅ FIX: Set default display time if not set
    final displayTime = storage.read(DISPLAY_TIME_KEY);
    if (displayTime == null || displayTime.isEmpty) {
      await storage.write(DISPLAY_TIME_KEY, DEFAULT_DISPLAY_TIME);
      debugPrint("✅ Set default display time: $DEFAULT_DISPLAY_TIME");
    }

    if (Platform.isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      await _scheduleAndroidPeriodicTask();
      await _scheduleAndroidMidnightTask();
      debugPrint("✅ Android WorkManager initialized");
    } else if (Platform.isIOS) {
      await _initializeBackgroundFetch();
      debugPrint("✅ iOS Background Fetch initialized (timeline-based updates)");
    }
  }

  /// Android: Schedule periodic task with WorkManager
  static Future<void> _scheduleAndroidPeriodicTask() async {
    await Workmanager().cancelByUniqueName("1");

    await Workmanager().registerPeriodicTask(
      "1",
      FETCH_WORDS_TASK,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );

    debugPrint("✅ Android periodic task scheduled (every 15 minutes)");
  }

  /// Schedule Android midnight task to fetch new words
  static Future<void> _scheduleAndroidMidnightTask() async {
    await Workmanager().cancelByUniqueName("midnight_fetch");

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final timeUntilMidnight = nextMidnight.difference(now);

    debugPrint("🌙 Scheduling midnight fetch in ${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes % 60}m");

    await Workmanager().registerPeriodicTask(
      "midnight_fetch",
      MIDNIGHT_FETCH_TASK,
      frequency: const Duration(hours: 24),
      initialDelay: timeUntilMidnight,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint("✅ Android midnight fetch task scheduled");
  }

  /// iOS: Initialize background_fetch ONLY for data refresh (not scheduling)
  static Future<void> _initializeBackgroundFetch() async {
    int status = await bf.BackgroundFetch.configure(
      bf.BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
        requiredNetworkType: bf.NetworkType.NONE,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    debugPrint('✅ iOS BackgroundFetch configured with status: $status');

    try {
      await bf.BackgroundFetch.start();
      debugPrint('✅ iOS BackgroundFetch started');
    } catch (e) {
      debugPrint('⚠️ iOS BackgroundFetch start failed: $e');
    }

    debugPrint('📱 iOS: WidgetKit timeline will handle automatic updates');
  }

  /// Background Fetch event handler (iOS) - only for refreshing data
  static Future<void> _onBackgroundFetch(String taskId) async {
    debugPrint('🔄 [iOS BackgroundFetch] Event received: $taskId');

    try {
      await GetStorage.init();

      final storage = GetStorage();
      final sourceLang = storage.read(SOURCE_LANG_KEY) ?? 'german';
      final targetLang = storage.read(TARGET_LANG_KEY) ?? 'english';
      final displayTime = storage.read(DISPLAY_TIME_KEY) ?? DEFAULT_DISPLAY_TIME;

      if (taskId == "com.lingobuzz.midnight") {
        debugPrint("🌙 Midnight task - fetching new day's words");
        await fetchNewDayWords(
          sourceLang: sourceLang,
          targetLang: targetLang,
          displayTime: displayTime,
        );
      } else {
        await checkAndUpdateWords(
          sourceLang: sourceLang,
          targetLang: targetLang,
          displayTime: displayTime,
        );
      }

      await _reloadWidgetKitTimeline();

      debugPrint('✅ [iOS BackgroundFetch] Task completed: $taskId');
      bf.BackgroundFetch.finish(taskId);
    } catch (e) {
      debugPrint('❌ [iOS BackgroundFetch] Task failed: $e');
      bf.BackgroundFetch.finish(taskId);
    }
  }

  /// Background Fetch timeout handler (iOS)
  static void _onBackgroundFetchTimeout(String taskId) {
    debugPrint('⏱️ [iOS BackgroundFetch] Task timeout: $taskId');
    bf.BackgroundFetch.finish(taskId);
  }

  /// Force WidgetKit to reload its timeline (iOS only)
  static Future<void> _reloadWidgetKitTimeline() async {
    if (!Platform.isIOS) return;

    try {
      const channel = MethodChannel('widgetkit_reload');
      await channel.invokeMethod('reloadAllTimelines');
      debugPrint("✅ WidgetKit timeline reloaded");
    } catch (e) {
      debugPrint("⚠️ WidgetKit reload channel unavailable: $e");
    }
  }

  /// Fetch new words for the new day automatically
  static Future<void> fetchNewDayWords({
    String? sourceLang,
    String? targetLang,
    String? displayTime,
  }) async {
    debugPrint("🌅 Fetching new day's words at ${DateTime.now()}");

    try {
      final storage = GetStorage();
      final isSetupDone = storage.read(IS_SETUP_DONE_KEY) ?? false;

      if (!isSetupDone) {
        debugPrint("⚠️ Setup not done, skipping midnight fetch");
        return;
      }

      final source = sourceLang ?? storage.read(SOURCE_LANG_KEY) ?? 'german';
      final target = targetLang ?? storage.read(TARGET_LANG_KEY) ?? 'english';
      final displayTimeRange = displayTime ?? storage.read(DISPLAY_TIME_KEY) ?? DEFAULT_DISPLAY_TIME;

      final lastMidnightFetch = storage.read(LAST_MIDNIGHT_FETCH_KEY);
      final now = DateTime.now();

      if (lastMidnightFetch != null) {
        final lastFetchDate = DateTime.parse(lastMidnightFetch);
        final today = DateTime(now.year, now.month, now.day);
        final lastFetchDay = DateTime(lastFetchDate.year, lastFetchDate.month, lastFetchDate.day);

        if (today.isAtSameMomentAs(lastFetchDay)) {
          debugPrint("✅ Already fetched words for today");
          return;
        }
      }

      debugPrint("🌍 Fetching new words: $source → $target");

      storage.write('isFetchedAtMidnight', DateTime.now().toString());
      await storage.write(LAST_MIDNIGHT_FETCH_KEY, now.toIso8601String());

      if (Platform.isIOS) {
        await _reloadWidgetKitTimeline();
      }

    } catch (e, st) {
      debugPrint("❌ Error in midnight fetch: $e\n$st");
    }
  }

  /// Schedule one-off task for immediate execution
  static Future<void> scheduleImmediateUpdate() async {
    if (Platform.isAndroid) {
      await Workmanager().registerOneOffTask(
        "immediate_update",
        FETCH_WORDS_TASK,
        initialDelay: const Duration(seconds: 5),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      debugPrint("✅ Android immediate update scheduled");
    } else if (Platform.isIOS) {
      await _reloadWidgetKitTimeline();
      debugPrint("✅ iOS: WidgetKit timeline reloaded");
    }
  }

  static Future<void> cancelAll() async {
    if (Platform.isAndroid) {
      await Workmanager().cancelAll();
      debugPrint("❌ Android: All WorkManager tasks cancelled");
    } else if (Platform.isIOS) {
      await bf.BackgroundFetch.stop();
      debugPrint("❌ iOS: Background Fetch stopped");
    }
  }

  /// Main background update function
  static Future<void> checkAndUpdateWords({
    String? sourceLang,
    String? targetLang,
    String? displayTime,
  }) async {
    debugPrint("🔄 checkAndUpdateWords called at ${DateTime.now()} on ${Platform.isAndroid ? 'Android' : 'iOS'}");

    final storage = GetStorage();
    final isSetupDone = storage.read(IS_SETUP_DONE_KEY) ?? false;

    if (!isSetupDone) {
      debugPrint("⚠️ Setup not done, skipping background update");
      return;
    }

    final source = sourceLang ?? storage.read(SOURCE_LANG_KEY) ?? 'german';
    final target = targetLang ?? storage.read(TARGET_LANG_KEY) ?? 'english';
    final displayTimeRange = displayTime ?? storage.read(DISPLAY_TIME_KEY) ?? DEFAULT_DISPLAY_TIME;

    debugPrint("🌍 Using languages: $source → $target");
    debugPrint("⏰ Display time: $displayTimeRange");

    List<WordModel> dailyWords = loadDailyWords();

    if (dailyWords.isEmpty) {
      debugPrint("📅 No daily words found in storage");
      return;
    }

    printWordTimeSlots(dailyWords, source, target, displayTime: displayTimeRange);

    final currentSlot = getCurrentTimeSlot(dailyWords.length, displayTime: displayTimeRange);

    if (currentSlot < 0) {
      debugPrint("⏰ Outside display time range, skipping widget update");
      return;
    }

    final lastShownSlot = storage.read(LAST_SHOWN_SLOT_KEY) ?? -1;

    if (lastShownSlot == currentSlot) {
      debugPrint("✅ Already showing word for slot $currentSlot");
      return;
    }

    final currentWord = getWordForSlot(dailyWords, currentSlot);
    if (currentWord == null) return;

    await updateHomeWidget(currentWord, source, target);
    await sendWordNotification(currentWord, source, target);

    await storage.write(LAST_SHOWN_SLOT_KEY, currentSlot);
    await storage.write(CURRENT_WORD_INDEX_KEY, currentSlot);

    debugPrint("🎯 Updated widgets + notification for slot $currentSlot (was: $lastShownSlot)");
  }

  /// Parse display time string to get start and end times
  static Map<String, double>? parseDisplayTime(String? displayTime) {
    if (displayTime == null || displayTime.isEmpty) {
      // ✅ FIX: Use default display time instead of null
      displayTime = DEFAULT_DISPLAY_TIME;
    }

    try {
      final parts = displayTime.split('-').map((e) => e.trim()).toList();
      if (parts.length != 2) return null;

      final startTime = _parseTimeToHour(parts[0]);
      final endTime = _parseTimeToHour(parts[1]);

      if (startTime == null || endTime == null) return null;

      return {'start': startTime, 'end': endTime};
    } catch (e) {
      debugPrint("❌ Error parsing display time: $e");
      return null;
    }
  }

  static double? _parseTimeToHour(String time) {
    try {
      final cleaned = time.trim().toUpperCase();
      final isAM = cleaned.contains('AM');
      final isPM = cleaned.contains('PM');

      if (!isAM && !isPM) return null;

      final timePart = cleaned.replaceAll(RegExp(r'\s*[AP]M', caseSensitive: false), '').trim();
      final hourMin = timePart.split(':');

      if (hourMin.isEmpty) return null;

      int hour = int.parse(hourMin[0]);
      int minute = hourMin.length > 1 ? int.parse(hourMin[1]) : 0;

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return hour + (minute / 60.0);
    } catch (e) {
      debugPrint("❌ Error parsing time: $e");
      return null;
    }
  }

  static int getCurrentTimeSlot(int totalWords, {String? displayTime}) {
    if (totalWords <= 0) {
      debugPrint("⚠️ Cannot calculate time slot: totalWords is $totalWords");
      return -1;
    }

    // ✅ FIX: Use default display time if not provided
    final effectiveDisplayTime = displayTime ?? DEFAULT_DISPLAY_TIME;
    final timeRange = parseDisplayTime(effectiveDisplayTime);

    final currentTime = DateTime.now();
    final currentHour = currentTime.hour + (currentTime.minute / 60.0);

    if (timeRange != null) {
      final start = timeRange['start']!;
      final end = timeRange['end']!;

      debugPrint("🕐 Parsed display time - Start: $start, End: $end, Current: ${currentHour.toStringAsFixed(2)}");

      double activeDuration;
      if (end >= start) {
        activeDuration = end - start;
      } else {
        activeDuration = (24 - start) + end;
      }

      bool isWithin;
      if (end >= start) {
        isWithin = currentHour >= start && currentHour < end;
      } else {
        isWithin = currentHour >= start || currentHour < end;
      }

      if (!isWithin) {
        debugPrint("⏰ Current time (${currentHour.toStringAsFixed(2)}) is outside display range ($start - $end)");
        return -1;
      }

      final slotDuration = activeDuration / totalWords;
      double hoursSinceStart = currentHour - start;
      if (hoursSinceStart < 0) hoursSinceStart += 24;

      int slot = (hoursSinceStart / slotDuration).floor();

      if (slot < 0) slot = 0;
      if (slot >= totalWords) slot = totalWords - 1;

      debugPrint("📊 Active duration: ${activeDuration.toStringAsFixed(2)} hrs, Slot duration: ${slotDuration.toStringAsFixed(4)} hrs, Current slot: $slot");
      return slot;
    } else {
      // ✅ FIX: This should never happen now with default time
      final slotDuration = 24.0 / totalWords;
      final slot = (currentHour / slotDuration).floor();
      debugPrint("⚠️ Using 24-hour fallback");
      debugPrint("📊 24-hour mode - Slot duration: ${slotDuration.toStringAsFixed(2)} hrs, Current slot: $slot");
      return slot;
    }
  }

  static WordModel? getWordForSlot(List<WordModel> words, int slot) {
    if (words.isEmpty) {
      debugPrint("⚠️ getWordForSlot: words list is empty");
      return null;
    }

    if (slot < 0) {
      debugPrint("⚠️ getWordForSlot: invalid slot $slot");
      return null;
    }

    final index = slot % words.length;
    debugPrint("✅ getWordForSlot: returning word at index $index (slot $slot, total words: ${words.length})");
    return words[index];
  }

  /// Update both home screen and lock screen widgets
  static Future<void> updateHomeWidget(
      WordModel word, String sourceLang, String targetLang) async {
    final source = _getWordByLang(word, sourceLang);
    final target = _getWordByLang(word, targetLang);

    await HomeWidget.saveWidgetData<String>('word', source);
    await HomeWidget.saveWidgetData<String>('translation', target);
    await HomeWidget.saveWidgetData<String>('language', sourceLang);
    await HomeWidget.saveWidgetData<String>(
        'last_updated', DateTime.now().toString());

    await HomeWidget.saveWidgetData<String>('word_short', _truncateText(source, 15));
    await HomeWidget.saveWidgetData<String>('translation_short', _truncateText(target, 15));
    await HomeWidget.saveWidgetData<String>('word_initial', source.isNotEmpty ? source[0].toUpperCase() : '');

    debugPrint("💾 Widget data saved: $source → $target");

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        name: 'HomeWidgetGlanceProvider',
        androidName: 'HomeWidgetGlanceProvider',
      );

      await HomeWidget.updateWidget(
        name: 'LockScreenWidgetProvider',
        androidName: 'LockScreenWidgetProvider',
      );

      debugPrint("🎨 Android home & lock screen widgets updated: $source → $target");
    } else if (Platform.isIOS) {
      await _reloadWidgetKitTimeline();
      debugPrint("🎨 iOS: WidgetKit timeline reloaded (automatic update)");
    }
  }

  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static Future<void> sendWordNotification(WordModel word, String sourceLang, String targetLang) async {
    try {
      final source = _getWordByLang(word, sourceLang);
      final target = _getWordByLang(word, targetLang);

      await PushNotificationService.sendPushNotification(source, target);
      debugPrint("🔔 Notification sent: $source → $target");
    } catch (e) {
      debugPrint("❌ Notification error: $e");
    }
  }

  static String _getWordByLang(WordModel word, String lang) {
    switch (lang.toLowerCase()) {
      case 'german':
        return word.german ?? '';
      case 'english':
        return word.english ?? '';
      case 'french':
        return word.french ?? '';
      case 'italian':
        return word.italian ?? '';
      case 'spanish':
        return word.spanish ?? '';
      case 'chinese':
        return word.chinese ?? '';
      case 'korean':
        return word.korean ?? '';
      case 'portuguese':
        return word.portuguese ?? '';
      case 'japanese':
        return word.japanese ?? '';
      default:
        return '';
    }
  }

  static Future<void> saveDailyWords(List<WordModel> words) async {
    final storage = GetStorage();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final wordList = words.map((w) => w.toJson()).toList();
    await storage.write(DAILY_WORDS_KEY, wordList);
    await storage.write(LAST_FETCH_DATE_KEY, today);
    debugPrint("✅ Daily words saved for $today");
  }

  static List<WordModel> loadDailyWords() {
    final storage = GetStorage();
    List<dynamic> rawList = storage.read(DAILY_WORDS_KEY) ?? [];
    return rawList.map((item) {
      final map = Map<String, dynamic>.from(item);
      return WordModel.fromJson(map, map['id']);
    }).toList();
  }

  static Future<void> saveLanguagePreferences({
    required String sourceLang,
    required String targetLang,
  }) async {
    final storage = GetStorage();
    await storage.write(SOURCE_LANG_KEY, sourceLang);
    await storage.write(TARGET_LANG_KEY, targetLang);
    debugPrint("✅ Language preferences saved: $sourceLang → $targetLang");
  }

  static Future<void> saveDisplayTime(String? displayTime) async {
    final storage = GetStorage();
    if (displayTime != null && displayTime.isNotEmpty) {
      await storage.write(DISPLAY_TIME_KEY, displayTime);
      debugPrint("✅ Display time saved: $displayTime");
    } else {
      await storage.write(DISPLAY_TIME_KEY, DEFAULT_DISPLAY_TIME);
      debugPrint("✅ Display time set to default: $DEFAULT_DISPLAY_TIME");
    }

    if (Platform.isIOS) {
      await _reloadWidgetKitTimeline();
    }
  }

  static String? getDisplayTime() {
    final storage = GetStorage();
    final displayTime = storage.read(DISPLAY_TIME_KEY);
    return displayTime ?? DEFAULT_DISPLAY_TIME;
  }

  static void printWordTimeSlots(List<WordModel> words, String sourceLang, String targetLang, {String? displayTime}) {
    if (words.isEmpty) {
      debugPrint("⚠️ No words available to print time slots");
      return;
    }

    final effectiveDisplayTime = displayTime ?? DEFAULT_DISPLAY_TIME;
    final timeRange = parseDisplayTime(effectiveDisplayTime);

    String formatHourDouble(double h) {
      if (h < 0) h += 24;
      if (h >= 24) h = h % 24;
      int hour = h.floor() % 24;
      int minute = ((h - h.floor()) * 60).round();
      if (minute == 60) {
        hour = (hour + 1) % 24;
        minute = 0;
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    if (timeRange != null) {
      double startHour = timeRange['start']!;
      double endHour = timeRange['end']!;

      double activeDuration;
      if (endHour >= startHour) {
        activeDuration = endHour - startHour;
      } else {
        activeDuration = (24 - startHour) + endHour;
      }

      final slotDuration = activeDuration / words.length;

      debugPrint("\n🕒 Daily Word Time Slots (${words.length} words, ${slotDuration.toStringAsFixed(2)} hour(s) each)");
      debugPrint("📅 Active period: $effectiveDisplayTime\n");

      for (int i = 0; i < words.length; i++) {
        double slotStart = startHour + (i * slotDuration);
        if (slotStart >= 24) slotStart -= 24;
        double slotEnd = slotStart + slotDuration;
        if (slotEnd > 24) slotEnd -= 24;

        final start = formatHourDouble(slotStart);
        final end = formatHourDouble(slotEnd);

        final source = _getWordByLang(words[i], sourceLang);
        final target = _getWordByLang(words[i], targetLang);

        debugPrint("📘 Word ${i + 1}: '$source' → '$target' will be shown from $start to $end");
      }
    }
  }

  static Future<void> updateWidgetWithWordsList(
      List<WordModel> words, {
        String? sourceLang,
        String? targetLang,
        String? displayTime,
      }) async {
    if (words.isEmpty) {
      debugPrint("⚠️ No words to update widget with");
      return;
    }

    final storage = GetStorage();
    final source = sourceLang ?? storage.read(SOURCE_LANG_KEY) ?? 'german';
    final target = targetLang ?? storage.read(TARGET_LANG_KEY) ?? 'english';
    final displayTimeRange = displayTime ?? storage.read(DISPLAY_TIME_KEY) ?? DEFAULT_DISPLAY_TIME;

    await saveDailyWords(words);
    printWordTimeSlots(words, source, target, displayTime: displayTimeRange);

    final currentSlot = getCurrentTimeSlot(words.length, displayTime: displayTimeRange);

    if (currentSlot < 0) {
      debugPrint("⏰ Outside display time range - using first word");
      final firstWord = words[0];
      await updateHomeWidget(firstWord, source, target);
      await storage.write(CURRENT_WORD_INDEX_KEY, 0);
      await storage.write(LAST_SHOWN_SLOT_KEY, 0);
      debugPrint("🎨 Widgets updated with first word (outside display time)");

      await scheduleImmediateUpdate();
      return;
    }

    final currentWord = getWordForSlot(words, currentSlot);

    if (currentWord != null) {
      await updateHomeWidget(currentWord, source, target);
      await storage.write(CURRENT_WORD_INDEX_KEY, currentSlot);
      await storage.write(LAST_SHOWN_SLOT_KEY, currentSlot);
      debugPrint("🎨 Widgets updated with fetched words (slot $currentSlot)");

      await scheduleImmediateUpdate();
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔄 [Android WorkManager] Task started: $task at ${DateTime.now()}");

    try {
      await GetStorage.init();

      final storage = GetStorage();
      final sourceLang = storage.read(BackgroundTaskService.SOURCE_LANG_KEY) ?? 'german';
      final targetLang = storage.read(BackgroundTaskService.TARGET_LANG_KEY) ?? 'english';
      final displayTime = storage.read(BackgroundTaskService.DISPLAY_TIME_KEY) ?? BackgroundTaskService.DEFAULT_DISPLAY_TIME;

      if (task == BackgroundTaskService.MIDNIGHT_FETCH_TASK) {
        debugPrint("🌙 Midnight task detected - fetching new day's words");
        await BackgroundTaskService.fetchNewDayWords(
          sourceLang: sourceLang,
          targetLang: targetLang,
          displayTime: displayTime,
        );
      } else {
        await BackgroundTaskService.checkAndUpdateWords(
          sourceLang: sourceLang,
          targetLang: targetLang,
          displayTime: displayTime,
        );
      }

      debugPrint("✅ [Android WorkManager] Task completed at ${DateTime.now()}");
      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint("❌ [Android WorkManager] Task failed: $e");
      debugPrint("Stack trace: $stackTrace");
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(bf.HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;

  if (isTimeout) {
    debugPrint('⏱️ [iOS Headless] Task timeout: $taskId');
    bf.BackgroundFetch.finish(taskId);
    return;
  }

  debugPrint('🔄 [iOS Headless] Task started: $taskId');

  try {
    await GetStorage.init();

    final storage = GetStorage();
    final sourceLang = storage.read(BackgroundTaskService.SOURCE_LANG_KEY) ?? 'german';
    final targetLang = storage.read(BackgroundTaskService.TARGET_LANG_KEY) ?? 'english';
    final displayTime = storage.read(BackgroundTaskService.DISPLAY_TIME_KEY) ?? BackgroundTaskService.DEFAULT_DISPLAY_TIME;

    if (taskId == "com.lingobuzz.midnight") {
      debugPrint("🌙 Midnight task detected - fetching new day's words");
      await BackgroundTaskService.fetchNewDayWords(
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: displayTime,
      );
    } else {
      await BackgroundTaskService.checkAndUpdateWords(
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: displayTime,
      );
    }

    debugPrint('✅ [iOS Headless] Task completed: $taskId');
  } catch (e) {
    debugPrint('❌ [iOS Headless] Task failed: $e');
  }

  bf.BackgroundFetch.finish(taskId);
}