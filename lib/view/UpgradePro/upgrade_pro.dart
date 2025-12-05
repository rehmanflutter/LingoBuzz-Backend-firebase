import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/controller/UpgradeProController/upgrade_pro_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/snackbar_utils.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/common/utils/date_time_utils.dart';
import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';
import '../../model/user_model.dart';

class UpgradePro extends StatefulWidget {
  const UpgradePro({super.key});

  @override
  State<UpgradePro> createState() => _UpgradeProState();
}

class _UpgradeProState extends State<UpgradePro> {
  final controller = Get.put(UpgradeProController());
  final authController = Get.find<AuthController>();

  // @override
  // void initState() {
  //   super.initState();
  //   controller.gpayConfig = PaymentConfiguration.fromAsset('gpay.json');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          /// ---------- Header ----------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                6.h.height,
                CustomTextWidget(
                  title: 'LingoBuzz Premium',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
                0.8.h.height,
                CustomTextWidget(
                  title:
                  'Enjoy full, unlimited access with these features',
                  fontSize: 9.8,
                  color: const Color(0xff2C2521),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Divider(color: AppColors.offGray),

          /// ---------- Plans ----------
          Expanded(
            child: ListView.builder(
              itemCount: controller.proPlan.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final plan = controller.proPlan[index];
                return CustomContainer(
                  margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8),
                  borders: true,
                  width: double.infinity,
                  cir: 10,
                  col: plan.isPopular
                      ? AppColors.white.withOpacity(0.98)
                      : AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.5.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// -------- Plan Title Row --------
                        Row(
                          children: [
                            SvgPicture.asset(
                              AppImages.book,
                              color: AppColors.gray,
                            ),
                            2.w.width,
                            Expanded(
                              child: CustomTextWidget(
                                title: plan.title,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (plan.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  'Popular',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        1.2.h.height,

                        /// -------- Price and Billing --------
                        Row(
                          children: [
                            CustomTextWidget(
                              title: plan.planLabel,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ],
                        ),
                        0.8.h.height,
                        CustomTextWidget(
                          title: plan.billed,
                          color: const Color(0xff4B5768),
                          fontSize: 12,
                        ),

                        if (plan.save.isNotEmpty) ...[
                          1.h.height,
                          CustomTextWidget(
                            title: plan.save,
                            color: const Color(0xff4B5768),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ],

                        1.5.h.height,

                        /// -------- Dynamic Features --------
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: plan.features.map((feature) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 0.8.h),
                              child: CustomTextWidget(
                                title: '• $feature',
                                fontSize: 11,
                                color: AppColors.gray,
                              ),
                            );
                          }).toList(),
                        ),

                        3.h.height,

                        Obx(() {
                          final currentUser = authController.currentUser.value;

                          // ✅ Find if user already has this plan active
                          final activeSubscription = currentUser?.subscription?.firstWhere(
                                (sub) => sub.planName == plan.title && (sub.isActive ?? false),
                            orElse: () => SubscriptionModel(), // empty if not found
                          );

                          final bool hasActivePlan = activeSubscription?.planName == plan.title;

                          return MainCustomButton(
                            backColour: hasActivePlan ? AppColors.green : AppColors.primaryColor,
                            textColor: hasActivePlan ? AppColors.white : AppColors.black,
                            height: 5.3,
                            title: hasActivePlan
                                ? 'Valid till ${DateTimeUtils.formatDateToReadable(activeSubscription?.endDate)}'
                                : 'Upgrade to Pro',
                            onTap: () {
                              controller.selectedPlanIndex.value = index;

                              // Optional: prevent re-purchase of active plan
                              if (!hasActivePlan) {
                                if(Platform.isAndroid){
                                  controller.makeStripePayment();
                                }else{
                                  paymentBottomSheet(context);
                                }
                              } else {
                                SnackBarUtils.showSuccessSnackbar('You already have this plan active.');
                              }
                            },
                          );
                        })

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ====================== PAYMENT SHEET ======================
  static paymentBottomSheet(BuildContext context) {
    final controller = Get.put(UpgradeProController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              1.h.height,
              Center(
                child: CustomTextWidget(
                  title: 'Choose Payment Method',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              3.h.height,
              Obx(
                    () => CustomContainer(
                  onTap: controller.isProcessingCardPayment.value
                      ? null
                      : () {
                    Navigator.pop(context);
                    controller.makeStripePayment();
                  },
                  height: 6.5.h,
                  width: double.infinity,
                  cir: 30,
                  borders: true,
                  col: controller.isProcessingCardPayment.value
                      ? AppColors.gray.withValues(alpha: 0.5)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isProcessingCardPayment.value)
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.black,
                          ),
                        )
                      else
                        Icon(Icons.credit_card, size: 20),
                      2.w.width,
                      CustomTextWidget(
                        title: controller.isProcessingCardPayment.value
                            ? 'Processing...'
                            : 'Pay with Card',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ],
                  ),
                ),
              ),

              2.h.height,

              /// Apple Pay Button
              Obx(() =>CustomContainer(
                  onTap: controller.isProcessingApplePayment.value
                      ? null
                      : () {
                    Navigator.pop(context);
                    controller.makeApplePayPayment();
                  },
                  height: 6.5.h,
                  width: double.infinity,
                  cir: 30,
                  borders: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple),
                      2.w.width,
                      CustomTextWidget(
                        title: controller.isProcessingApplePayment.value
                            ? 'Processing...'
                            : 'Pay with Apple Pay',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ],
                  ),
                ),
              ),

              3.h.height,
              CustomContainer(
                onTap: () {
                  Navigator.pop(context);
                },
                height: 6.5.h,
                width: double.infinity,
                cir: 30,
                borders: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    2.w.width,
                    CustomTextWidget(
                      title: 'Cancel',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ],
                ),
              ),

              2.h.height,
            ],
          ),
        );
      },
    );
  }
}


