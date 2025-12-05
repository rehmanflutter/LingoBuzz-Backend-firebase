import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/widgets/custom_loading_indicator.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'custamContainer.dart';

class MainCustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? col;
  final Color? textColor;
  final Color? backColour;
  final bool? loading;
  final double? width;
  final double? height;

  const MainCustomButton({super.key,
    required this.title,
    required this.onTap,
    this.col,
    this.textColor = Colors.black,
    this.loading = false,
    this.backColour = AppColors.primaryColor,
    this.width,
    this.height = 6,
  });
  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      height: height!.h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading==true? (){}: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: AppColors.primaryColor,
          backgroundColor: backColour,
          minimumSize: Size(double.infinity, 7.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child:
        loading==true?  CustomLoadingIndicator():
        CustomTextWidget(
          title: title,
          color: textColor!,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
