import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../bottomAppBar/bottom_app_bar.dart';
import '../widgets/custamContainer.dart';
import '../widgets/custom_Button.dart';

class AllBottomSheets {
  static void upgradeProBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              4.h.height,
              Center(
                child: SizedBox(
                  height: 15.h,
                  child: Image.asset(AppImages.proLogo),
                ), //SvgPicture.asset(AppImages.proful)
              ),
              2.h.height,
              Center(
                child: CustomTextWidget(
                  title: 'Upgrade to Pro',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              2.h.height,

              CustomTextWidget(
                title:
                    '•Up to 10 words & phrases on notification, lockscreen and widget',
                fontSize: 11,
                color: AppColors.gray,
              ),
              0.8.h.height,
              CustomTextWidget(
                title: '•Choose topics you want to learn (travel, work, etc.)',
                fontSize: 11,
                color: AppColors.gray,
              ),
              0.8.h.height,
              CustomTextWidget(
                title: '•Save and replay every word and sentence',
                fontSize: 11,
                color: AppColors.gray,
              ),
              0.8.h.height,
              CustomTextWidget(
                title: '•Practice Test',
                fontSize: 11,
                color: AppColors.gray,
              ),
              0.8.h.height,
              CustomTextWidget(
                title: '•Priority support',
                fontSize: 11,
                color: AppColors.gray,
              ),
              3.h.height,
              MainCustomButton(
                title: 'Upgrade to Pro',
                onTap: () {
                  Navigator.pop(context);
                  final navigationController = Get.find<BottomNavController>();
                  navigationController.selectedIndex.value=2;
                },
              ),
              2.h.height,
              CustomContainer(
                onTap: () {
                  Navigator.pop(context);
                },
                height: 6.5.h,
                width: double.infinity,
                borders: true,
                cir: 30,
                child: CustomTextWidget(
                  title: 'Maybe Later',
                  fontWeight: FontWeight.w600,
                ),
              ),
              5.h.height,
            ],
          ),
        );
      },
    );
  }
}
