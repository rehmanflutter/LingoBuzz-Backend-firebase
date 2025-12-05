import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/controller/SettingController/topic_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/common/widgets/custamContainer.dart';

class TopicSelection extends StatelessWidget {
  TopicSelection({super.key});

  final TopicController controller = Get.find<TopicController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final currentLearning = authController.currentUser.value?.currentLearning;
    final currentLevel = currentLearning?.currentLevel;

    // ✅ Extract selected topics from user data
    final filteredProgress = currentLearning?.levelProgress
        ?.where((progress) => progress.levelName == currentLevel)
        .toList() ??
        [];

    final selectedCategoryNames = filteredProgress
        .expand((progress) => progress.selectedCategories)
        .map((cat) => cat.categoryName)
        .toList();

    // ✅ Initialize controller selectedTopics once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setSelectedTopics(selectedCategoryNames);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                2.h.height,
                CustomContainer(
                  width: double.infinity,
                  borders: true,
                  cir: 10,
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(AppImages.autoStorie),
                            2.w.width,
                            const CustomTextWidget(
                              title: 'Choose topics you want to learn',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        2.h.height,

                        /// ✅ Dynamic topic list (Reactive)
                        Obx(
                              () => Column(
                            children: controller.allTopics.map((topic) {
                              final isSelected =
                              controller.selectedTopics.contains(topic);

                              return _buildTopicItem(
                                topic,
                                isSelected,
                                    () => controller.toggleTopic(topic),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                3.h.height,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            children: [
              7.h.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CustomContainer(
                      height: 40,
                      width: 40,
                      cir: 30,
                      col: const Color(0xffFAFAFA),
                      child: Icon(Icons.arrow_back, color: AppColors.black),
                    ),
                  ),
                  Column(
                    children: [
                      CustomTextWidget(
                        title: 'Topic Selection',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      CustomTextWidget(
                        title: 'Choose topics you want to learn',
                        fontSize: 9,
                        color: const Color(0xff2C2521),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ],
          ),
        ),
        Divider(color: AppColors.offGray),
        1.h.height,
      ],
    );
  }

  /// Topic Item
  Widget _buildTopicItem(String title, bool isSelected, VoidCallback onToggle) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomTextWidget(
              title: title,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(
                value: isSelected,
                activeColor: AppColors.primaryColor,
                trackColor: const Color(0xffE5E5E5),
                thumbColor: Colors.white,
                onChanged: (_) => onToggle(),
              ),
            ),
          ],
        ),
        Divider(height: 6, color: AppColors.lightGray),
      ],
    );
  }
}
