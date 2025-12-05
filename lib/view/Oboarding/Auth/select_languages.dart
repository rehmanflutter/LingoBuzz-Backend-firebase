import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/model/language_model.dart';
import 'package:lingobuzz/view/Oboarding/widgets/oboarding_container.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../controller/languages_controller/language_controller.dart';

class SelectLanguages extends StatelessWidget {
  SelectLanguages({super.key});

  final languageController = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OboardingContainer(
          width: 75.w,
          title: 'What languages would you like to work with?',
        ),
        Center(
          child: CustomTextWidget(
            title: 'Select Languages',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        3.h.height,

        // ✅ Fixed Native Language Section (English only)
        CustomTextWidget(title: 'Your Native Language'),
        0.6.h.height,
        _buildFixedNativeLanguage(),

        2.h.height,

        // ✅ Learning Language Section (Dynamic excluding English)
        CustomTextWidget(title: 'Language to Learn'),
        0.6.h.height,
        Obx(
              () => _buildLanguageDropdown(
            value: languageController.learnLanguage.value,
            languages: languageController.languagesAvailable,
            onChanged: (language) {
              if (language != null) {
                languageController.setLearnLanguage(language,showLoading: true);
              }
            },
            hint: 'Select language to learn',
          ),
        ),
      ],
    );
  }

  /// ✅ Fixed Dropdown showing only English
  Widget _buildFixedNativeLanguage() {
    final native = languageController.nativeLanguage.value!;
    return Container(
      height: 6.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),
        border: Border.all(color: const Color(0xffE5E5E5)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      alignment: Alignment.centerLeft,
      child: CustomTextWidget(
        title: native.name ?? 'English',
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required LanguageModel? value,
    required List<LanguageModel> languages,
    required ValueChanged<LanguageModel?> onChanged,
    required String hint,
  }) {
    return Container(
      height: 6.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),
        border: Border.all(color: const Color(0xffE5E5E5)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LanguageModel>(
          value: value,

          // ✅ Selected item display fix
          selectedItemBuilder: (context) {
            return languages.map((lang) {
              final displayName =
              (lang.name == "Portuguese") ? "Portuguese (BR)" : (lang.name ?? '');

              return Align(
                alignment: Alignment.centerLeft,
                child: CustomTextWidget(
                  title: displayName,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              );
            }).toList();
          },

          hint: CustomTextWidget(
            title: hint,
            fontSize: 14,
            color: AppColors.gray,
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xffA6A6A6),
          ),
          dropdownColor: const Color(0xffFCFCFC),
          style: TextStyle(fontSize: 14, color: AppColors.gray),

          // ✅ Dropdown list display fix
          items: languages.map((LanguageModel language) {
            final displayName =
            (language.name == "Portuguese") ? "Portuguese (BR)" : (language.name ?? '');

            return DropdownMenuItem<LanguageModel>(
              value: language,
              child: CustomTextWidget(
                title: displayName,
                fontSize: 14,
                color: Colors.black87,
              ),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

}
