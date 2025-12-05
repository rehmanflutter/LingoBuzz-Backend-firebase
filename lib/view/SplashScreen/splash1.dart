import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../controller/AuthController/auth_controller.dart';
import '../../controller/SettingController/topic_controller.dart';
import '../../controller/app_info_controller.dart';
import '../../controller/languages_controller/language_controller.dart';
import '../../controller/words_controller/word_controller.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/services/background_task_services.dart';
import '../Home/home_widget_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final controller = Get.put(AuthController());
  final languagesController = Get.put(LanguageController());
  final topicController = Get.put(TopicController());
  final wordController = Get.put(WordController());
  final AppInfoController appInfoController = Get.put(AppInfoController());
  final pageController = PageController();
  final box = GetStorage();


  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> initializeWidgetsOnAppStart() async {
    try {
      Log.debug('\n╔═══════════════════════════════════════════════════════════╗');
      Log.debug('║           INITIALIZING WIDGETS ON APP START               ║');
      Log.debug('╚═══════════════════════════════════════════════════════════╝');

      // 1. Initialize HomeWidgetService
      await HomeWidgetService.initialize();

      // 2. Check if setup is done
      final isSetupDone = box.read('isSetupDone') ?? false;

      if (!isSetupDone) {
        Log.debug('⚠️ Setup not done - widgets will show setup required');
        return;
      }

      // 3. Load and update widgets
      await HomeWidgetService.loadAndUpdateWidget();

      // 4. Initialize background services
      await BackgroundTaskService.initialize();

      Log.debug('╔═══════════════════════════════════════════════════════════╗');
      Log.debug('║           WIDGET INITIALIZATION COMPLETE                  ║');
      Log.debug('╚═══════════════════════════════════════════════════════════╝\n');

    } catch (e, st) {
      Log.debug('❌ Error initializing widgets on app start: $e\n$st');
    }
  }

  Future<void> _initializeApp() async {
     initializeWidgetsOnAppStart();
    await _generateAndSaveFcmToken();

    /// ✅ Delay for splash animation
    await Future.delayed(const Duration(seconds: 3));

    try {
      final isSetupDone = box.read("isSetupDone") ?? false;
      final showOnboarding = box.read("showOnBoarding") ?? true;

      Log.debug('🔍 [SplashScreen] Checking setup status...');
      Log.debug('   isSetupDone: $isSetupDone');
      Log.debug('   showOnboarding: $showOnboarding');

      if (showOnboarding) {
        Log.debug('🚀 First launch detected. Navigating to Onboarding...');
        Navigator.pushReplacementNamed(context, AppRoutes.splishScreen);
        return;
      }

      if (isSetupDone) {
        Log.debug('✅ Setup complete. Navigating to Home...');
        Navigator.pushReplacementNamed(context, AppRoutes.bottomAppBarScreen);
      } else {
        Log.debug('🚀 Setup not done. Navigating to Onboarding...');
        Navigator.pushReplacementNamed(context, AppRoutes.oboarding);
      }
    } catch (e, s) {
      Log.debug('❌ Error checking setup status: $e');
      Log.debug('StackTrace: $s');
      Navigator.pushReplacementNamed(context, AppRoutes.splishScreen);
    }
  }

  /// 🔹 Generate and Save FCM Token
  Future<void> _generateAndSaveFcmToken() async {
    try {
      // 🔹 Request permissions (especially for iOS)
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      Log.debug("🔔 Notification permission: ${settings.authorizationStatus}");

      // 🔹 iOS only: ensure APNs token is available
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          Log.err("⚠️ APNs token not available yet.");
          return;
        } else {
          Log.debug("📱 APNs token: $apnsToken");
        }
      }

      // 🔹 Get FCM token
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        box.write('fcm_token', token);
        Log.debug("✅ FCM Token saved: $token");
      } else {
        box.write('fcm_token', "");
        Log.err("⚠️ FCM token is null or empty");
      }

      // 🔹 Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        box.write('fcm_token', newToken);
        Log.debug("🔄 FCM token refreshed: $newToken");
      });
    } catch (e) {
      Log.err("❌ Failed to generate FCM token: $e");
      box.write('fcm_token', "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            1.h.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 30,
                  width: 30,
                  child: Image.asset(AppImages.buzzysplish),
                ),
                1.w.width,
                CustomTextWidget(
                  title: 'LingoBuzz',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            CustomTextWidget(
              title: 'The fun way to learn new Language',
            ),
          ],
        ),
      ),
    );
  }
}
