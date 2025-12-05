import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../core/common/widgets/custamContainer.dart';

class LockScreenNotification extends StatelessWidget {
  const LockScreenNotification({super.key});

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
                  title: 'Lock Screen Notification',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
            CustomTextWidget(
              title: 'Learn passively with vocabulary on your lock screen',
              fontSize: 10,
              color: AppColors.gray,
            ),
            1.h.height,
            CustomContainer(
              width: double.infinity,
              borders: true,
              cir: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          // color: Colors.amber,
                          height: 60,
                          width: 60,
                          child: Image.asset(AppImages.buzzyleft),
                        ),
                        3.w.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextWidget(
                              title: 'LingoBuzz',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            0.5.h.height,
                            CustomTextWidget(
                              title: 'J’aime apprendre le francias',
                              fontWeight: FontWeight.w600,
                            ),
                            CustomTextWidget(
                              title: 'I like learning French.',
                              fontSize: 12,

                              color: AppColors.gray,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
