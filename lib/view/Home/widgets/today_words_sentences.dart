import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/services/app_services.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:lingobuzz/model/word_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../core/common/shimmers/today_phrases_shimmer.dart';
import '../../../core/common/widgets/custamContainer.dart';

class TodayWordsSentences extends StatelessWidget {
  TodayWordsSentences({super.key});

  final WordController controller = Get.find<WordController>();
  final AuthController authController = Get.find<AuthController>();

  bool _calledOnce = false;
  final Random _random = Random();

  /// ✅ Helper to get tile color
  Color _getTileColor(int index) {
    if (index == 0) return const Color(0xff51D0FE);
    if (index == 1) return const Color(0xff1BDD68);
    if (index == 2) return const Color(0xffFF81B3);

    // Random pastel colors
    final List<Color> colorPalette = [
      const Color(0xffFFA07A),
      const Color(0xff9B59B6),
      const Color(0xffF39C12),
      const Color(0xff16A085),
      const Color(0xffE74C3C),
      const Color(0xff5DADE2),
      const Color(0xff58D68D),
      const Color(0xffF1948A),
      const Color(0xffBB8FCE),
    ];
    return colorPalette[_random.nextInt(colorPalette.length)];
  }

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      width: double.infinity,
      col: AppColors.white,
      shadow: true,
      borders: true,
      cir: 10,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 8),
        child: Column(
          children: [
            /// 🔹 Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(AppImages.book),
                    2.w.width,
                    CustomTextWidget(
                      title: 'Today\'s Words/Phrases',
                      fontWeight: FontWeight.w800,
                    ),
                  ],
                ),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Image.asset(AppImages.buzzyleft),
                ),
              ],
            ),
            1.h.height,
            Obx(() {
              final words = controller.wordsList;

              if (!_calledOnce && words.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  _calledOnce = true;
                  controller.markWordsAsSeen(words);
                  await controller.loadSeenAndSavedWords();
                });
              }

              if (controller.isLoading.value) {
                return const ShimmerTodayWordsSentences();
              }

              if(controller.wordsList.isEmpty && controller.errorMessage.isNotEmpty){
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: CustomTextWidget(
                    textAlign: TextAlign.center,
                    title: controller.errorMessage.toString(),
                    fontSize: 16,
                   // color: AppColors.grey,
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 50.h),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    final color = _getTileColor(index);

                    return CustomContainer(
                      margin: const EdgeInsets.only(bottom: 10),
                      col: color,
                      cir: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 60.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextWidget(
                                    title:
                                    WordModel.getWordByLang(word, authController.currentUser.value?.currentLearning?.languageName ?? ""),
                                    fontSize: 17,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  CustomTextWidget(
                                    height: 1.2,
                                    title: WordModel.getWordByLang(
                                      word,
                                      authController.currentUser.value
                                          ?.nativeLanguage
                                          ?.name ??
                                          "",
                                    ),
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 33,
                                child: IconButton(
                                  onPressed: () async {
                                    if (controller.isWordSaved(word.id)) {
                                      await controller.unsaveWord(word.id);
                                    } else {
                                      await controller.saveWord(word);
                                    }
                                    await controller.loadSeenAndSavedWords();
                                  },
                                  icon: Obx(()=> SvgPicture.asset(
                                      AppImages.star,
                                      height: 15,
                                      color: controller.isWordSaved(word.id)
                                          ? AppColors.primaryColor
                                          : AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 35,
                                child: IconButton(
                                  onPressed: () {
                                    AppServices.speakText(
                                      WordModel.getWordByLang(
                                        word,
                                        authController.currentUser.value
                                            ?.currentLearning
                                            ?.languageName ??
                                            "",
                                      )
                                    );
                                  },
                                  icon: SvgPicture.asset(
                                    AppImages.volumeUp,
                                    height: 18,
                                  ),
                                ),
                              ),
                              5.width
                            ],
                          ),

                        ],
                      ),

                    );
                  },
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
