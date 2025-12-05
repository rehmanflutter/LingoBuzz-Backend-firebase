import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/bottomSheets/all_bottom_sheets.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/core/common/utils/text_field_custam.dart';
import 'package:lingobuzz/core/services/app_services.dart';
import 'package:lingobuzz/model/word_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../Routes/app_routes.dart';
import '../../../controller/quizController/quiz_controller.dart';
import '../../../controller/words_controller/word_controller.dart';
import '../../../core/common/widgets/custamContainer.dart';

class SaveWords extends StatelessWidget {
  SaveWords({super.key});

  final wordController = Get.find<WordController>();
  final authController = Get.find<AuthController>();

  // Reactive variable for search text
  final RxString searchQuery = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// Search Field
        CustomTextField(
          title: '',
          hintText: 'Search saved words',
          onChanged: (value) => searchQuery.value = value.toLowerCase().trim(),
          startIcon: Padding(
            padding: EdgeInsets.symmetric(vertical: 1.3.h),
            child: SvgPicture.asset(AppImages.search),
          ),
        ),
        2.h.height,

        /// Practice Test Button
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

        /// Saved Words List
        Obx(() {
          // Filter list based on search
          final filteredList = wordController.savedWordsList.where((word) {
            final wordText = WordModel.getWordByLang(
              word.wordModel,
              authController.currentUser.value?.currentLearning?.languageName ?? "",
            ).toLowerCase();
            return wordText.contains(searchQuery.value);
          }).toList();

          return ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final word = filteredList[index];
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
                      /// Left side (word + translation)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              /// Word in learning language
                              Container(
                                constraints: BoxConstraints(maxWidth: 50.w),
                                child: CustomTextWidget(
                                  title: WordModel.getWordByLang(
                                    word.wordModel,
                                    authController.currentUser.value?.currentLearning?.languageName ?? "",
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              2.w.width,

                              /// Level tag
                              CustomContainer(
                                height: 25,
                                col: const Color(0xffF6F5EE),
                                cir: 30,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  child: CustomTextWidget(
                                    title: word.level ?? "",
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          /// Translation
                          Container(
                            constraints: BoxConstraints(maxWidth: 50.w),
                            child: CustomTextWidget(
                              title: WordModel.getWordByLang(
                                word.wordModel,
                                authController.currentUser.value?.nativeLanguage?.name ?? "",
                              ),
                              color: AppColors.gray,
                              fontSize: 13,
                            ),
                          ),
                          // 0.7.h.height,
                          //
                          // /// Example Sentence (static example, replace with real data if available)
                          // SizedBox(
                          //   width: 65.w,
                          //   child: const CustomTextWidget(
                          //     title: '"Bonjour tout le monde!" - Hello everyone!',
                          //     color: Color(0XFF6B7280),
                          //     fontSize: 11,
                          //   ),
                          // ),
                        ],
                      ),

                      /// Right side (icons)
                      Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              wordController.isWordSaved(word.id)
                                  ? await wordController.unsaveWord(word.id)
                                  : await wordController.saveWord(
                                WordModel.fromJson(word.toJson(), word.id),
                              );
                              await wordController.loadSeenAndSavedWords();
                            },
                            child: SvgPicture.asset(
                              AppImages.star,
                              height: 2.h,
                              color: wordController.isWordSaved(word.id)
                                  ? AppColors.primaryColor
                                  : AppColors.black,
                            ),
                          ),
                          2.w.width,

                          GestureDetector(
                            onTap: () {
                              AppServices.speakText(
                                WordModel.getWordByLang(
                                word.wordModel,
                                authController.currentUser.value?.currentLearning?.languageName ?? "",
                              ),);
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
          );
        }),
      ],
    );
  }
}
