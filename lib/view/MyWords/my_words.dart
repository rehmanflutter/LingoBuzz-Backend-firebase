import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/MyWordsController/my_words_cpontroller.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/view/MyWords/widgets/all_seen.dart';
import 'package:lingobuzz/view/MyWords/widgets/save_words.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/common/widgets/custamContainer.dart';

class MyWords extends StatelessWidget {
  MyWords({super.key});
  final controller = Get.put(MyWordsCpontroller());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                7.h.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomTextWidget(
                          title: 'Words',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        CustomTextWidget(
                          title: 'Track your vocabulary progress',
                          fontSize: 9,
                          color: Color(0xff2C2521),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.offGray),
          1.h.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: CustomContainer(
              onTap: () {
                controller.saveWords.value = true;
              },
              width: double.infinity,
              height: 6.h,
              col: AppColors.offprimary,
              cir: 10,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Obx(
                      () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomContainer(
                        width: 41.w,
                        height: 5.h,
                        cir: 13,
                        col: controller.saveWords.value
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        child: CustomTextWidget(
                          title: 'Saved',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CustomContainer(
                        onTap: () {
                          controller.saveWords.value = false;
                        },
                        width: 41.w,
                        height: 4.9.h,
                        cir: 13,
                        col: controller.saveWords.value == false
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        child: CustomTextWidget(
                          title: 'Seen',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Obx(
                      () => controller.saveWords.value == true
                          ? SaveWords()
                          : AllWordsSeen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
