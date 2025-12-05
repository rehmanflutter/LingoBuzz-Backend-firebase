import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/controller/SettingController/setting_controller.dart';
import 'package:lingobuzz/controller/languages_controller/language_controller.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/core/common/widgets/custom_loading_indicator.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../controller/AuthController/auth_controller.dart';
import '../../core/common/bottomAppBar/bottom_app_bar.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/common/snackbar_utils.dart';
import '../../core/common/utils/date_time_utils.dart';
import '../../core/common/widgets/custamContainer.dart';
import '../../model/language_model.dart';

class Setting extends StatelessWidget {
  Setting({super.key});

  final SettingController controller = Get.put(SettingController());
  final AuthController authController = Get.find<AuthController>();
  final languageController = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          /// Fixed Header (Not Scrollable)
          _buildHeader(),
          Divider(color: AppColors.offGray),
          1.h.height,

          /// Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  children: [
                    /// Profile Section
                    _buildProfileSection(context),
                    2.h.height,

                    /// Learning Preferences
                    _buildLearningPreferences(),
                    2.h.height,

                    /// Topic Selection
                    _buildTopicSelection(context),
                    2.h.height,

                    /// Language Settings
                    _buildLanguageSettings(),
                    2.h.height,

                    /// Notifications
                    _buildNotifications(controller),
                    2.h.height,

                    /// Audio Settings
                    _buildAudioSettings(),
                    2.h.height,

                    /// App Preferences
                    // _buildAppPreferences(),
                    // 2.h.height,

                    /// Account Settings
                    _buildAccountSettings(context),
                    2.h.height,

                    /// Invite Friends
                    _buildInviteFriend(controller),

