import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/controller/app_info_controller.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/common/snackbar_utils.dart';
import '../../core/services/background_task_services.dart';
import 'disply_time_controller.dart';

class SettingController extends GetxController {
  final box = GetStorage();
  final displayTimeHandler = DisplayTimeUpdateHandler();


  /// ------------------ LEARNING PREFERENCES ------------------
  RxString selectedLevel = 'A2'.obs;
  final List<String> levels = ['A1', 'A2', 'A3', 'A4'];

  /// ------------------ LANGUAGE SETTINGS ------------------
  RxString learningLanguage = 'French'.obs;
  final List<String> learningLanguages = [
    'French',
    'Spanish',
    'German',
    'Italian',
  ];

  RxString interfaceLanguage = 'English'.obs;
  final List<String> interfaceLanguages = [
    'English',
    'French',
    'Spanish',
    'Urdu',
  ];

  /// ------------------ NOTIFICATIONS ------------------
  RxBool pushNotifications = true.obs;
  RxBool dailyReminders = true.obs;
  RxBool widgetUpdates = true.obs;

  /// ------------------ TIME SETTINGS ------------------
  RxString displayTime = '8:00AM - 8:00PM'.obs;
  final List<String> displayTimes = [
    '8:00AM - 8:00PM',
    '9:00AM - 9:00PM',
    '12:00AM - 11:59PM',
  ];

  /// ------------------ AUDIO SETTINGS ------------------
  RxBool soundEffects = true.obs;
  RxDouble volume = 75.0.obs;

  /// ------------------ APP PREFERENCES ------------------
  RxString theme = 'System'.obs;
  final List<String> themes = ['System', 'Light', 'Dark'];

  RxString difficulty = 'Adaptive'.obs;
  final List<String> difficulties = ['Easy', 'Medium', 'Hard', 'Adaptive'];

  /// ------------------ INIT (LOAD FROM CACHE) ------------------
  @override
  void onInit() {
    super.onInit();
    _loadSettingsFromCache();
  }

  /// ✅ Load all settings from cache
  void _loadSettingsFromCache() {
    selectedLevel.value = box.read('selectedLevel') ?? 'A2';
    learningLanguage.value = box.read('learningLanguage') ?? 'French';
    interfaceLanguage.value = box.read('interfaceLanguage') ?? 'English';

    pushNotifications.value = box.read('pushNotifications') ?? true;
    dailyReminders.value = box.read('dailyReminders') ?? true;
    widgetUpdates.value = box.read('widgetUpdates') ?? true;

    displayTime.value = box.read('displayTime') ?? BackgroundTaskService.DEFAULT_DISPLAY_TIME;

    soundEffects.value = box.read('soundEffects') ?? true;
    volume.value = (box.read('volume') ?? 75.0).toDouble();

    theme.value = box.read('theme') ?? 'System';
    difficulty.value = box.read('difficulty') ?? 'Adaptive';
  }

  /// ------------------ SAVE METHODS ------------------
  Future<void> setLevel(String level) async {
    selectedLevel.value = level;
    await box.write('selectedLevel', level);
  }

  Future<void> setLearningLanguage(String lang) async {
    learningLanguage.value = lang;
    await box.write('learningLanguage', lang);
  }

  Future<void> setInterfaceLanguage(String lang) async {
    interfaceLanguage.value = lang;
    await box.write('interfaceLanguage', lang);
  }

  Future<void> setDisplayTime(String time) async {
    displayTime.value = time;
    await displayTimeHandler.updateDisplayTime(time);
  }

  Future<void> setTheme(String themeMode) async {
    theme.value = themeMode;
    await box.write('theme', themeMode);
  }

  Future<void> setDifficulty(String diff) async {
    difficulty.value = diff;
    await box.write('difficulty', diff);
  }

  Future<void> setVolume(double value) async {
    volume.value = value;
    await box.write('volume', value);
  }

  /// ------------------ TOGGLE METHODS ------------------
  void togglePushNotifications() {
    pushNotifications.value = !pushNotifications.value;
    box.write('pushNotifications', pushNotifications.value);
  }

  void toggleDailyReminders() {
    dailyReminders.value = !dailyReminders.value;
    box.write('dailyReminders', dailyReminders.value);
  }

  void toggleWidgetUpdates() {
    widgetUpdates.value = !widgetUpdates.value;
    box.write('widgetUpdates', widgetUpdates.value);
  }

  void toggleSoundEffects() {
    soundEffects.value = !soundEffects.value;
    box.write('soundEffects', soundEffects.value);
  }


  /// ✅ Invite a Friend (modern Share Plus API)
  Future<void> inviteFriend() async {
    final AppInfoController appInfoController = Get.find<AppInfoController>();

    try {
      final appInfo = appInfoController.appInfo.value;

      final appStoreUrl = appInfo?.appstoreUrl?.trim();
      final playStoreUrl = appInfo?.playstoreUrl?.trim();

      // Build download section dynamically
      String downloadSection = '';
      if (playStoreUrl != null && playStoreUrl.isNotEmpty) {
        downloadSection += '📱 Android: $playStoreUrl\n';
      }
      if (appStoreUrl != null && appStoreUrl.isNotEmpty) {
        downloadSection += '🍏 iPhone: $appStoreUrl\n';
      }

      String message = '''
Hey! 👋

I'm using **LingoBuzz** to learn new languages effortlessly — right from my home screen!

You should try it too 🌍
${downloadSection.isNotEmpty ? '\nDownload now:\n$downloadSection' : ''}

Happy learning! 🗣️  
— The LingoBuzz Team
''';

      // Modern share call using ShareParams
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Join me on LingoBuzz!',
          title: 'Invite a Friend',
        ),
      );

      // Optional feedback UI
      if (result.status == ShareResultStatus.success) {
        SnackBarUtils.showSuccessSnackbar('Thanks for sharing LingoBuzz 🎉');
      } else if (result.status == ShareResultStatus.dismissed) {
        SnackBarUtils.showErrorSnackbar('You didn’t send the invite.');
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackbar('Something went wrong: $e');
    }
  }



}
