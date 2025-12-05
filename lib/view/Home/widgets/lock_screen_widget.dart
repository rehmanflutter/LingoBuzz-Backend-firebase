import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/common/widgets/custamContainer.dart';

class LockScreenWidget extends StatelessWidget {
  const LockScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      width: double.infinity,
      col: AppColors.white,
      shadow: true,
      borders: true,
      cir: 10,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(AppImages.lock),
                2.w.width,
                CustomTextWidget(
                  title: 'Lock Screen Widget',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
            CustomTextWidget(
              title: 'Learn passively with vocabulary on your lock screen',
              fontSize: 8,
              color: AppColors.gray,
            ),
            2.h.height,
            Center(
              child: CustomContainer(
                width: 50.w,
                col: AppColors.white,
                cir: 15,
                shadow: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomTextWidget(
                            title: 'Merci',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),

                          CustomTextWidget(
                            title: 'Thank you',
                            fontSize: 13,

                            color: AppColors.gray,
                          ),
                        ],
                      ),

                      SizedBox(
                        // color: Colors.amber,
                        height: 40,
                        width: 40,
                        child: Image.asset(AppImages.buzzyleft),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
