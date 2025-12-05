// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import '../../../controller/AuthController/auth_controller.dart';
// import '../../../controller/SettingController/topic_controller.dart';
// import '../../../controller/words_controller/word_controller.dart';
// import 'app_logger.dart';
//
// /// ✅ Centralized Login Flow Handler
// /// This class handles the complete login flow with proper sequencing
// class LoginFlowHelper {
//   static final _storage = GetStorage();
//
//   /// ✅ Execute complete login flow
//   static Future<Map<String, dynamic>> executeLoginFlow({
//     required String email,
//     required String password,
//   }) async {
//     Log.debug("🚀 Starting complete login flow...");
//
//     try {
//       // Get controllers
//       final authController = Get.find<AuthController>();
//       final topicController = Get.find<TopicController>();
//       final wordController = Get.find<WordController>();
//
//       // Step 1: Authenticate user
//       Log.debug("🔐 Step 1: Authenticating user...");
//       final loginSuccess = await authController.login();
//
//       if (!loginSuccess) {
//         Log.debug("❌ Login failed at authentication step");
//         return {
//           'success': false,
//           'message': 'Authentication failed',
//           'needsSetup': false,
//         };
//       }
//
//       // Step 2: Verify user data loaded
//       Log.debug("👤 Step 2: Verifying user data...");
//       if (authController.currentUser.value == null) {
//         Log.debug("❌ User data not loaded");
//         return {
//           'success': false,
//           'message': 'Failed to load user data',
//           'needsSetup': false,
//         };
//       }
//
//       // Step 3: Check if setup is complete
//       Log.debug("🔍 Step 3: Checking setup status...");
//       final isSetupDone = _storage.read('isSetupDone') ?? false;
//
//       if (!isSetupDone) {
//         Log.debug("⚠️ Setup not complete - redirecting to setup");
//         return {
//           'success': true,
//           'message': 'Please complete your setup',
//           'needsSetup': true,
//         };
//       }
//
//       // Step 4: Sync TopicController with Firestore
//       Log.debug("📚 Step 4: Syncing topics from Firestore...");
//       await topicController.refreshTopicsFromFirestore();
//
//       // Verify topics are loaded
//       if (topicController.selectedTopics.isEmpty) {
//         Log.debug("⚠️ No topics found - may need category setup");
//         return {
//           'success': true,
//           'message': 'Please select your learning categories',
//           'needsSetup': true,
//         };
//       }
//
//       // Step 5: Initialize WordController
//       Log.debug("📖 Step 5: Initializing WordController...");
//       await wordController.initializeAndFetchWords();
//
//       // Step 6: Verify words are fetched
//       if (wordController.hasError.value) {
//         Log.debug("⚠️ Error fetching words: ${wordController.errorMessage.value}");
//         return {
//           'success': true,
//           'message': 'Logged in but failed to load words',
//           'needsSetup': false,
//           'warning': wordController.errorMessage.value,
//         };
//       }
//
//       Log.debug("✅ Login flow completed successfully!");
//       Log.debug("   - User: ${authController.currentUser.value?.email}");
//       Log.debug("   - Language: ${authController.currentUser.value?.currentLearning?.languageName}");
//       Log.debug("   - Level: ${authController.currentUser.value?.currentLearning?.currentLevel}");
//       Log.debug("   - Topics: ${topicController.selectedTopics.length}");
//       Log.debug("   - Words loaded: ${wordController.wordsList.length}");
//
//       return {
//         'success': true,
//         'message': 'Login successful',
//         'needsSetup': false,
//       };
//
//     } catch (e, st) {
//       Log.debug("❌ Error in login flow: $e\n$st");
//       return {
//         'success': false,
//         'message': 'An error occurred during login: ${e.toString()}',
//         'needsSetup': false,
//       };
//     }
//   }
//
//   /// ✅ Execute post-setup flow (after onboarding)
//   static Future<Map<String, dynamic>> executePostSetupFlow() async {
//     Log.debug("🚀 Starting post-setup flow...");
//
//     try {
//       // Get controllers
//       final authController = Get.find<AuthController>();
//       final topicController = Get.find<TopicController>();
//       final wordController = Get.find<WordController>();
//
//       // Step 1: Verify user data
//       Log.debug("👤 Step 1: Verifying user data...");
//       if (authController.currentUser.value == null) {
//         return {
//           'success': false,
//           'message': 'User data not found',
//         };
//       }
//
//       // Step 2: Verify topics are confirmed
//       Log.debug("📚 Step 2: Verifying topics...");
//       if (topicController.needsCategorySelection()) {
//         return {
//           'success': false,
//           'message': 'Please select your learning categories',
//         };
//       }
//
//       // Step 3: Mark setup as done
//       Log.debug("✅ Step 3: Marking setup as complete...");
//       _storage.write('isSetupDone', true);
//
//       // Step 4: Initialize and fetch words
//       Log.debug("📖 Step 4: Initializing WordController...");
//       await wordController.initializeAndFetchWords();
//
//       if (wordController.hasError.value) {
//         Log.debug("⚠️ Warning: ${wordController.errorMessage.value}");
//       }
//
//       Log.debug("✅ Post-setup flow completed!");
//       return {
//         'success': true,
//         'message': 'Setup completed successfully',
//       };
//
//     } catch (e, st) {
//       Log.debug("❌ Error in post-setup flow: $e\n$st");
//       return {
//         'success': false,
//         'message': 'An error occurred: ${e.toString()}',
//       };
//     }
//   }
//
//   /// ✅ Refresh user data and words (for pull-to-refresh)
//   static Future<void> refreshUserData() async {
//     Log.debug("🔄 Refreshing user data...");
//
//     try {
//       final authController = Get.find<AuthController>();
//       final topicController = Get.find<TopicController>();
//       final wordController = Get.find<WordController>();
//
//       // Refresh from Firestore
//       await authController.getUser();
//       await topicController.refreshTopicsFromFirestore();
//
//       // Rebuild path and refresh words
//       wordController.buildQueryPath();
//       await wordController.refreshWords();
//
//       Log.debug("✅ User data refreshed successfully");
//     } catch (e, st) {
//       Log.debug("❌ Error refreshing user data: $e\n$st");
//     }
//   }
//
//   /// ✅ Validate complete user setup
//   static bool isUserSetupComplete() {
//     try {
//       final authController = Get.find<AuthController>();
//       final topicController = Get.find<TopicController>();
//
//       final isSetupDone = _storage.read('isSetupDone') ?? false;
//       final hasUser = authController.currentUser.value != null;
//       final hasLearning = authController.currentUser.value?.currentLearning != null;
//       final hasTopics = !topicController.needsCategorySelection();
//
//       Log.debug("Setup validation:");
//       Log.debug("   - Setup done flag: $isSetupDone");
//       Log.debug("   - Has user: $hasUser");
//       Log.debug("   - Has learning: $hasLearning");
//       Log.debug("   - Has topics: $hasTopics");
//
//       return isSetupDone && hasUser && hasLearning && hasTopics;
//     } catch (e) {
//       Log.debug("⚠️ Error validating setup: $e");
//       return false;
//     }
//   }
//
//   /// ✅ Get setup status details
//   static Map<String, dynamic> getSetupStatus() {
//     try {
//       final authController = Get.find<AuthController>();
//       final topicController = Get.find<TopicController>();
//
//       final isSetupDone = _storage.read('isSetupDone') ?? false;
//       final user = authController.currentUser.value;
//
//       return {
//         'isSetupDone': isSetupDone,
//         'hasUser': user != null,
//         'hasEmail': user?.email != null,
//         'hasLearning': user?.currentLearning != null,
//         'hasLanguage': user?.currentLearning?.languageName != null,
//         'hasLevel': user?.currentLearning?.currentLevel != null,
//         'hasTopics': !topicController.needsCategorySelection(),
//         'topicsCount': topicController.selectedTopics.length,
//         'needsCategorySelection': topicController.needsCategorySelection(),
//       };
//     } catch (e) {
//       Log.debug("⚠️ Error getting setup status: $e");
//       return {
//         'isSetupDone': false,
//         'hasUser': false,
//         'error': e.toString(),
//       };
//     }
//   }
// }