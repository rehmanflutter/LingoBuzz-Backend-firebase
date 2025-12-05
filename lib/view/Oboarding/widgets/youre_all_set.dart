import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/view/Oboarding/widgets/oboarding_container.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class YoureAllSet extends StatelessWidget {
  const YoureAllSet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OboardingContainer(
          // width: 75.w,
          title:
              'Welcome Aboard, Anto. You’re all set to start learning passively. I will be here to help!',
        ),
        7.h.height,
        SvgPicture.asset(AppImages.allok),
        2.h.height,
        Center(
          child: CustomTextWidget(
            title: 'You’re All Set!',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        0.5.h.height,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: CustomTextWidget(
            textAlign: TextAlign.center,
            title: 'Your personalized vocabulary will start appearing on your home screen, widgets and notification',
            fontSize: 15,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }
}
