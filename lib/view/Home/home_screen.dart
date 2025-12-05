import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/controller/UpgradeProController/upgrade_pro_controller.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/widgets/custom_image_widget.dart';
import 'package:lingobuzz/view/Home/widgets/setup_widget.dart';
import 'package:lingobuzz/view/Home/widgets/take_quiz_widget.dart';
import 'package:lingobuzz/view/Home/widgets/today_words_sentences.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/common/helpers/battery_optimization_helper.dart';
import '../../core/common/helpers/home_widget_helper.dart';
import '../../core/services/push_notifications_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, WidgetSetupLifecycleHandler {
  final AuthController authController = Get.find<AuthController>();
  final WordController wordController = Get.find<WordController>();
  final UpgradeProController upgrade = Get.put(UpgradeProController());
  final storage = GetStorage();

  @override
   initState()  {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatteryOptimizationHelper.checkAndRequest(context);
      WidgetSetupHelper.showWidgetSetupPromptIfNeeded(context);
    });
    _generateAndSaveFcmToken();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

     wordController.refreshDailyProgress();

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
        storage.write('fcm_token', token);
        Log.debug("✅ FCM Token saved: $token");
      } else {
        storage.write('fcm_token', "");
        Log.err("⚠️ FCM token is null or empty");
      }

      // 🔹 Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        storage.write('fcm_token', newToken);
        Log.debug("🔄 FCM token refreshed: $newToken");
      });
    } catch (e) {
      Log.err("❌ Failed to generate FCM token: $e");
      storage.write('fcm_token', "");
    }
    Log.debug("New Fcm Token : ${storage.read('fcm_token')}");
    authController.updateUserData(
        fcmToken: storage.read('fcm_token'),
      showLoading: false
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = authController.currentUser.value;
    //
    // PushNotificationService.sendPushNotification(
    //   'LingoBuzz',
    //   "Testing push notification",
    // );
    // upgrade.upgradeToPremium([], isFirstTimeUpgrade: true);

    //await authController.upgradeToPremium();

    // await EmailHelper().sendWelcomeEmail(
    //   email: 'ahmadasghar.appdev@gmail.com',
    //   firstName: 'Ahmed',
    // );
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        elevation: 6,
        onPressed: () {


          WidgetSetupHelper.openWidgetSettings(context);
        },
        label: Row(
          children: [
            Text(
              'Setup Widgets',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.now_widgets_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            6.h.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomTextWidget(
                        title: 'Hello there! 👋',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomTextWidget(
                        title:
                            "You're doing great with your ${currentUser?.currentLearning?.languageName ?? ""} learning journey.",
                        fontSize: 9,
                        color: AppColors.gray,
                      ),
                    ],
                  ),
                ),
                AvatarImage(
                  radius: 22,
                  imageUrl: currentUser?.image ?? "",
                  name:
                      "${currentUser?.firstName ?? ""} ${currentUser?.lastName ?? ""}",
                ),
              ],
            ),
            3.h.height,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TodayWordsSentences(),
                    2.h.height,
                    TakeQuizWidget(),
                    10.h.height
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
