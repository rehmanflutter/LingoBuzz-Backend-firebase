import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final Color? color;
  const CustomLoadingIndicator({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    //  return Center(child: Lottie.asset('assets/loader.json',repeat: true));
    return Center(
      child: SizedBox(
        height: 17,
        width: 17,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: color?? AppColors.white,
        ),
      ),
    );
  }
}
