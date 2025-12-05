import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/controller/quizController/quiz_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/bottomSheets/all_bottom_sheets.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../controller/words_controller/word_controller.dart';
import '../../../core/common/shimmers/take_quiz_shimmer.dart';
import '../../../core/common/widgets/custamContainer.dart';
import '../../../core/common/widgets/progressIndicator.dart';

class TakeQuizWidget extends StatelessWidget {
  TakeQuizWidget({super.key});

  final authController = Get.find<AuthController>();
  final wordController = Get.find<WordController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = wordController.isLoading.value || authController.isLoading.value; // observe both controllers

      return CustomContainer(
        width: double.infinity,
        col: AppColors.white,
        shadow: true,
        borders: true,
        cir: 10,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
          child: isLoading
              ? const TakeQuizLoadingWidget() // ✅ Show shimmer
              : _buildStatsContent(context),
        ),
      );
    });
  }

  /// ✅ Extracted stats content for clarity
  Widget _buildStatsContent(BuildContext context) {



    return Obx((){
      final progressStats = wordController.getDailyProgressStats();
      final wordsShownSoFar = progressStats['wordsShownSoFar'] as int;
      final totalWordsToday = progressStats['totalWordsToday'] as int;
     return Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(AppImages.learning),
              3.w.width,
              CustomTextWidget(
                title: 'Learning Stats',
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ],
          ),
          1.h.height,
          _buildStatRow(
            'Daily Goal',
            '${authController.currentUser.value?.currentLearning?.wordsPerDay ?? 0} words',
          ),
          1.h.height,
          // ✅ Updated Progress Indicator
          CustomProgressIndicator(
            totalSteps: totalWordsToday > 0 ? totalWordsToday : 5,
            progress: double.parse(wordsShownSoFar.toString()),
            barColor: AppColors.primaryColor,
          ),
          1.h.height,
          _buildWeeklyRow(),
          1.h.height,
          _buildMonthlyRow(),
          2.h.height,
          CustomContainer(
            onTap: () {
              if (authController.currentUser.value?.subscription != null &&
                  authController.currentUser.value!.subscription!.isNotEmpty) {
                final quizController = Get.put(QuizController());
                quizController.resetQuiz();
                quizController.generateQuiz();
                Navigator.pushNamed(context, AppRoutes.welconQuiz);
              } else {
                AllBottomSheets.upgradeProBottomSheet(context);
              }
            },
            height: 6.h,
            width: double.infinity,
            borders: true,
            cir: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(AppImages.trophy, height: 20),
                2.w.width,
                CustomTextWidget(title: 'Take Quiz'),
              ],
            ),
          ),
        ],
      );
    }
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomTextWidget(
          title: title,
          color: AppColors.gray,
          fontSize: 10,
        ),
        CustomTextWidget(title: value),
      ],
    );
  }

  Widget _buildWeeklyRow() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeklyWords = wordController.seenWordsList.where((word) {
      final date = word.dateTime;
      return date != null &&
          date.isAfter(startOfWeek) &&
          date.isBefore(now.add(const Duration(days: 1)));
    }).length;

    return _buildStatRow('This Week', '$weeklyWords words');
  }

  Widget _buildMonthlyRow() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthlyWords = wordController.seenWordsList.where((word) {
      final date = word.dateTime;
      return date != null &&
          date.isAfter(startOfMonth) &&
          date.isBefore(now.add(const Duration(days: 1)));
    }).length;

    return _buildStatRow('This Month', '$monthlyWords words');
  }
}