                    3.h.height,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Header
  Widget _buildHeader() {
    return Column(
      children: [
        6.h.height,
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CustomTextWidget(
              title: 'Settings',
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            CustomTextWidget(
              title: 'Customize your learning experience',
              fontSize: 9,
              color: const Color(0xff2C2521),
            ),
          ],
        ),
      ],
    );
  }

  /// Profile Section
  Widget _buildProfileSection(BuildContext context) {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.5.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:  [
                    CustomTextWidget(
                      title: ('${authController.currentUser.value?.firstName ?? ''} ${authController.currentUser.value?.lastName ?? ''}')
                          .trim(),
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: authController.currentUser.value?.email ?? '',
                      fontSize: 11,
                    ),
                  ],
                ),
                SizedBox(height: 4.h, child: Image.asset(AppImages.buzzyleft)),
              ],
            ),
            2.h.height,
            GestureDetector(
              onTap: () {
                  Navigator.pushNamed(context, AppRoutes.editProfileScreen);
              },
              child: CustomContainer(
                height: 6.h,
                cir: 40,
                width: double.infinity,
                col: const Color(0xffF7F6F6),
                child: const CustomTextWidget(
                  title: 'Edit Profile',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Learning Preferences
  Widget _buildLearningPreferences() {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.autoStorie),
                2.w.width,
                const CustomTextWidget(
                  title: 'Learning Preferences',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            2.h.height,

            /// Current Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Current Level',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'Your learning level',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(() {
                  final currentUser = authController.currentUser.value;

                  // Determine selected level:
                  final selectedLevel = currentUser?.currentLearning?.currentLevel ??
                      (authController.levelAssessmentList.isNotEmpty
                          ? authController.levelAssessmentList.first.name
                          : null);

                  return CustomContainer(
                    height: 5.5.h,
                    width: 25.w,
                    borders: true,
                    cir: 30,
                    col: AppColors.lightGray,
                    child: DropdownButtonHideUnderline(
                      child: IgnorePointer(
                        ignoring: authController.isLoading.value,
                        child: DropdownButton<String>(
                          value: selectedLevel,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: Colors.grey,
                          ),
                          dropdownColor: AppColors.white,
                          items: authController.levelAssessmentList.map((level) {
                            return DropdownMenuItem<String>(
                              value: level.name,
                              child:  authController.isLoading.value? CustomLoadingIndicator(color: AppColors.primaryColor,):
                              CustomTextWidget(
                                title: level.name,
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) async {
                            if (newValue == null) return;
                            try {
                              final success = await authController.updateUserData(
                                  currentLearning: currentUser?.currentLearning?.copyWith(
                                currentLevel: newValue,
                              ));
                              if (success) {
                                SnackBarUtils.showSuccessSnackbar('Level updated to $newValue successfully!');
                              } else {
                                SnackBarUtils.showErrorSnackbar('Failed to update level.');
                              }
                            } catch (e) {
                              SnackBarUtils.showErrorSnackbar('Error: $e');
                            }
                          },
                        ),
                      ),
                    ),
                  );
                })

              ],
            ),

            Divider(color: AppColors.lightGray),

            /// Daily Words Goal
            Obx(() {
              final currentUser = authController.currentUser.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomTextWidget(
                        title: 'Daily Words Goal',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomTextWidget(
                        title:
                        currentUser?.subscription==null?
                        '3 words per day (Free)':'${currentUser?.currentLearning?.wordsPerDay ?? 3} words per day',
                        fontSize: 9,
                        color: AppColors.gray,
                      ),

                    ],
                  ),
                  currentUser?.subscription != null && currentUser!.subscription!.isNotEmpty
                      ? Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final sub in currentUser.subscription!) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (sub.isActive ?? false)
                                  ? AppColors.green.withOpacity(0.1)
                                  : AppColors.gray.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (sub.isActive ?? false)
                                    ? AppColors.green
                                    : AppColors.gray,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextWidget(
                                  title: sub.planName ?? 'Unknown Plan',
                                  fontSize: 12,
                                  color: (sub.isActive ?? false)
                                      ? AppColors.green
                                      : AppColors.gray,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(height: 2),
                                CustomTextWidget(
                                  title:
                                  'From ${DateTimeUtils.formatDateToReadable(sub.startDate)} to ${DateTimeUtils.formatDateToReadable(sub.endDate)}',
                                  fontSize: 10,
                                  color: (sub.isActive ?? false)
                                      ? AppColors.primaryColor
                                      : AppColors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ):
                  GestureDetector(
                    onTap: () {
                      final navigationController = Get.find<BottomNavController>();
                      navigationController.selectedIndex.value=2;
                    },
                    child: CustomContainer(
                      height: 5.5.h,
                      width: 28.w,
                      borders: true,
                      cir: 30,
                      col: AppColors.lightGray,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(AppImages.pro, height: 1.8.h),
                          CustomTextWidget(
                            title: '  Upgrade',
                            fontSize: 12,
                            color: AppColors.gray,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            Divider(color: AppColors.lightGray),
            SizedBox(height: 3,),
            /// Daily Words Goal
            Obx(() {
              final currentUser = authController.currentUser.value;
              final isPremium = currentUser?.subscription != null &&
                  currentUser!.subscription!.isNotEmpty &&
                  (currentUser.subscription!.first.isActive ?? false);

              // ✅ Default values
              final int minWords = 1;
              final int maxWords = isPremium ? 10 : 3;
              final RxInt wordsPerDay = (currentUser?.currentLearning?.wordsPerDay ?? minWords).obs;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomTextWidget(
                        title: 'Words Per Day',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomTextWidget(
                        title: isPremium
                            ? 'Up to $maxWords words per day (Pro)'
                            : 'Up to $maxWords words per day (Free)',
                        fontSize: 9,
                        color: AppColors.gray,
                      ),
                    ],
                  ),

                  /// ✅ Counter UI (for all users)
                  CustomContainer(
                    height: 5.5.h,
                    width: 33.w,
                    borders: true,
                    cir: 30,
                    col: AppColors.lightGray.withOpacity(0.1),
                    child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Decrease Button
                        InkWell(
                          onTap: () async {
                            if (wordsPerDay.value > minWords) {
                              wordsPerDay.value--;
                              await authController.updateUserData(
                                currentLearning: currentUser?.currentLearning?.copyWith(
                                  wordsPerDay: wordsPerDay.value,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: Icon(Icons.remove, color: AppColors.gray),
                          ),
                        ),

                        /// Current Value
                        CustomTextWidget(
                          title: '${wordsPerDay.value}',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),

                        /// Increase Button
                        InkWell(
                          onTap: () async {
                            if (wordsPerDay.value < maxWords) {
                              wordsPerDay.value++;
                              await authController.updateUserData(
                                showLoading: false,
                                currentLearning: currentUser?.currentLearning?.copyWith(
                                  wordsPerDay: wordsPerDay.value,
                                ),
                              );
                            } else {
                              SnackBarUtils.showInfoSnackbar(
                                'You can select up to $maxWords words per day.',
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: Icon(Icons.add,color: AppColors.gray),
                          ),
                        ),
                      ],
                    )),
                  ),
                ],
              );
            }),

          ],
        ),
      ),
    );
  }

  /// Topic Selection
  Widget _buildTopicSelection(BuildContext context,) {
    return CustomContainer(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.topicSelection);
      },
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(AppImages.borderAll),
                    2.w.width,
                     Obx(()=> CustomTextWidget(
                        title: 'Topic Selection - Level ${authController.currentUser.value?.currentLearning?.currentLevel ?? ''}',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                                           ),
                     ),
                  ],
                ),
                1.h.height,
                CustomTextWidget(
                  title: 'Select specific learning topics',
                  fontSize: 9,
                  color: AppColors.gray,
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray),
          ],
        ),
      ),
    );
  }

  /// Language Settings
  Widget _buildLanguageSettings() {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.language),
                2.w.width,
                const CustomTextWidget(
                  title: 'Language Settings',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            2.h.height,
            /// Learning Language
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Learning Language',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'The language you\'re studying',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                // CustomTextWidget(title: authController.currentUser.value?.userLanguages?.nativeLanguage?.name ?? ''),
                // CustomTextWidget(title: authController.currentUser.value?.userLanguages?.learningLanguage?.name ?? ''),
                Obx(() {
                  final availableLanguages = languageController.languagesAvailable;
                  final selectedLang = LanguageModel(
                    id: authController.currentUser.value?.currentLearning?.id,
                    name: authController.currentUser.value?.currentLearning?.languageName,
                  );

                  final isSwitching = languageController.isSwitchingLanguage.value;

                  return CustomContainer(
                    height: 5.5.h,
                    boxConstraints: BoxConstraints(
                      minWidth: 28.w,
                      maxWidth: 40.w,
                    ),
                    borders: true,
                    cir: 30,
                    col: AppColors.lightGray,
                    child: DropdownButtonHideUnderline(
                      child: IgnorePointer(
                        ignoring: languageController.isLoading.value || isSwitching,
                        child: DropdownButton<LanguageModel>(
                          value: selectedLang,

                          // 🟢 Fix selected item UI text
                          selectedItemBuilder: (context) {
                            return availableLanguages.map((lang) {
                              final displayName = (lang.name == "Portuguese")
                                  ? "Portuguese (BR)"
                                  : lang.name ?? "";

                              return Center(
                                child: CustomTextWidget(
                                  title: displayName,
                                  fontSize: 12,
                                  color: AppColors.gray,
                                ),
                              );
                            }).toList();
                          },

                          icon: isSwitching
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          )
                              : const Icon(Icons.keyboard_arrow_down_sharp, color: Colors.grey),

                          dropdownColor: AppColors.white,

                          // 🟢 Fix dropdown list UI text
                          items: availableLanguages.map((language) {
                            final displayName = (language.name == "Portuguese")
                                ? "Portuguese (BR)"
                                : language.name ?? "";

                            return DropdownMenuItem<LanguageModel>(
                              value: language,
                              child: languageController.isLoading.value
                                  ? CustomLoadingIndicator(color: AppColors.primaryColor)
                                  : CustomTextWidget(
                                title: displayName,
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            );
                          }).toList(),

                          onChanged: (newLanguage) async {
                            if (newLanguage != null &&
                                newLanguage.name != selectedLang.name) {
                              try {
                                Log.debug("🔄 Starting language switch from ${selectedLang.name} to ${newLanguage.name}");

                                languageController.isSwitchingLanguage.value = true;

                                final currentUser = authController.currentUser.value;
                                final currentSubscription = currentUser?.subscription;
                                final isPremium = currentSubscription != null &&
                                    currentSubscription.isNotEmpty &&
                                    (currentSubscription.first.isActive ?? false);

                                final wordsPerDay = isPremium ? 10 : 3;

                                Log.debug("📊 Switching with:");
                                Log.debug("   - Is Premium: $isPremium");
                                Log.debug("   - Words per day: $wordsPerDay");

                                final success = await languageController.selectNewLearnLanguage(
                                  newLanguage,
                                  defaultLevel:
                                  currentUser?.currentLearning?.currentLevel ?? 'A1',
                                  defaultWordsPerDay: wordsPerDay,
                                );

                                if (success) {
                                  Log.debug("✅ Language switched in controller");

                                  try {
                                    final wordController = Get.find<WordController>();

                                    Log.debug("🔄 Calling word controller handleLanguageSwitch");
                                    await wordController.handleLanguageSwitch();

                                    Log.debug("✅ Word controller switch complete");
                                    Log.debug("   - Words loaded: ${wordController.wordsList.length}");

                                    SnackBarUtils.showSuccessSnackbar(
                                      "Switched to ${newLanguage.name}! ${wordController.wordsList.length} words loaded.",
                                    );
                                  } catch (e, st) {
                                    Log.debug("❌ Error in word controller: $e\n$st");
                                    SnackBarUtils.showErrorSnackbar(
                                      "Language switched but failed to load words. Please restart the app.",
                                    );
                                  }
                                } else {
                                  Log.debug("❌ Language switch failed in controller");
                                  SnackBarUtils.showErrorSnackbar(
                                    "Failed to switch language. Please try again.",
                                  );
                                }
                              } catch (e, st) {
                                Log.debug("❌ Error in language switch: $e\n$st");
                                SnackBarUtils.showErrorSnackbar(
                                  "An error occurred while switching language.",
                                );
                              } finally {
                                languageController.isSwitchingLanguage.value = false;
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  );
                })

              ],
            ),

            Divider(color: AppColors.lightGray),

            /// Interface Language
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Interface Language',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'App display language',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => IgnorePointer(
                    ignoring: true,
                    child: CustomContainer(
                      height: 5.5.h,
                      width: 28.w,
                      borders: true,
                      cir: 30,
                      col: AppColors.lightGray,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.interfaceLanguage.value,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: Colors.grey,
                          ),
                          dropdownColor: AppColors.white,
                          items: controller.interfaceLanguages.map((String lang) {
                            return DropdownMenuItem<String>(
                              value: lang,
                              child: CustomTextWidget(
                                title: lang,
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            controller.interfaceLanguage.value = newValue!;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications(SettingController controller) {
    final wordController = Get.find<WordController>();
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.notificationsUnread),

                2.w.width,
                const CustomTextWidget(
                  title: 'Notifications',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            2.h.height,

            /// Push Notifications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Push Notifications',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'Receive learning reminders',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => CupertinoSwitch(
                    value: controller.pushNotifications.value,
                    onChanged: (val) => controller.togglePushNotifications(),
                    activeColor: AppColors.primaryColor,
                    trackColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),

            Divider(color: AppColors.lightGray),

            /// Daily Reminders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Daily Reminders',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'Daily practice notifications',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => CupertinoSwitch(
                    value: controller.dailyReminders.value,
                    onChanged: (val) => controller.toggleDailyReminders(),
                    activeColor: AppColors.primaryColor,
                    trackColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
            1.h.height,

            /// Widget Updates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Widget Updates',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'Refresh vocabulary on home/lock screen',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => CupertinoSwitch(
                    value: controller.widgetUpdates.value,
                    onChanged: (val) => controller.toggleWidgetUpdates(),
                    activeColor: AppColors.primaryColor,
                    trackColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),

            2.h.height,

            /// Display Time Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Display Time',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(
                      // color: Colors.amber,
                      width: 45.w,
                      child: CustomTextWidget(
                        maxLines: 1,
                        title: 'When to display words on lock screen',
                        fontSize: 8,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
      Obx(() => CustomContainer(
          height: 5.h,
          width: 33.w,
          borders: true,
          cir: 30,
          col: AppColors.lightGray,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.displayTime.value,
              icon: Icon(
                Icons.keyboard_arrow_down_sharp,
                color: Colors.grey,
                size: 2.h,
              ),
              dropdownColor: AppColors.white,
              items: controller.displayTimes.map((String time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: CustomTextWidget(
                    title: time,
                    fontSize: 8,
                    color: AppColors.gray,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  await controller.setDisplayTime(newValue);
                }
              },
            ),
          ),
        ),
      )

      ],
            ),
          ],
        ),
      ),
    );
  }

  /// Audio Settings
  Widget _buildAudioSettings() {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.headphones),
                2.w.width,
                const CustomTextWidget(
                  title: 'Audio Settings',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            2.h.height,

            /// Sound Effects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Sound Effects',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'Play sounds during lessons',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => CupertinoSwitch(
                    value: controller.soundEffects.value,
                    onChanged: (val) => controller.toggleSoundEffects(),
                    activeColor: AppColors.primaryColor,
                  ),
                ),
              ],
            ),

            Divider(color: AppColors.lightGray),
            1.h.height,

            /// Volume Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomTextWidget(
                  title: 'Volume',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                Obx(
                  () => CustomTextWidget(
                    title: '${controller.volume.value.toInt()}%',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Obx(
              () => SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryColor,
                  inactiveTrackColor: AppColors.lightGray,
                  thumbColor: AppColors.primaryColor,
                  overlayColor: Colors.yellow.withOpacity(0.2),
                ),
                child: Slider(
                  padding: EdgeInsets.all(0),
                  value: controller.volume.value,
                  min: 0,
                  max: 100,
                  onChanged: (value) => controller.setVolume(value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// App Preferences
  Widget _buildAppPreferences() {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.clarify),
                2.w.width,
                const CustomTextWidget(
                  title: 'App Preferences',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            2.h.height,

            /// Theme
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Theme',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'App appearance',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => IgnorePointer(
                    ignoring: true,
                    child: CustomContainer(
                      height: 5.5.h,
                      width: 28.w,
                      borders: true,
                      cir: 30,
                      col: AppColors.lightGray,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.theme.value,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: Colors.grey,
                          ),
                          dropdownColor: AppColors.white,
                          items: controller.themes.map((String theme) {
                            return DropdownMenuItem<String>(
                              value: theme,
                              child: CustomTextWidget(
                                title: theme,
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            controller.theme.value = newValue!;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Divider(color: AppColors.lightGray),

            /// Lesson Difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomTextWidget(
                      title: 'Lesson Difficulty',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      title: 'Adjust challenge level',
                      fontSize: 9,
                      color: AppColors.gray,
                    ),
                  ],
                ),
                Obx(
                  () => IgnorePointer(
                    ignoring: true,
                    child: CustomContainer(
                      height: 5.5.h,
                      width: 28.w,
                      borders: true,
                      cir: 30,
                      col: AppColors.lightGray,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.difficulty.value,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_sharp,
                            color: Colors.grey,
                          ),
                          dropdownColor: AppColors.white,
                          items: controller.difficulties.map((String diff) {
                            return DropdownMenuItem<String>(
                              value: diff,
                              child: CustomTextWidget(
                                title: diff,
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            controller.difficulty.value = newValue!;
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Account Settings
  Widget _buildAccountSettings(BuildContext context) {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.accountCircle),
                2.w.width,
                const CustomTextWidget(
                  title: 'Account Settings',
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            2.h.height,

            /// Log out
            GestureDetector(
              onTap: () {
                authController.logout(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomTextWidget(title: 'Log out', fontSize: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xffA6A6A6),
                  ),
                ],
              ),
            ),
            // 2.h.height,
            //
            // /// Delete Account
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     const CustomTextWidget(title: 'Delete Account', fontSize: 12),
            //     Icon(
            //       Icons.arrow_forward_ios,
            //       size: 16,
            //       color: Color(0xffA6A6A6),
            //     ),
            //   ],
            // ),
            // 2.h.height,
            //
            // /// Contact Us
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     const CustomTextWidget(title: 'Contact Us', fontSize: 12),
            //     Icon(
            //       Icons.arrow_forward_ios,
            //       size: 16,
            //       color: Color(0xffA6A6A6),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  ///. incite
  ///
  ///

  Widget _buildInviteFriend(SettingController controller) {
    return CustomContainer(
      width: double.infinity,
      borders: true,
      cir: 10,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomTextWidget(
                title: 'Invite a Friend',
                fontWeight: FontWeight.w600,
              ),
              1.h.height,
              CustomTextWidget(
                title:
                    'Can you think of a friend that should be learning a new language. Invite them to LingoBuzz to help them grow',
                color: AppColors.gray,
                fontSize: 9,
              ),
              2.h.height,
              InkWell(
                onTap: (){
                  controller.inviteFriend();
                },
                child: CustomContainer(
                  height: 4.5.h,
                  width: 40.w,
                  cir: 30,
                  col: AppColors.primaryColor,
                  child: CustomTextWidget(title: 'Invite Friends'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
