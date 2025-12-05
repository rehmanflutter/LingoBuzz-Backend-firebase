import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/common/widgets/custamContainer.dart';

class HomeScreenWidget extends StatelessWidget {
  const HomeScreenWidget({super.key});

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(AppImages.lock),
                        2.w.width,
                        CustomTextWidget(
                          title: 'Home Screen Widgets',
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
                        title:
                            'Learn passively with vocabulary on your home screen',
                        fontSize: 9,
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
            Center(
              child: CustomContainer(
                width: 60.w,
                col: AppColors.white,
                cir: 15,
                shadow: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomContainer(
                                height: 8,
                                width: 8,
                                col: AppColors.black,
                                cir: 10,
                              ),
                              2.w.width,
                              CustomTextWidget(
                                title: 'LingoBuzz',
                                color: AppColors.gray,
                              ),
                            ],
                          ),
                          SvgPicture.asset(AppImages.circular, height: 1.5.h),
                        ],
                      ),
                      3.h.height,
                      CustomTextWidget(
                        title: 'Bonjour',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      CustomTextWidget(
                        title: 'Hello',
                        fontSize: 14,
                        color: AppColors.gray,
                      ),
                      4.h.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomContainer(
                            height: 5.h,
                            width: 25.w,
                            cir: 20,
                            borders: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  AppImages.soundIcon,
                                  height: 2.h,
                                ),
                                2.w.width,
                                CustomTextWidget(title: 'Play'),
                              ],
                            ),
                          ),

                          CustomContainer(
                            height: 5.h,
                            width: 25.w,
                            cir: 20,
                            borders: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  AppImages.staricon,
                                  height: 2.h,
                                ),
                                2.w.width,
                                CustomTextWidget(title: 'Save'),
                              ],
                            ),
                          ),
                        ],
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
