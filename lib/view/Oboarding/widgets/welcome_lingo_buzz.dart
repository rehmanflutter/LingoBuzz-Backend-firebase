import 'package:flutter/material.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/view/Oboarding/widgets/oboarding_container.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class WelcomeLingoBuzz extends StatelessWidget {
  const WelcomeLingoBuzz({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OboardingContainer(
          title: 'Hi there! I\'m Buzzy, your language learning companion. Let\'s set up your passive learning journey!',
        ),
        8.h.height,
        CustomTextWidget(
          title: 'Welcome to LingoBuzz',
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        0.7.h.height,
        CustomTextWidget(
          textAlign: TextAlign.center,
          title:
              'Learn vocabulary effortlessly through your lock screen, widgets, and notifications. No courses, no pressure - just passive immersion.',
          fontSize: 14,
          color: AppColors.gray,
        ),
      ],
    );
  }
}
