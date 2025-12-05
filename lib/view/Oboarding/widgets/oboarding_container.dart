import 'package:flutter/material.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/common/widgets/custamContainer.dart';

class OboardingContainer extends StatelessWidget {
  final String title;
  final double? width;
  const OboardingContainer({
    super.key,
    required this.title,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        3.h.height,
        CustomContainer(
          height: 120,
          width: 120,
          // col: Colors.amber,
          imageDecoration: DecorationImage(image: AssetImage(AppImages.buzzy)),
        ),
        3.h.height,
        Stack(
          children: [
            Container(
              //color: Colors.amber,
              height: 13.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: 5.506, // 180 degrees (rotates upside down)
                  child: CustomContainer(
                    height: 60,
                    width: 60,
                    col: AppColors.green,
                    cir: 2,
                  ),
                ),
              ],
            ),
            Container(color: Colors.white, height: 13.h),
            Positioned(
              // bottom: 1,
              // left: 0,
              // right: 0,
              child: Center(
                child: CustomContainer(
                  // height: 12.h,
                  width: width,
                  col: AppColors.green,
                  cir: 10,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    child: CustomTextWidget(
                      color: AppColors.white,
                      textAlign: TextAlign.center,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      title:
                      title, // 'Hi there! I\'m Buzzy, your language learning companion. Let\'s set up your passive learning journey!',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
