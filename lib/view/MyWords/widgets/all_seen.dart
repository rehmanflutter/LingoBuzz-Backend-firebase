import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/MyWordsController/my_words_cpontroller.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/bottomSheets/all_bottom_sheets.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/core/services/app_services.dart';
import 'package:lingobuzz/model/word_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../Routes/app_routes.dart';
import '../../../controller/quizController/quiz_controller.dart';
import '../../../controller/words_controller/word_controller.dart';
import '../../../core/common/widgets/custamContainer.dart';

class AllWordsSeen extends StatelessWidget {
  AllWordsSeen({super.key});

  final controller = Get.put(MyWordsCpontroller());
  final wordController = Get.find<WordController>();
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// ✅ Apply level filter
      final selectedLevel = controller.level[controller.levelSelect.value];
      final filteredWords = selectedLevel == 'All'
          ? wordController.seenWordsList
          : wordController.seenWordsList
          .where((word) => (word.level ?? '').toUpperCase() == selectedLevel)
          .toList();

      return Column(
        children: [
          2.h.height,

          /// Filter Buttons (Level Chips)
          SizedBox(
            height: 3.h,
            child: ListView.builder(
              itemCount: controller.level.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Obx(
                      () => CustomContainer(
                    onTap: () {
                      controller.levelSelect.value = index;
                    },
                    height: 3.5.h,
                    borders: true,
                    margin: EdgeInsets.only(right: 2.w),
                    col: controller.levelSelect.value == index
                        ? AppColors.lightGray
                        : Colors.transparent,
                    cir: 30,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.5.w),
                      child: CustomTextWidget(
                        title: controller.level[index],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          2.h.height,

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomContainer(
                onTap: () {
                  if (authController.currentUser.value?.subscription != null && authController.currentUser.value!.subscription!.isNotEmpty) {
                    final quizController = Get.put(QuizController());
                    quizController.resetQuiz();
                    quizController.generateQuiz();
                    Navigator.pushNamed(context, AppRoutes.welconQuiz);
                  }else{
                    AllBottomSheets.upgradeProBottomSheet(context);
                  }
                },
                borders: true,
                col: AppColors.lightGray,
                cir: 30,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                  child: Row(
                    children: [
                      SvgPicture.asset(AppImages.smalbook),
                      2.w.width,
                      CustomTextWidget(
                        title: 'Take a practice test',
                        fontSize: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          2.h.height,

          /// ✅ Filtered List or Empty State
          if (filteredWords.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: CustomTextWidget(
                title: 'No words found in $selectedLevel level',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray,
              ),
            )
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredWords.length,
              itemBuilder: (context, index) {
                final word = filteredWords[index];
                return CustomContainer(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  borders: true,
                  cir: 10,
                  shadow: true,
                  col: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Word Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  constraints: BoxConstraints(maxWidth: 50.w),
                                  child: CustomTextWidget(
                                    title: WordModel.getWordByLang(word.wordModel, authController.currentUser.value?.currentLearning?.languageName??"English"),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                2.w.width,
                                CustomContainer(
                                  height: 25,
                                  col: const Color(0xffF6F5EE),
                                  cir: 30,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 3.5.w),
                                    child: CustomTextWidget(
                                      title: word.level ?? "",
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              constraints: BoxConstraints(maxWidth: 50.w),
                              child: CustomTextWidget(
                                title: WordModel.getWordByLang(word.wordModel, authController.currentUser.value?.nativeLanguage?.name??"English"),
                                color: AppColors.gray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        /// Star + Volume Actions
                        Row(
                          children: [
                            Obx(()=> InkWell(
                                onTap: () async {
                                  if (wordController.isWordSaved(word.wordModel.id)) {
                                    await wordController.unsaveWord(word.wordModel.id);
                                  } else {
                                    await wordController.saveWord(
                                      WordModel.fromJson(
                                        word.wordModel.toJson(),
                                        word.wordModel.id,
                                      ),
                                    );
                                  }
                                  await wordController.loadSeenAndSavedWords();
                                },
                                child: SvgPicture.asset(
                                  AppImages.star,
                                  height: 2.h,
                                  color: wordController.isWordSaved(word.wordModel.id)
                                      ? AppColors.primaryColor
                                      : AppColors.black,
                                ),
                              ),
                            ),
                            2.w.width,
                            GestureDetector(
                              onTap: () {
                                AppServices.speakWord(WordModel.getWordByLang(word.wordModel, authController.currentUser.value?.currentLearning?.languageName??"English"));
                              },
                              child: SvgPicture.asset(AppImages.volume),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      );
    });
  }
}
