import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/text_field_custam.dart';
import 'package:lingobuzz/core/common/widgets/custom_Button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../controller/AuthController/auth_controller.dart';
import '../utils/Themes/app_color.dart';

class ForgotPassword {
  static void openResetPasswordBottomSheet(BuildContext context) {
    final controller = Get.find<AuthController>();
    controller.resetPasswordErrorMessage.value='';
    controller.resetEmailController.clear();
    showModalBottomSheet(
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 10),
              CustomTextWidget(
                title: "Forgot Password",
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 5),
              CustomTextWidget(
                title: 'Enter the email associated with your account and we\'ll send you a link to reset your password.',
                fontSize: 12,
                color: AppColors.gray,
              ),
              SizedBox(height: 10),
              CustomTextField(hintText: 'exampleuser@gmail.com',controller: controller.resetEmailController),
              Obx(()=> controller.resetPasswordErrorMessage.value.isNotEmpty?
              Align(
                alignment: Alignment.centerLeft,
                child: CustomTextWidget(
                    title: controller.resetPasswordErrorMessage.value,
                    fontSize: 12,
                    color: AppColors.red,
                  ),
              ):SizedBox(),
              ),
              SizedBox(height: 10),
              Obx(()=> MainCustomButton(
                  loading: controller.isLoading.value,
                  title: 'Send Email',
                  onTap: () async {
                    bool response = await controller.sendPasswordResetEmail();
                    if(response){
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }
}
