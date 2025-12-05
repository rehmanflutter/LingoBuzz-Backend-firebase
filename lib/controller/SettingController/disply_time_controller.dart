// ✅ COMPLETE FIX: Display Time Update Handler
// Add this to your settings controller or wherever you handle display time changes

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/core/services/background_task_services.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import '../../model/word_model.dart';
import '../../view/Home/home_widget_service.dart';

class DisplayTimeUpdateHandler {
  final box = GetStorage();

  /// ✅ FIX: Proper display time update with immediate widget refresh
  Future<void> updateDisplayTime(String newDisplayTime) async {
    print('\n╔═══════════════════════════════════════════════════════════╗');
    print('║           UPDATING DISPLAY TIME                           ║');
    print('╚═══════════════════════════════════════════════════════════╝');
    print('🕐 New display time: $newDisplayTime');

    try {
      // 1. Save display time to storage
      await BackgroundTaskService.saveDisplayTime(newDisplayTime);
      print('✅ Display time saved to storage');

      // 2. Get current word list
      final wordController = Get.find<WordController>();
      final dailyWords = BackgroundTaskService.loadDailyWords();

      if (dailyWords.isEmpty) {
        print('⚠️ No daily words available - skipping widget update');
        return;
      }

      print('📚 Daily words count: ${dailyWords.length}');

      // 3. Get language preferences
      final sourceLang = box.read(BackgroundTaskService.SOURCE_LANG_KEY) ?? 'german';
      final targetLang = box.read(BackgroundTaskService.TARGET_LANG_KEY) ?? 'english';

      print('🌍 Languages: $sourceLang → $targetLang');

      // 4. Calculate new current slot with new display time
      final currentSlot = BackgroundTaskService.getCurrentTimeSlot(
        dailyWords.length,
        displayTime: newDisplayTime,
      );

      print('📍 New current slot: $currentSlot');

      // 5. Get the word for the new current slot
      WordModel currentWord;
      if (currentSlot < 0) {
        print('⏰ Outside new display time - using first word');
        currentWord = dailyWords[0];
      } else {
        currentWord = BackgroundTaskService.getWordForSlot(dailyWords, currentSlot) ?? dailyWords[0];
        print('✅ Using word from slot $currentSlot');
      }

      // 6. Update widget with new word and display time
      await HomeWidgetService.updateWidgetWithWordsList(
        words: dailyWords,
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: newDisplayTime,
      );

      print('🎨 Widget updated with new display time');

      // 7. Force widget refresh
      await HomeWidgetService.forceUpdate();

      // 8. Print new time slots
      BackgroundTaskService.printWordTimeSlots(
        dailyWords,
        sourceLang,
        targetLang,
        displayTime: newDisplayTime,
      );

      // 9. Reset last shown slot to force update
      await box.write(BackgroundTaskService.LAST_SHOWN_SLOT_KEY, -1);

      // 10. Trigger immediate background check
      await BackgroundTaskService.checkAndUpdateWords(
        sourceLang: sourceLang,
        targetLang: targetLang,
        displayTime: newDisplayTime,
      );

      print('╔═══════════════════════════════════════════════════════════╗');
      print('║           DISPLAY TIME UPDATE COMPLETE                    ║');
      print('╚═══════════════════════════════════════════════════════════╝\n');

    } catch (e, st) {
      print('❌ Error updating display time: $e');
      print('Stack trace: $st');
    }
  }
}