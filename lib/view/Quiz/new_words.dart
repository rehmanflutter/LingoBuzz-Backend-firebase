import 'package:flutter/material.dart';
import 'package:lingobuzz/Routes/app_routes.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';

class NewWordsLesson extends StatelessWidget {
  NewWordsLesson({super.key});
  final words = [
    {'word': 'Hola!', 'translation': 'Hello'},
    {'word': 'Tengo Hambre!', 'translation': 'I am hungry'},
    {'word': 'Casa!', 'translation': 'Cases'},
    {'word': 'Por favor!', 'translation': 'Excuse me'},
  ];
  @override
  Widget build(BuildContext context) {
    // Default words if not provided

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                4.h.height,

                Image.asset(AppImages.buzzy, height: 15.h),

                1.h.height,

                const CustomTextWidget(
                  title: 'Good Work!',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),

                0.4.h.height,

                CustomTextWidget(
                  title: 'You just completed your first lesson',
                  fontSize: 14,
                  color: AppColors.gray,
                ),

                2.h.height,

                _buildNewWordsSection(words),

                3.h.height,

                MainCustomButton(
                  title: 'Back to home',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.bottomAppBarScreen);
                  },
                ),
                2.h.height,
                CustomContainer(
                  width: double.infinity,
                  height: 6.h,
                  cir: 30,
                  borderCol: AppColors.offGray,
                  borders: true,
                  child: CustomTextWidget(title: 'Try Again'),
                ),
                6.h.height,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// New Words Section
  Widget _buildNewWordsSection(List<Map<String, String>> words) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Section Title
        Padding(
          padding: EdgeInsets.only(left: 2.w, bottom: 1.5.h),
          child: const CustomTextWidget(
            title: 'New Words',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.left,
            color: Colors.black,
          ),
        ),

        /// Words Container
        CustomContainer(
          width: double.infinity,
          cir: 16,
          col: const Color(0xffF1F1F1),

          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: ListView.builder(
              itemCount: words.length,

              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final word = words[index];
                return _buildWordItem(
                  word['word'] ?? '',
                  word['translation'] ?? '',
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Word Item
  Widget _buildWordItem(String word, String translation) {
    return CustomContainer(
      col: AppColors.white,
      borders: true,
      borderCol: AppColors.offGray,
      cir: 10,
      margin: EdgeInsets.only(bottom: 7),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 4.w),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: word,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                0.2.h.height,
                CustomTextWidget(
                  title: translation,
                  fontSize: 13,
                  color: AppColors.gray,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
