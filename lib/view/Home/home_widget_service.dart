import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/core/services/background_task_services.dart';
import 'package:lingobuzz/model/word_model.dart';
import '../../core/services/app_services.dart';

class HomeWidgetService {
  static const String androidProviderName = 'HomeWidgetGlanceProvider';
  static const String androidLockScreenProviderName = 'LockScreenWidgetProvider';
  static const String iosHomeWidgetName = 'WordsWidget';
  static const String iosLockCircularName = 'LockScreenCircularWidget';
  static const String iosLockRectangularName = 'LockScreenRectangularWidget';
  static const String iosLockInlineName = 'LockScreenInlineWidget';
  static const String appGroupId = 'group.com.lingobuzz.app';
  static const MethodChannel _widgetKitChannel = MethodChannel('widgetkit_reload');
  static const MethodChannel _widgetActionsChannel = MethodChannel('widget_actions');

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// INITIALIZATION
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<void> initialize() async {
    try {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('🚀 Initializing HomeWidgetService');
      debugPrint('═══════════════════════════════════════════════════');

      await HomeWidget.setAppGroupId(appGroupId);
      debugPrint('✅ App Group ID set: $appGroupId');

      HomeWidget.registerBackgroundCallback(backgroundCallback);
      debugPrint('✅ Background callback registered');

      if (Platform.isIOS) {
        await _setupIOSListeners();
      }

      await _setupWidgetClickHandlers();

      // ✅ FIX: Force immediate widget update after initialization
      await loadAndUpdateWidget();

      // ✅ FIX: Reload timeline after initial load
      if (Platform.isIOS) {
        await Future.delayed(Duration(milliseconds: 500));
        await _reloadWidgetKitTimeline();
      }

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('✅ HomeWidgetService initialized successfully');
      debugPrint('═══════════════════════════════════════════════════');
    } catch (e, st) {
      debugPrint('❌ Error initializing HomeWidgetService: $e');
      debugPrint('Stack trace: $st');
    }
  }

  static Future<void> _setupIOSListeners() async {
    try {
      _widgetActionsChannel.setMethodCallHandler((call) async {
        if (call.method == 'onWidgetAction') {
          final action = call.arguments['action'] as String?;
          debugPrint('📱 iOS Widget Action: $action');
          await _handleWidgetAction(action);
        }
      });
      debugPrint('✅ iOS widget action listeners configured');
    } catch (e) {
      debugPrint('⚠️ iOS listeners setup failed: $e');
    }
  }

