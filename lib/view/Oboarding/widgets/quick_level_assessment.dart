import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/view/Oboarding/widgets/oboarding_container.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../core/common/widgets/custamContainer.dart';

class QuickLevelAssessment extends StatelessWidget {
  QuickLevelAssessment({super.key});

  final controller = Get.put(AuthController());
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OboardingContainer(
          width: 75.w,
          title: 'Let’s assess your current level',
        ),
        Center(
          child: CustomTextWidget(
            title: 'Quick Level Assessment',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        2.h.height,

        Expanded(
          child: ListView.builder(
            // physics: NeverScrollableScrollPhysics(),
            itemCount: controller.levelAssessmentList.length,
            padding: EdgeInsets.all(0),
            itemBuilder: (context, index) {
              return Obx(
                () => CustomContainer(
                  onTap: () {
                     controller.selectedAssessmentLevel.value = index;
                  },
                  cir: 8,
                  margin: EdgeInsets.only(bottom: 1.5.h),
                  width: double.infinity,
                  height: 7.h,
                  borders: true,
                  borderWidth: controller.selectedAssessmentLevel.value == index ? 2.5 : 1,
                  col: controller.selectedAssessmentLevel.value == index
                      ? AppColors.offprimary
                      : AppColors.offWhite,
                  borderCol: controller.selectedAssessmentLevel.value == index
                      ? AppColors.primaryColor
                      : AppColors.offGray,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextWidget(
                            title: controller.levelAssessmentList[index].title,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          CustomTextWidget(
                            title: controller
                                .levelAssessmentList[index]
                                .description,
                            color: AppColors.gray,
                            fontSize: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
