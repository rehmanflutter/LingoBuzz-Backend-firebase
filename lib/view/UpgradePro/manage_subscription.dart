import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/controller/UpgradeProController/upgrade_pro_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';

class ManageSubscription extends StatelessWidget {
  ManageSubscription({super.key});
  final controller = Get.put(UpgradeProController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                7.h.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back, color: AppColors.black),
                    ),
                    CustomTextWidget(
                      title: 'Manage Subscription',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    2.w.width,
                  ],
                ),
              ],
            ),
          ),
          1.h.height,

          Divider(color: AppColors.offGray),
          1.h.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                CustomContainer(
                  width: double.infinity,
                  borders: true,
                  cir: 10,
                  col: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title
                        const CustomTextWidget(
                          title: 'Pro Subscription',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          textAlign: TextAlign.left,
                          color: Colors.black,
                        ),

                        0.5.h.height,

                        /// Status
                        CustomTextWidget(
                          title: 'You are on Pro Monthly Plan',
                          fontSize: 11,
                          textAlign: TextAlign.left,
                          color: AppColors.gray,
                        ),

                        2.h.height,

                        /// Next Billing Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomTextWidget(
                              title: 'Next Billing:',
                              fontSize: 13,
                              textAlign: TextAlign.left,
                              color: Colors.black,
                            ),
                            CustomTextWidget(
                              title: 'Oct 21, 2025',
                              fontSize: 13,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),

                        1.5.h.height,

                        Divider(color: AppColors.offGray, height: 0),

                        1.5.h.height,

                        /// Payment Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomTextWidget(
                              title: 'Payment:',
                              fontSize: 13,
                              textAlign: TextAlign.left,
                              color: Colors.black,
                            ),
                            CustomTextWidget(
                              title: '••••••1025',
                              fontSize: 13,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),

                        1.5.h.height,

                        Divider(color: AppColors.offGray, height: 0),

                        1.5.h.height,

                        /// Plan Type Row
                        CustomTextWidget(
                          title: '  Plan Type',
                          fontSize: 13,
                          textAlign: TextAlign.left,
                          color: Colors.black,
                        ),
                        1.h.height,
                        CustomContainer(
                          height: 5.h,
                          width: double.infinity,
                          borders: true,
                          cir: 8,
                          col: AppColors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: 'Monthly',
                                isExpanded:
                                    true, // 👈 makes text align properly with space
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.gray,
                                  size: 22,
                                ),
                                dropdownColor: AppColors.white,
                                items: ['Monthly', 'Yearly', 'Lifetime'].map((
                                  String plan,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: plan,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        CustomTextWidget(
                                          title: plan,
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  print('Plan changed to: $newValue');
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                2.h.height,

                MainCustomButton(
                  title: 'Change Plan',
                  onTap: () {
                    ChangePlanSubscription(context);
                  },
                ),
                2.h.height,
                CustomContainer(
                  onTap: () {
                    showCancelSubscriptionDialog(context);
                  },
                  height: 6.h,
                  width: double.infinity,
                  cir: 30,
                  borderCol: AppColors.offGray,
                  borders: true,
                  child: CustomTextWidget(
                    title: 'Cancel Subscription',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showCancelSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 7.w),
          backgroundColor: AppColors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.buzzysad, // replace with your image
                  height: 80,
                  width: 80,
                ),
                SizedBox(height: 15),
                CustomTextWidget(
                  title: 'Cancel Subscription',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                SizedBox(height: 10),
                CustomTextWidget(
                  title:
                      'Are you sure you want to cancel your Pro plan? You’ll lose access to all Pro features at the end of your billing cycle',
                  fontSize: 11,
                  color: Colors.grey,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: CustomContainer(
                        height: 45,
                        cir: 30,
                        borders: true,
                        borderCol: Colors.grey.shade400,
                        onTap: () => Navigator.pop(context),
                        child: Center(
                          child: CustomTextWidget(
                            title: 'Cancel',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomContainer(
                        height: 45,
                        cir: 30,
                        col: AppColors.primaryColor,
                        onTap: () {
                          // Navigator.pop(context);
                          // Add your confirm action here
                        },
                        child: Center(
                          child: CustomTextWidget(
                            title: 'Confirm',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void ChangePlanSubscription(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 7.w),
          backgroundColor: AppColors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.proLogo, // replace with your image
                  height: 80,
                  width: 80,
                ),
                SizedBox(height: 15),
                CustomTextWidget(
                  title: 'Change Plan',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                SizedBox(height: 10),
                CustomTextWidget(
                  title:
                      'You’re currently on the Pro Monthly plan. Do you want to switch to a different plan?',
                  fontSize: 11,
                  color: Colors.grey,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: CustomContainer(
                        height: 45,
                        cir: 30,
                        borders: true,
                        borderCol: Colors.grey.shade400,
                        onTap: () => Navigator.pop(context),
                        child: Center(
                          child: CustomTextWidget(
                            title: 'No',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomContainer(
                        height: 45,
                        cir: 30,
                        col: AppColors.primaryColor,
                        onTap: () {
                          // Navigator.pop(context);
                          // Add your confirm action here
                        },
                        child: Center(
                          child: CustomTextWidget(
                            title: 'Yes',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