  static Future<void> _setupWidgetClickHandlers() async {
    try {
      final Uri? initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        debugPrint('🔗 App launched from widget: $initialUri');
        await handleWidgetClick(initialUri);
      }

      HomeWidget.widgetClicked.listen((uri) async {
        if (uri != null) {
          debugPrint('🖱️ Widget clicked: $uri');
          await handleWidgetClick(uri);
        }
      });

      debugPrint('✅ Widget click handlers registered');
    } catch (e) {
      debugPrint('❌ Error setting up click handlers: $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// DATA MANAGEMENT
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<void> loadAndUpdateWidget() async {
    try {
      debugPrint('\n┌─────────────────────────────────────────────────┐');
      debugPrint('│ 🔄 Loading and Updating Widgets                │');
      debugPrint('└─────────────────────────────────────────────────┘');

      final storage = GetStorage();

      final isSetupDone = storage.read('isSetupDone') ?? false;
      debugPrint('📋 Setup Status: ${isSetupDone ? "Complete" : "Incomplete"}');

      if (!isSetupDone) {
        debugPrint('⚠️ Setup not complete - showing default widget');
        await _showSetupRequiredWidget();
        return;
      }

      final dailyWords = BackgroundTaskService.loadDailyWords();
      debugPrint('📚 Daily Words Count: ${dailyWords.length}');

      if (dailyWords.isEmpty) {
        debugPrint('⚠️ No daily words available');
        await _showNoWordsWidget();
        return;
      }

      // ✅ FIX: Always get fresh language settings from storage
      final sourceLang = storage.read(BackgroundTaskService.SOURCE_LANG_KEY) ?? 'german';
      final targetLang = storage.read(BackgroundTaskService.TARGET_LANG_KEY) ?? 'english';
      final displayTime = storage.read(BackgroundTaskService.DISPLAY_TIME_KEY) ?? BackgroundTaskService.DEFAULT_DISPLAY_TIME;

      debugPrint('🌍 Source Language: $sourceLang');
      debugPrint('🌍 Target Language: $targetLang');
      debugPrint('⏰ Display Time: $displayTime');

      // ✅ FIX: Save all data BEFORE determining current word
      await _saveAllDataToSharedStorage(
        words: dailyWords,
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: displayTime,
      );

      // ✅ FIX: Get current time slot with correct display time
      final currentSlot = BackgroundTaskService.getCurrentTimeSlot(
        dailyWords.length,
        displayTime: displayTime,
      );

      debugPrint('📍 Current Time Slot: $currentSlot');

      WordModel currentWord;
      if (currentSlot < 0) {
        debugPrint('⏰ Outside display time - using first word');
        currentWord = dailyWords[0];
      } else {
        currentWord = BackgroundTaskService.getWordForSlot(dailyWords, currentSlot) ?? dailyWords[0];
        debugPrint('✅ Using word from slot $currentSlot');
      }

      // ✅ FIX: Update widget with correct translations
      await updateWidgetWithWord(
        word: currentWord,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      // ✅ FIX: Force platform-specific update
      await _triggerWidgetUpdate();

      // ✅ FIX: Additional reload for iOS to ensure timeline refreshes
      if (Platform.isIOS) {
        await Future.delayed(Duration(milliseconds: 300));
        await _reloadWidgetKitTimeline();
      }

      debugPrint('┌─────────────────────────────────────────────────┐');
      debugPrint('│ ✅ Widget Update Complete                       │');
      debugPrint('└─────────────────────────────────────────────────┘\n');
    } catch (e, st) {
      debugPrint('❌ Error in loadAndUpdateWidget: $e');
      debugPrint('Stack trace: $st');
    }
  }

  static Future<void> _saveAllDataToSharedStorage({
    required List<WordModel> words,
    required String sourceLang,
    required String targetLang,
    String? displayTime,
  }) async {
    try {
      debugPrint('\n📦 Saving data to shared storage...');

      final wordsArray = words.map((word) => {
        'id': word.id ?? '',
        'german': word.german ?? '',
        'english': word.english ?? '',
        'french': word.french ?? '',
        'italian': word.italian ?? '',
        'spanish': word.spanish ?? '',
        'chinese': word.chinese ?? '',
        'korean': word.korean ?? '',
        'portuguese': word.portuguese ?? '',
        'japanese': word.japanese ?? '',
      }).toList();

      if (Platform.isAndroid) {
        final jsonString = jsonEncode(wordsArray);
        await HomeWidget.saveWidgetData<String>('daily_words_json', jsonString);
        debugPrint('💾 Android: Saved ${words.length} words as JSON');
      } else {
        await HomeWidget.saveWidgetData('daily_words', wordsArray);
        debugPrint('💾 iOS: Saved ${words.length} words as array');
      }

      await HomeWidget.saveWidgetData<String>('sourceLang', sourceLang);
      await HomeWidget.saveWidgetData<String>('targetLang', targetLang);
      await HomeWidget.saveWidgetData<bool>('isSetupDone', true);

      // ✅ FIX: Always save display time (use default if null)
      final effectiveDisplayTime = displayTime ?? BackgroundTaskService.DEFAULT_DISPLAY_TIME;
      await HomeWidget.saveWidgetData<String>('displayTime', effectiveDisplayTime);
      debugPrint('💾 Display time saved: $effectiveDisplayTime');

      await HomeWidget.saveWidgetData<String>(
        'last_sync',
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.saveWidgetData<int>('word_count', words.length);

      debugPrint('✅ All data saved to shared storage');
      debugPrint('   - Words: ${words.length}');
      debugPrint('   - Languages: $sourceLang → $targetLang');
      debugPrint('   - Display Time: $effectiveDisplayTime');
    } catch (e) {
      debugPrint('❌ Error saving to shared storage: $e');
    }
  }

  static Future<void> _showSetupRequiredWidget() async {
    await HomeWidget.saveWidgetData<String>('word', 'Setup');
    await HomeWidget.saveWidgetData<String>('translation', 'Required');
    await HomeWidget.saveWidgetData<String>('language', '');
    await HomeWidget.saveWidgetData<String>('word_short', 'Setup');
    await HomeWidget.saveWidgetData<String>('translation_short', 'Required');
    await HomeWidget.saveWidgetData<String>('word_initial', 'S');
    await _triggerWidgetUpdate();
  }

  static Future<void> _showNoWordsWidget() async {
    await HomeWidget.saveWidgetData<String>('word', 'No Words');
    await HomeWidget.saveWidgetData<String>('translation', 'Add words in app');
    await HomeWidget.saveWidgetData<String>('language', '');
    await HomeWidget.saveWidgetData<String>('word_short', 'No Words');
    await HomeWidget.saveWidgetData<String>('translation_short', 'Add words');
    await HomeWidget.saveWidgetData<String>('word_initial', 'N');
    await _triggerWidgetUpdate();
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// WIDGET UPDATE METHODS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<void> updateWidget({
    required String word,
    required String translation,
    String? language,
    String? wordId,
  }) async {
    try {
      debugPrint('\n🎨 Updating widget display:');
      debugPrint('   Word: $word');
      debugPrint('   Translation: $translation');
      debugPrint('   Language: ${language ?? "Unknown"}');

      await HomeWidget.saveWidgetData<String>('word', word);
      await HomeWidget.saveWidgetData<String>('translation', translation);
      await HomeWidget.saveWidgetData<String>('language', language ?? 'Unknown');
      await HomeWidget.saveWidgetData<String>('word_id', wordId ?? '');

      await HomeWidget.saveWidgetData<String>('word_short', _truncateText(word, 15));
      await HomeWidget.saveWidgetData<String>('translation_short', _truncateText(translation, 15));
      await HomeWidget.saveWidgetData<String>('word_initial', word.isNotEmpty ? word[0].toUpperCase() : '?');

      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateTime.now().toIso8601String(),
      );

      debugPrint('✅ Widget data saved successfully');

      await _triggerWidgetUpdate();
    } catch (e, st) {
      debugPrint('❌ Error updating widget: $e');
      debugPrint('Stack trace: $st');
    }
  }

  static Future<void> updateWidgetWithWord({
    required WordModel word,
    required String sourceLang,
    required String targetLang,
  }) async {
    final sourceText = _getWordByLang(word, sourceLang);
    final targetText = _getWordByLang(word, targetLang);

    if (sourceText.isEmpty || targetText.isEmpty) {
      debugPrint('⚠️ Cannot update widget - missing translations');
      debugPrint('   Source ($sourceLang): "$sourceText"');
      debugPrint('   Target ($targetLang): "$targetText"');
      return;
    }

    await updateWidget(
      word: sourceText,
      translation: targetText,
      language: sourceLang,
      wordId: word.id,
    );
  }

  static Future<void> updateWidgetWithWordsList({
    required List<WordModel> words,
    required String sourceLang,
    required String targetLang,
    String? displayTime,
  }) async {
    try {
      debugPrint('\n╔═══════════════════════════════════════════════════╗');
      debugPrint('║ 📝 Updating Widgets with Words List              ║');
      debugPrint('╚═══════════════════════════════════════════════════╝');
      debugPrint('Words Count: ${words.length}');
      debugPrint('Languages: $sourceLang → $targetLang');

      // ✅ FIX: Use default display time if not provided
      final effectiveDisplayTime = displayTime ?? BackgroundTaskService.DEFAULT_DISPLAY_TIME;
      debugPrint('Display Time: $effectiveDisplayTime');

      if (words.isEmpty) {
        debugPrint('⚠️ No words provided');
        await _showNoWordsWidget();
        return;
      }

      int validWords = 0;
      for (var word in words) {
        final source = _getWordByLang(word, sourceLang);
        final target = _getWordByLang(word, targetLang);
        if (source.isNotEmpty && target.isNotEmpty) {
          validWords++;
        }
      }

      debugPrint('Valid words with translations: $validWords/${words.length}');

      if (validWords == 0) {
        debugPrint('❌ No valid word translations found');
        await _showNoWordsWidget();
        return;
      }

      // ✅ FIX: Save all data with effective display time
      await _saveAllDataToSharedStorage(
        words: words,
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: effectiveDisplayTime,
      );

      await BackgroundTaskService.saveDailyWords(words);
      await BackgroundTaskService.saveLanguagePreferences(
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
      await BackgroundTaskService.saveDisplayTime(effectiveDisplayTime);

      // ✅ FIX: Get current slot with effective display time
      final currentSlot = BackgroundTaskService.getCurrentTimeSlot(
        words.length,
        displayTime: effectiveDisplayTime,
      );

      WordModel currentWord;
      if (currentSlot < 0) {
        debugPrint('⏰ Outside display hours - using first word');
        currentWord = words[0];
      } else {
        currentWord = BackgroundTaskService.getWordForSlot(words, currentSlot) ?? words[0];
        debugPrint('✅ Current slot: $currentSlot/${words.length}');
      }

      await updateWidgetWithWord(
        word: currentWord,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      BackgroundTaskService.printWordTimeSlots(
        words,
        sourceLang,
        targetLang,
        displayTime: effectiveDisplayTime,
      );

      // ✅ FIX: Multiple update triggers to ensure widgets refresh
      await _triggerWidgetUpdate();

      if (Platform.isIOS) {
        await Future.delayed(Duration(milliseconds: 500));
        await _reloadWidgetKitTimeline();
      }

      debugPrint('╔═══════════════════════════════════════════════════╗');
      debugPrint('║ ✅ Widget List Update Complete                    ║');
      debugPrint('╚═══════════════════════════════════════════════════╝\n');
    } catch (e, st) {
      debugPrint('❌ Error updating widget with list: $e');
      debugPrint('Stack trace: $st');
    }
  }

  static Future<void> _triggerWidgetUpdate() async {
    try {
      if (Platform.isAndroid) {
        final homeResult = await HomeWidget.updateWidget(
          name: androidProviderName,
          androidName: androidProviderName,
        );

        final lockResult = await HomeWidget.updateWidget(
          name: androidLockScreenProviderName,
          androidName: androidLockScreenProviderName,
        );

        debugPrint('📱 Android Widgets Updated:');
        debugPrint('   Home Screen: ${homeResult == true ? "✅" : "⚠️"}');
        debugPrint('   Lock Screen: ${lockResult == true ? "✅" : "⚠️"}');
      } else if (Platform.isIOS) {
        await _reloadWidgetKitTimeline();
        debugPrint('📱 iOS: WidgetKit timelines reloaded');
        debugPrint('   Home Widget: ✅');
        debugPrint('   Lock Screen Widgets: ✅ (Circular, Rectangular, Inline)');
      }
    } catch (e) {
      debugPrint('⚠️ Error triggering widget update: $e');
    }
  }

  static Future<void> _reloadWidgetKitTimeline() async {
    if (!Platform.isIOS) return;

    try {
      final result = await _widgetKitChannel.invokeMethod('reloadAllTimelines');
      debugPrint('🔄 WidgetKit reload result: $result');
    } catch (e) {
      debugPrint('⚠️ WidgetKit reload channel error (may be normal): $e');
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// WIDGET ACTIONS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<void> handleWidgetClick(Uri uri) async {
    debugPrint('\n🖱️ Widget Click Detected:');
    debugPrint('   URI: $uri');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');

    try {
      final action = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
      await _handleWidgetAction(action);
    } catch (e, st) {
      debugPrint('❌ Error handling widget click: $e');
      debugPrint('Stack trace: $st');
    }
  }

  static Future<void> _handleWidgetAction(String? action) async {
    if (action == null || action.isEmpty) {
      debugPrint('⚠️ No action specified');
      return;
    }

    debugPrint('🎯 Handling Action: $action');

    switch (action.toLowerCase()) {
      case 'play':
        await _handlePlayAction();
        break;
      case 'save':
        await _handleSaveAction();
        break;
      case 'next':
        await _handleNextAction();
        break;
      case 'refresh':
        await _handleRefreshAction();
        break;
      case 'open':
      case 'widget':
        await _handleOpenAction();
        break;
      default:
        debugPrint('⚠️ Unknown action: $action');
    }
  }

  static Future<void> _handlePlayAction() async {
    debugPrint('🔊 Play Action Triggered');

    try {
      final word = await HomeWidget.getWidgetData<String>('word');

      if (word == null || word.isEmpty) {
        debugPrint('⚠️ No word to play');
        return;
      }

      debugPrint('🔊 Playing word: $word');
      await AppServices.speakText(word);
      debugPrint('✅ Audio playback initiated');
    } catch (e) {
      debugPrint('❌ Error playing word: $e');
    }
  }

  static Future<void> _handleSaveAction() async {
    debugPrint('⭐ Save Action Triggered');

    try {
      final wordId = await HomeWidget.getWidgetData<String>('word_id');

      if (wordId == null || wordId.isEmpty) {
        debugPrint('⚠️ No word ID available');
        return;
      }

      if (!Get.isRegistered<WordController>()) {
        debugPrint('⚠️ WordController not registered');
        return;
      }

      final wordController = Get.find<WordController>();
      final word = wordController.wordsList.firstWhereOrNull(
            (w) => w.id == wordId,
      );

      if (word == null) {
        debugPrint('⚠️ Word not found in controller: $wordId');
        return;
      }

      await wordController.toggleSaveWord(word);
      debugPrint('✅ Word saved/unsaved: ${word.id}');
    } catch (e) {
      debugPrint('❌ Error saving word: $e');
    }
  }

  static Future<void> _handleNextAction() async {
    debugPrint('⏭️ Next Action Triggered');

    try {
      final storage = GetStorage();
      final dailyWords = BackgroundTaskService.loadDailyWords();

      if (dailyWords.isEmpty) {
        debugPrint('⚠️ No daily words available');
        return;
      }

      final currentIndex = storage.read(BackgroundTaskService.CURRENT_WORD_INDEX_KEY) ?? 0;
      final nextIndex = (currentIndex + 1) % dailyWords.length;

      debugPrint('Moving from word $currentIndex to $nextIndex');

      await storage.write(BackgroundTaskService.CURRENT_WORD_INDEX_KEY, nextIndex);

      final sourceLang = storage.read(BackgroundTaskService.SOURCE_LANG_KEY) ?? 'german';
      final targetLang = storage.read(BackgroundTaskService.TARGET_LANG_KEY) ?? 'english';

      final nextWord = dailyWords[nextIndex];
      await updateWidgetWithWord(
        word: nextWord,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      debugPrint('✅ Moved to word ${nextIndex + 1}/${dailyWords.length}');
    } catch (e) {
      debugPrint('❌ Error showing next word: $e');
    }
  }

  static Future<void> _handleRefreshAction() async {
    debugPrint('🔄 Refresh Action Triggered');

    try {
      await loadAndUpdateWidget();
      debugPrint('✅ Widget refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing widget: $e');
    }
  }

  static Future<void> _handleOpenAction() async {
    debugPrint('📱 Open App Action Triggered');
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// UTILITY METHODS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
        debugPrint('⚠️ Unknown language: $lang');
        return '';
    }
  }

  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// PUBLIC UTILITY METHODS
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<void> refreshWidget() async {
    debugPrint('🔄 Public refresh widget called');
    await loadAndUpdateWidget();
  }

  static Future<void> clearWidget() async {
    try {
      debugPrint('🗑️ Clearing all widget data');

      await HomeWidget.saveWidgetData<String>('word', '');
      await HomeWidget.saveWidgetData<String>('translation', '');
      await HomeWidget.saveWidgetData<String>('language', '');
      await HomeWidget.saveWidgetData<String>('word_id', '');
      await HomeWidget.saveWidgetData<String>('word_short', '');
      await HomeWidget.saveWidgetData<String>('translation_short', '');
      await HomeWidget.saveWidgetData<String>('word_initial', '');
      await HomeWidget.saveWidgetData<String>('last_updated', '');
      await HomeWidget.saveWidgetData<bool>('isSetupDone', false);

      await _triggerWidgetUpdate();

      debugPrint('✅ Widget data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing widget: $e');
    }
  }

  static Future<bool> isWidgetAvailable() async {
    try {
      final word = await HomeWidget.getWidgetData<String>('word');
      return word != null && word.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, String>> getCurrentWidgetData() async {
    try {
      final word = await HomeWidget.getWidgetData<String>('word') ?? '';
      final translation = await HomeWidget.getWidgetData<String>('translation') ?? '';
      final language = await HomeWidget.getWidgetData<String>('language') ?? '';
      final wordId = await HomeWidget.getWidgetData<String>('word_id') ?? '';
      final lastUpdated = await HomeWidget.getWidgetData<String>('last_updated') ?? '';

      return {
        'word': word,
        'translation': translation,
        'language': language,
        'word_id': wordId,
        'last_updated': lastUpdated,
      };
    } catch (e) {
      debugPrint('❌ Error getting widget data: $e');
      return {};
    }
  }

  static Future<void> forceUpdate() async {
    debugPrint('⚡ Force update triggered');

    try {
      await loadAndUpdateWidget();

      if (Platform.isIOS) {
        await Future.delayed(Duration(milliseconds: 500));
        await _reloadWidgetKitTimeline();
      }

      debugPrint('✅ Force update complete');
    } catch (e) {
      debugPrint('❌ Error in force update: $e');
    }
  }
}

@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  debugPrint('\n╔═══════════════════════════════════════════════════════════╗');
  debugPrint('║           BACKGROUND CALLBACK TRIGGERED                   ║');
  debugPrint('╚═══════════════════════════════════════════════════════════╝');
  debugPrint('URI: $uri');
  debugPrint('Time: ${DateTime.now()}');

  try {
    await GetStorage.init();
    debugPrint('✅ GetStorage initialized');

    if (uri != null) {
      final action = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');
      debugPrint('🎯 Action: $action');

      switch (action.toLowerCase()) {
        case 'refresh':
          debugPrint('🔄 Executing refresh in background');
          await HomeWidgetService.loadAndUpdateWidget();
          break;

        case 'next':
          debugPrint('⏭️ Executing next word in background');
          await HomeWidgetService._handleNextAction();
          break;

        default:
          debugPrint('⚠️ Action "$action" requires foreground app');
      }
    } else {
      debugPrint('ℹ️ No specific action - performing general refresh');
      await HomeWidgetService.loadAndUpdateWidget();
    }

    debugPrint('✅ Background callback completed successfully');
  } catch (e, st) {
    debugPrint('❌ Background callback error: $e');
    debugPrint('Stack trace: $st');
  }

  debugPrint('╚═══════════════════════════════════════════════════════════╝\n');
}

class WidgetKit {
  static const MethodChannel _channel = MethodChannel('widgetkit_reload');

  static Future<void> reloadAllTimelines() async {
    if (!Platform.isIOS) {
      debugPrint('⚠️ WidgetKit is only available on iOS');
      return;
    }

    try {
      final result = await _channel.invokeMethod('reloadAllTimelines');
      debugPrint('🔄 WidgetKit: Timeline reload result: $result');
    } catch (e) {
      debugPrint('⚠️ WidgetKit reload error (may be normal): $e');
    }
  }

  static Future<void> reloadWidget(String kind) async {
    if (!Platform.isIOS) {
      debugPrint('⚠️ WidgetKit is only available on iOS');
      return;
    }

    try {
      final result = await _channel.invokeMethod('reloadTimeline', {'kind': kind});
      debugPrint('🔄 WidgetKit: Reloaded $kind - Result: $result');
    } catch (e) {
      debugPrint('⚠️ WidgetKit reload error for $kind: $e');
    }
  }
}