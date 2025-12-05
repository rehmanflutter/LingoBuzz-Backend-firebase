// import 'package:flutter_tts/flutter_tts.dart';

// class AppServices {
//   static final FlutterTts _flutterTts = FlutterTts();

//   /// Speaks the given [text] aloud using text-to-speech.
//   static Future<void> speakText(String text) async {
//     if (text.isEmpty) return;

//     await _flutterTts.setLanguage(
//       "en-US",
//     ); // You can change to "fr-FR", "ur-PK", etc.
//     await _flutterTts.setPitch(1.0); // Normal pitch
//     await _flutterTts.setSpeechRate(0.5); // Slower speed
//     await _flutterTts.speak(text); // Speak text
//   }

//   /// Optional: Stop speaking immediately
//   static Future<void> stopSpeaking() async {
//     await _flutterTts.stop();
//   }
// }
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'dart:io';

import '../common/helpers/app_logger.dart';

class AppServices {
  static final FlutterTts _flutterTts = FlutterTts();


  /// Initialize TTS with platform-specific settings
  static Future<void> initializeTTS() async {
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
  }

  /// Speaks the given [text] aloud using text-to-speech.
  /// Converts language name (e.g. "German") to language code automatically.
  static Future<void> speakText(
      String text) async {
    if (text.isEmpty) return;
    final controller = Get.find<AuthController>();
    String languageName = controller.currentUser.value?.currentLearning?.languageName??"English";

    final languageCode = _getLanguageCode(languageName);
    Log.debug('🔊 Speaking in $languageName ($languageCode): $text');

    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.setPitch(1.0); // Normal pitch
    await _flutterTts.setSpeechRate(0.5); // Slower speed
    await _flutterTts.speak(text);
  }

  /// Converts a language name into a valid TTS language code.
  static String _getLanguageCode(String languageName) {
    switch (languageName.toLowerCase()) {
      case "english":
        return "en-US";
      case "german":
        return "de-DE";
      case "french":
        return "fr-FR";
      case "spanish":
        return "es-ES";
      case "italian":
        return "it-IT";
      case "portuguese":
        return "pt-PT";
      case "japanese":
        return "ja-JP";
      case "chinese":
        return "zh-CN";
      case "korean":
        return "ko-KR";
      case "arabic":
        return "ar-SA";
      case "hindi":
        return "hi-IN";
      case "turkish":
        return "tr-TR";
      case "russian":
        return "ru-RU";
      default:
        return "en-US"; // Default to English if not found
    }
  }


  /// Speak word in English pronunciation
  static Future<void> speakWord(String word) async {
    final controller = Get.find<AuthController>();
    String languageName = controller.currentUser.value?.currentLearning?.languageName??"English";
    // Always speak in English pronunciation
    await speakText(word);
  }

  /// Stop speaking immediately
  static Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

}
