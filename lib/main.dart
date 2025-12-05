import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_themes.dart';
import 'package:lingobuzz/core/services/app_services.dart';
import 'package:lingobuzz/core/services/background_task_services.dart';
import 'package:lingobuzz/view/Home/home_widget_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'core/common/app_keys.dart';
import 'core/common/stripe_keys.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handle background Firebase messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.data}');
  if (message.data.isNotEmpty) {
    final title = message.data['title'] ?? 'LingoBuzz';
    final body = message.data['body'] ?? 'You have a new notification';
    await showLocalNotification(title, body);
  }
}

/// Initialize Firebase Messaging + Local Notifications
Future<void> setupFirebaseMessaging() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iOSInit,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  if (Platform.isAndroid) {
    const channel = AndroidNotificationChannel(
      'lingobuzz_channel',
      'LingoBuzz Notifications',
      description: 'Notifications for LingoBuzz app.',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        'notification',
      ), // Custom sound
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        notification.title ?? 'LingoBuzz',
        notification.body ?? 'You have a new message',
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📲 Notification tapped: ${message.data}');
  });

  debugPrint('✅ Firebase Messaging setup complete');
}

/// Show local notification with custom sound
Future<void> showLocalNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'lingobuzz_channel',
    'LingoBuzz Notifications',
    channelDescription: 'LingoBuzz app notifications',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF4CAF50),
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'), // Custom sound
  );

  const iOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'notification.wav', // Custom sound for iOS
  );

  const details = NotificationDetails(android: androidDetails, iOS: iOSDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
  );
}

Future<void> main() async {
  // CRITICAL: Initialize bindings FIRST, before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Then initialize storage
  await GetStorage.init();

  // Firebase initialization - Use defaultFirebaseOptions or simple initialization
  // This will automatically use GoogleService-Info.plist on iOS
  Platform.isIOS
      ? await Firebase.initializeApp()
      : await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: "AIzaSyBRpsYu3wjSWsJydzil_5dSZy2hjA_lw68",
            authDomain: "lingo-buzz.firebaseapp.com",
            projectId: "lingo-buzz",
            storageBucket: "lingo-buzz.firebasestorage.app",
            messagingSenderId: "877566608307",
            appId: "1:877566608307:web:22ad047810b6140fdec1c6",
            measurementId: "G-7QJESYLBZ6",
          ),
        );

  // Initialize services BEFORE running app
  await _initializeServices();

  // Run app in the SAME zone where bindings were initialized
  runApp(const MyApp());
}

/// Initialize all services
Future<void> _initializeServices() async {
  try {
    Stripe.publishableKey = StripeConfig.publishableKey;
    Stripe.merchantIdentifier =
        StripeConfig.merchantDisplayName; // For Apple Pay
    await Stripe.instance.applySettings();
    debugPrint('🚀 Initializing services...');

    // Setup Firebase Messaging
    await setupFirebaseMessaging();
    debugPrint('✅ Firebase Messaging initialized');

    // Initialize Home Widget Service
    await HomeWidgetService.initialize();
    debugPrint('✅ Home Widget Service initialized');

    // Initialize TTS
    await AppServices.initializeTTS();
    debugPrint('✅ TTS initialized');

    // Initialize and start background tasks
    await BackgroundTaskService.initialize();
    await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

    debugPrint('✅ Background Task Service initialized');

    // Schedule immediate update to ensure widget shows current word
    await BackgroundTaskService.scheduleImmediateUpdate();
    debugPrint('✅ Immediate update scheduled');

    debugPrint('🎉 All services initialized successfully');
  } catch (e, stack) {
    debugPrint('🔥 Service initialization failed: $e');
    debugPrintStack(stackTrace: stack);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 ========== MyApp.build() CALLED ==========');

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        debugPrint('🎨 ResponsiveSizer builder called');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LingoBuzz',
          theme: AppThemes.lightTheme,
          scaffoldMessengerKey: scaffoldMessengerKey,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.splashPage,
        );
      },
    );
  }
}
