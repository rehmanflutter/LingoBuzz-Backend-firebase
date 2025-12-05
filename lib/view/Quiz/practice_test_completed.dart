import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/controller/quizController/quiz_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';
import '../../core/common/widgets/progressIndicator.dart';

class PracticeTestCompleted extends StatelessWidget {
  PracticeTestCompleted({super.key});

  final QuizController quizController = Get.find<QuizController>();

  @override
  Widget build(BuildContext context) {
    final result = quizController.getResult();
    final num percentage = result.percentage;
    final bool isLowScore = percentage < 40;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            5.h.height,
            CustomContainer(
              height: 20.h,
              width: double.infinity,
              imageDecoration: DecorationImage(
                image: AssetImage(AppImages.orange),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  isLowScore ? AppImages.buzzysad : AppImages.buzzy,
                  height: 15.h,
                ),
              ),
            ),
            2.h.height,
            CustomTextWidget(
              title: "Practice Test Completed",
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              child: CustomTextWidget(
                color: AppColors.gray,
                textAlign: TextAlign.center,
                fontSize: 13,
                title:
                'You scored ${result.correctAnswers} out of ${result.totalQuestions} questions correctly. ${isLowScore ? "Keep practicing!" : "Amazing!"}',
              ),
            ),
            4.h.height,
            CustomProgressIndicator(
              barColor: isLowScore ? Colors.red : AppColors.green,
              totalSteps: result.correctAnswers,
              progress: result.correctAnswers / result.totalQuestions,
            ),
            1.h.height,
            CustomTextWidget(
              title: '${result.percentage.toStringAsFixed(0)}% accuracy',
              fontSize: 13,
            ),
            20.h.height,
            MainCustomButton(
              title: 'Back to home',
              onTap: () {
                quizController.resetQuiz();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.bottomAppBarScreen, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
