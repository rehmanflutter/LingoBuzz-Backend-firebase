import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/helpers/email_helper.dart';
import 'package:lingobuzz/core/common/snackbar_utils.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/view/Oboarding/Auth/create_your_account.dart';
import 'package:lingobuzz/view/Oboarding/Auth/select_languages.dart';
import 'package:lingobuzz/view/Oboarding/widgets/learning_preferences.dart';
import 'package:lingobuzz/view/Oboarding/widgets/quick_level_assessment.dart';
import 'package:lingobuzz/view/Oboarding/widgets/welcome_lingo_buzz.dart';
import 'package:lingobuzz/view/Oboarding/widgets/youre_all_set.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../controller/SettingController/topic_controller.dart';
import '../../controller/languages_controller/language_controller.dart';
import '../../controller/words_controller/word_controller.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/common/widgets/custom_Button.dart';
import '../../core/common/widgets/progressIndicator.dart';
import '../../model/user_model.dart';

class Oboarding extends StatefulWidget {
  Oboarding({super.key});

  @override
  State<Oboarding> createState() => _OboardingState();
}

class _OboardingState extends State<Oboarding> {
  final controller = Get.find<AuthController>();
  final languagesController = Get.find<LanguageController>();
  final pageController = PageController();
  final box = GetStorage();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = controller.currentUser.value;
      int nextPage = 0;

      // ✅ Page routing logic based on new UserModel structure
      if (user?.uid == null || user?.email == null || user!.email!.isEmpty) {
        // No account created
        nextPage = 1;
      } else if (user.nativeLanguage == null || user.currentLearning == null) {
        // Account exists but languages not set
        nextPage = 2;
      } else if (user.currentLearning?.currentLevel == null ||
          user.currentLearning!.currentLevel!.isEmpty) {
        // Languages set but level assessment not done
        nextPage = 3;
      } else if (user.currentLearning?.wordsPerDay == null ||
          user.currentLearning?.contentType == null) {
        // Level set but preferences not configured
        nextPage = 4;
      } else {
        // Everything is complete
        nextPage = 5;
      }

