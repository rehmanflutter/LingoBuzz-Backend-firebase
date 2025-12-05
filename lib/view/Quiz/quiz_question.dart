import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/core/common/widgets/custamContainer.dart';
import 'package:lingobuzz/core/common/helpers/app_logger.dart';

import '../../controller/quizController/quiz_controller.dart';

class QuizScreen extends StatelessWidget {
  QuizScreen({super.key});

  final QuizController controller = Get.put(QuizController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(() {
        if (controller.questions.isEmpty) {
          return const Center(
            child: CustomTextWidget(
              title: 'No seen words available for quiz',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          );
        }

        return Column(
          children: [
            /// Header
            _buildHeader(context),

            /// Progress Bar
            _buildProgressBar(),

            /// Quiz Content
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.questions.length,
                onPageChanged: (index) {
                  controller.currentPage.value = index;
                },
                itemBuilder: (context, index) {
                  return _buildQuizPage(index);
                },
              ),
            ),

            /// Check Button
            _buildCheckButton(context),

            6.h.height,
          ],
        );
      }),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Column(
          children: [
            6.h.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CustomContainer(
                    height: 40,
                    width: 40,
                    cir: 30,
                    col: const Color(0xffFAFAFA),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.black,
                      size: 20,
                    ),
                  ),
                ),
                const CustomTextWidget(
                  title: 'Quiz',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                const SizedBox(width: 40),
              ],
            ),
            1.5.h.height,
          ],
        ),
      ),
    );
  }

  /// Progress Bar
  Widget _buildProgressBar() {
    return Obx(() {
      int currentQuestion = controller.currentPage.value + 1;
      int totalQuestions = controller.totalQuestions;
      double percentage = controller.completionPercentage;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextWidget(
                  title: 'Question $currentQuestion of $totalQuestions',
                  fontSize: 12,
                  color: AppColors.gray,
                ),
                CustomTextWidget(
                  title: '${(percentage * 100).toInt()}% complete',
                  fontSize: 12,
                  color: AppColors.gray,
                ),
              ],
            ),
            1.h.height,
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Quiz Page Content
  Widget _buildQuizPage(int questionIndex) {
    final question = controller.questions[questionIndex];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        children: [
          2.h.height,
          CustomContainer(
            width: double.infinity,
            borders: true,
            cir: 10,
            col: AppColors.white,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    children: [
                      CustomTextWidget(
                        title: 'What does',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.left,
                        color: AppColors.black,
                      ),
                      CustomTextWidget(
                        title: " \"${question.question}\" ",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.left,
                        color: AppColors.green,
                      ),

                      CustomTextWidget(
                        title: 'means?',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.left,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                  2.h.height,
                  ...List.generate(
                    question.options.length,
                        (optionIndex) => Obx(() {
                      bool isSelected =
                          controller.selectedAnswers[questionIndex] == optionIndex;
                      return GestureDetector(
                        onTap: () {
                          controller.selectAnswer(questionIndex, optionIndex);
                          Log.debug(
                              "📘 Selected: ${question.options[optionIndex]} for Q${questionIndex + 1}");
                        },
                        child: CustomContainer(
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          borders: true,
                          cir: 8,
                          col: isSelected
                              ? AppColors.green.withOpacity(0.2)
                              : AppColors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.5.h),
                            child: Row(
                              children: [
                                isSelected
                                    ? SvgPicture.asset(AppImages.checkBox)
                                    : SvgPicture.asset(AppImages.clucal),
                                2.w.width,
                                Expanded(
                                  child: CustomTextWidget(
                                    title: question.options[optionIndex],
                                    fontSize: 14,
                                    textAlign: TextAlign.left,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check Button
  Widget _buildCheckButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Obx(
            () => GestureDetector(
          onTap: () {
            if (!controller.isCurrentQuestionAnswered) {
              Log.debug("⚠️ Please select an answer before checking.");
              return;
            }

            final index = controller.currentPage.value;
            final selectedIndex = controller.selectedAnswers[index];
            final correctIndex =
                controller.questions[index].correctAnswerIndex;

            final isCorrect = selectedIndex == correctIndex;

            controller.showResultBottomSheet(isCorrect, context);
          },
          child: CustomContainer(
            height: 6.h,
            width: double.infinity,
            cir: 40,
            col: controller.isCurrentQuestionAnswered
                ? AppColors.primaryColor
                : AppColors.offprimary,
            child: const CustomTextWidget(
              title: 'Check',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
