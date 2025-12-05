import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/instance_manager.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/view/Oboarding/widgets/oboarding_container.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/common/widgets/custamContainer.dart';

class LearningPreferences extends StatelessWidget {
  LearningPreferences({super.key});
  final controller = Get.put(AuthController());
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OboardingContainer(width: 70.w, title: 'Almost done!'),
          Center(
            child: CustomTextWidget(
              title: 'Learning Preferences',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          3.h.height,
          CustomTextWidget(
            title: 'How many words or phrases per day? (Free plan)',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          1.h.height,
          CustomContainer(
            width: double.infinity,
            col: AppColors.white,
            borders: true,
            cir: 10,
            borderWidth: 0.8,
            shadow: true,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.all(0),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    child: Obx(
                      () => GestureDetector(
                        onTap: () {
                          controller.wordsPerDaySelect.value = index;
                        },
                        child: Container(
                          width: double.infinity,
                          color: Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                height: 17,
                                controller.wordsPerDaySelect.value == index
                                    ? AppImages.checkBox
                                    : AppImages.clucal,
                              ),
                              2.w.width,
                              CustomTextWidget(
                                title: controller.wordsPerDay[index],
                                color: AppColors.gray,
                                fontSize: 15,
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
          ),
        ],
      ),
    );
  }
}
