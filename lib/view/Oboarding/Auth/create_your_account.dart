import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/bottomSheets/forgot_password.dart';
import 'package:lingobuzz/core/common/utils/text_field_custam.dart';
import 'package:lingobuzz/view/Oboarding/widgets/oboarding_container.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../core/common/utils/Themes/app_color.dart';

class CreateYourAccount extends StatelessWidget {
  CreateYourAccount({super.key});

  final controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLogin = controller.isLogin.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OboardingContainer(
            width: 80.w,
            title: 'Let’s get to know you better!',
          ),
          Center(
            child: CustomTextWidget(
              title: isLogin ? 'Login to your account' : 'Create your Account',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          2.h.height,

          /// Show Name Fields only for Create Account
          if (!isLogin)
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    title: 'First Name',
                    hintText: 'First Name',
                    controller: controller.firstNameController,
                  ),
                ),
                2.w.width,
                Expanded(
                  child: CustomTextField(
                    title: 'Last Name',
                    hintText: 'Last Name',
                    controller: controller.lastNameController,
                  ),
                ),
              ],
            ),
          if (!isLogin) 0.5.h.height,

          /// Common Fields (Email + Password)
          CustomTextField(
            title: 'Email Address',
            hintText: 'exampleuser@gmail.com',
            controller: controller.emailController,
          ),
          0.5.h.height,

          Obx(() => CustomTextField(
            obscur: controller.showPassword.value,
            title: 'Password',
            hintText: 'Enter your password',
            controller: controller.passwordController,
            lastIcon: GestureDetector(
              onTap: () {
                controller.showPassword.value =
                !controller.showPassword.value;
              },
              child: Icon(
                controller.showPassword.value
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
            ),
          )),

          /// ✅ Toggle between Login / Signup
          Obx(() => controller.isLogin.value
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              TextButton(
                onPressed: () {
                  controller.isLogin.value = false;
                },
                child: CustomTextWidget(
                  title: "Create account",
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),

              TextButton(
                onPressed: () {
                  ForgotPassword.openResetPasswordBottomSheet(context);
                },
                child: CustomTextWidget(
                  title: "Forgot Password?",
                  fontWeight: FontWeight.bold,
                  color: AppColors.red,
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              CustomTextWidget(
                title: "Already have an account? ",
                color: Colors.black,
              ),
              TextButton(
                onPressed: () {
                  controller.isLogin.value = true;
                },
                child: CustomTextWidget(
                  title: "Login",
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
            ],
          ))

        ],
      );
    });
  }
}
