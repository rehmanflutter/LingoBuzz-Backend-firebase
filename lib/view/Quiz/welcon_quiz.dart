import 'package:flutter/material.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';

class WelconQuiz extends StatelessWidget {
  const WelconQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: CustomContainer(
              height: 40,
              width: 40,
              cir: 30,
              col: const Color(0xffFAFAFA),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppImages.proLogo, height: 20.h),
            2.h.height,
            CustomTextWidget(
              title: 'Practice Test',
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
            CustomTextWidget(
              title: 'A quick check to see what you’ve learned so far',
              fontSize: 13,
              color: AppColors.gray,
            ),
            20.h.height,
            MainCustomButton(
              title: 'Continue',
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.quizScreen);
              },
            ),
          ],
        ),
      ),
    );
  }
}
