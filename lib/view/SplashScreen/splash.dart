import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../controller/AuthController/auth_controller.dart';
import '../../core/common/widgets/custom_Button.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});
  final pageController = PageController();
  final controller = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          SizedBox(
            height: 70.h,
            // color: Colors.amber,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: PageView.builder(
                controller: pageController,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      10.h.height,
                      Center(
                        child: CustomTextWidget(
                          title: 'LingoBuzz',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      7.h.height,
                      SizedBox(
                        height: 28.h,
                        // color: Colors.amber,
                        child: Image.asset(AppImages.buzzysplish),
                      ),
                      3.h.height,
                      SizedBox(
                        width: 83.w,
                        // color: Colors.amber,
                        child: CustomTextWidget(
                          title: 'The Fun way to Mastering New Language',
                          fontSize: 21,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          SmoothPageIndicator(
            controller: pageController,
            count: 2,
            axisDirection: Axis.horizontal,
            effect: ExpandingDotsEffect(
              spacing: 8.0,
              radius: 10.0,
              dotWidth: 8.0,
              dotHeight: 7.0,
              // paintStyle: PaintingStyle.stroke,
              strokeWidth: 1.5,
              dotColor: AppColors.lightGray,
              activeDotColor: AppColors.primaryColor,
            ),
          ),
          3.h.height,
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MainCustomButton(
              title: 'Start Learning',
              onTap: () {
                final box = GetStorage();
                box.write("showOnBoarding",false);
                Navigator.pushNamed(context, AppRoutes.oboarding);
              },
            ),
            2.h.height,

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextWidget(title: 'I already have an account? '),
                GestureDetector(
                  onTap: () {
                    final box = GetStorage();
                    box.write("showOnBoarding",false);
                    controller.isLogin.value=true;
                    Navigator.pushReplacementNamed(context, AppRoutes.oboarding);
                  },
                  child: CustomTextWidget(
                    title: 'Login here',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            6.h.height,
          ],
        ),
      ),
    );
  }
}
