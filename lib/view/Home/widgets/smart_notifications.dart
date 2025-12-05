import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/common/widgets/custamContainer.dart';

class SmartNotifications extends StatelessWidget {
  const SmartNotifications({super.key});

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(AppImages.notification, height: 1.7.h),
                        2.w.width,
                        CustomTextWidget(
                          title: 'Smart Notifications',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ],
                    ),
                    SizedBox(
                      // color: Colors.amber,
                      width: 72.w,
                      child: CustomTextWidget(
                        maxLines: 1,
                        title: 'Receive vocabulary through gentle notification',
                        fontSize: 10,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  // color: Colors.amber,
                  height: 40,
                  width: 13.w,

                  child: Image.asset(AppImages.buzzyleft),
                ),
              ],
            ),

            2.h.height,
            CustomContainer(
              width: double.infinity,
              col: AppColors.white,
              shadow: true,
              borders: true,
              cir: 10,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(0),
                      leading: SvgPicture.asset(
                        AppImages.notifications,
                        height: 3.h,
                      ),
                      title: CustomTextWidget(
                        title: 'LingoBuzz',
                        fontWeight: FontWeight.w600,
                      ),
                      subtitle: CustomTextWidget(
                        title: '2 minutes ago',
                        fontSize: 10,
                        color: AppColors.gray,
                      ),
                      trailing: Icon(
                        Icons.close_outlined,
                        color: AppColors.gray,
                      ),
                    ),

                    Row(
                      children: [
                        CustomContainer(
                          height: 6.h,
                          width: 8,
                          col: AppColors.orage,
                          cir: 20,
                        ),
                        2.w.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomTextWidget(
                                  title: 'Merci beaucoup',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                2.w.width,
                                SvgPicture.asset(AppImages.soundIcon),
                                1.w.width,

                                SvgPicture.asset(AppImages.staricon),
                              ],
                            ),
                            1.h.height,
                            CustomTextWidget(
                              title: 'Thank you very much',
                              fontSize: 12,
                              color: AppColors.gray,
                            ),
                          ],
                        ),
                      ],
                    ),
                    2.h.height,
                    CustomTextWidget(
                      title:
                          'Tap to hear pronunciation and save to your collection',
                      fontSize: 10,
                      color: AppColors.gray,
                    ),
                    2.h.height,
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
