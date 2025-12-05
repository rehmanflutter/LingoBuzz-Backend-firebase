import 'package:flutter/material.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';

class WelcomeProScreen extends StatelessWidget {
  const WelcomeProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomContainer(
            width: double.infinity,
            height: 20.h,
            imageDecoration: DecorationImage(
              image: AssetImage(AppImages.orange),
              // fit: BoxFit.cover,
            ),
            // col: Colors.amber,
            child: Image.asset(
              AppImages.buzzy, // replace with your image
              height: 10.h,
            ),
          ),
          1.h.height,
          CustomTextWidget(
            title: 'Welcome to LingoBuzz Pro',
            fontWeight: FontWeight.w600,
            fontSize: 19,
          ),
          CustomTextWidget(
            title: 'Enjoy unlimited access to all premium features',
            fontSize: 10,
            color: AppColors.gray,
          ),
          2.h.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: MainCustomButton(
              title: 'Continue',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.manageSubscription);
              },
            ),
          ),
        ],
      ),
    );
  }
}