      if (nextPage < 5) {
        pageController.jumpToPage(nextPage);
        controller.progressValue.value = (nextPage * 0.2).clamp(0.0, 1.0);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.bottomAppBarScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Column(
                children: [
                  7.h.height,
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (pageController.page == 0) {
                            Navigator.pop(context);
                          } else {
                            controller.progressValue.value =
                                (controller.progressValue.value - 0.2)
                                    .clamp(0.0, 1.0);
                            pageController.previousPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: const Icon(Icons.clear_outlined),
                      ),
                      3.w.width,
                      Expanded(
                        child: Obx(
                              () => CustomProgressIndicator(
                            totalSteps: 5,
                            progress: controller.progressValue.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 77.h,
              child: PageView.builder(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: index == 0
                        ? const WelcomeLingoBuzz()
                        : index == 1
                        ? CreateYourAccount()
                        : index == 2
                        ? SelectLanguages()
                        : index == 3
                        ? QuickLevelAssessment()
                        : index == 4
                        ? LearningPreferences()
                        : const YoureAllSet(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => MainCustomButton(
                loading: controller.isLoading.value,
                title: 'Continue',
                onTap: () async {

                  final currentPage = pageController.page?.round() ?? 0;

                  // ✅ Page 1 - Account creation or login
                  if (currentPage == 1) {
                    if (controller.isLoading.value) {
                      Log.debug('⚠️ Ignored tap — already processing');
                      return;
                    }

                    controller.isLoading.value = true;
                    Log.debug('🟢 Continue pressed on Page 1');
                    Log.debug('   - isLogin: ${controller.isLogin.value}');

                    bool response = false;

                    try {
                      if (controller.isLogin.value) {
                        // 🔐 LOGIN FLOW
                        Log.debug('🔐 Attempting login...');
                        response = await controller.login();
                        Log.debug('🔓 Login response: $response');

                        if (!response) {
                          Log.debug('❌ Login failed, stopping flow');
                          return;
                        }

                        Log.debug('🏠 Navigating to Home');
                        Navigator.pushReplacementNamed(context, AppRoutes.bottomAppBarScreen);
                        return;

                      } else {
                        // 🆕 CREATE ACCOUNT FLOW
                        Log.debug('🆕 Attempting account creation...');
                        response = await controller.createAccount();
                        Log.debug('✅ Account creation response: $response');

                        if (!response) {
                          Log.debug('❌ Account creation failed, stopping flow');
                          return;
                        }

                        Log.debug('✅ Account created successfully — moving to next onboarding page...');
                        await pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                        return;
                      }
                    } catch (e, s) {
                      Log.debug('🔥 Unexpected error during login/signup: $e');
                      Log.debug('$s');
                      return;
                    } finally {
                      controller.isLoading.value = false;
                      Log.debug('⏹️ Loading reset');
                    }
                  }

                  // ✅ Page 2 - Save languages (native + learning)
                  if (currentPage == 2) {
                    if (languagesController.nativeLanguage.value == null ||
                        languagesController.learnLanguage.value == null) {
                      SnackBarUtils.showErrorSnackbar(
                          "Please select both languages");
                      return;
                    }

                    // Create initial LearningLanguageModel with default values
                    final learningLanguage = LearningLanguageModel(
                      id: languagesController.learnLanguage.value!.id,
                      languageName: languagesController.learnLanguage.value!.name,
                      type: 'learning',
                      startedAt: DateTime.now(),
                    );

                    final response = await controller.updateUserData(
                      nativeLanguage: languagesController.nativeLanguage.value!,
                      currentLearning: learningLanguage,
                    );

                    if (!response) return;
                  }

                  // ✅ Page 3 - Level assessment
                  if (currentPage == 3) {
                    if (controller.selectedAssessmentLevel.value == 5) {
                      SnackBarUtils.showErrorSnackbar("Please select an assessment level");
                      return;
                    }

                    final selectedLevel = controller
                        .levelAssessmentList[controller.selectedAssessmentLevel.value]
                        .name;

                    // Update the currentLearning with selected level
                    final user = controller.currentUser.value;
                    if (user?.currentLearning != null) {
                      // final updatedLearning = user!.currentLearning!.copyWith(
                      //   currentLevel: selectedLevel,
                      // );
                   //  Log.debug("Learning model before update: ${user.currentLearning!.toMap()}");
                      final response = await controller.updateUserData(
                        currentLearning: LearningLanguageModel(
                          currentLevel: selectedLevel,
                          id: languagesController.learnLanguage.value!.id,
                          languageName: languagesController.learnLanguage.value!.name,
                          type: 'learning',
                          startedAt: DateTime.now(),
                        ),
                      );

                      if (!response) return;
                    }
                  }

                  // ✅ Page 4 - Learning preferences
                  if (currentPage == 4) {
                    final topicController = Get.find<TopicController>();
                    Log.debug('🟢 Saving learning preferences... page 4');
                    final wordsPerDay = controller.wordsPerDaySelect.value + 1;

                    // Update the currentLearning with preferences
                    final user = controller.currentUser.value;
                    if (user?.currentLearning != null) {
                      final updatedLearning = user!.currentLearning!.copyWith(
                        wordsPerDay: wordsPerDay,
                        contentType: 3,
                      );

                      final response = await controller.updateUserData(
                        currentLearning: updatedLearning,
                      );
                      await topicController.setInitialTopic();
                      final wordController = Get.find<WordController>();
                      box.write("isSetupDone", true);
                      wordController.fetchWordList();
                      EmailHelper().sendWelcomeEmail(
                        email: controller.currentUser.value?.email??"",
                        firstName: controller.currentUser.value?.firstName??"",
                      );
                      if (!response) return;
                    }
                  }

                  // ✅ Update progress
                  if (controller.progressValue.value < 1.0) {
                    controller.progressValue.value =
                        (controller.progressValue.value + 0.2).clamp(0.0, 1.0);
                  }

                  // ✅ Next page or navigate to Home
                  if (currentPage >= 5) {
                    Navigator.pushNamed(context, AppRoutes.bottomAppBarScreen);
                  } else {
                    await pageController.nextPage(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              ),
            ),
            5.h.height,
          ],
        ),
      ),
    );
  }
}