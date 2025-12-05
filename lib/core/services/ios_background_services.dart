// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:background_fetch/background_fetch.dart';
//
// import 'background_task_services.dart';
//
// /// 🍎 iOS Background Fetch Configuration
// class IOSBackgroundService {
//   /// ✅ Initialize iOS Background Fetch
//   static Future<void> initialize() async {
//     if (!Platform.isIOS) return;
//
//     // Configure BackgroundFetch
//     int status = await BackgroundFetch.configure(
//       BackgroundFetchConfig(
//         minimumFetchInterval: 15, // Minimum 15 minutes
//         stopOnTerminate: false,
//         enableHeadless: true,
//         startOnBoot: true,
//         requiresBatteryNotLow: false,
//         requiresCharging: false,
//         requiresStorageNotLow: false,
//         requiresDeviceIdle: false,
//         requiredNetworkType: NetworkType.ANY,
//       ),
//       _onBackgroundFetch,
//       _onBackgroundFetchTimeout,
//     );
//
//     debugPrint('🍎 iOS Background Fetch status: $status');
//
//     // Register headless task
//     BackgroundFetch.registerHeadlessTask(_backgroundFetchHeadlessTask);
//   }
//
//   /// 📱 Background fetch callback when app is running
//   static Future<void> _onBackgroundFetch(String taskId) async {
//     debugPrint('🔄 [iOS] Background fetch started: $taskId');
//
//     try {
//       await BackgroundTaskService.checkAndUpdateWords();
//       BackgroundFetch.finish(taskId);
//       debugPrint('✅ [iOS] Background fetch completed');
//     } catch (e) {
//       debugPrint('❌ [iOS] Background fetch error: $e');
//       BackgroundFetch.finish(taskId);
//     }
//   }
//
//   /// ⏱️ Timeout callback
//   static void _onBackgroundFetchTimeout(String taskId) {
//     debugPrint('⏱️ [iOS] Background fetch timeout: $taskId');
//     BackgroundFetch.finish(taskId);
//   }
// }
//
// /// 🎯 Headless task (runs when app is terminated)
// @pragma('vm:entry-point')
// void _backgroundFetchHeadlessTask(HeadlessTask task) async {
//   final taskId = task.taskId;
//   final timeout = task.timeout;
//
//   if (timeout) {
//     debugPrint('⏱️ [iOS Headless] Task timeout: $taskId');
//     BackgroundFetch.finish(taskId);
//     return;
//   }
//
//   debugPrint('🔄 [iOS Headless] Task started: $taskId');
//
//   try {
//     await BackgroundTaskService.checkAndUpdateWords();
//     BackgroundFetch.finish(taskId);
//     debugPrint('✅ [iOS Headless] Task completed');
//   } catch (e) {
//     debugPrint('❌ [iOS Headless] Task error: $e');
//     BackgroundFetch.finish(taskId);
//   }
// }