import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;
  BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xff62e2e6), AppColors.black],
          radius: 1.4,
          // center: Alignment(0, -0.1),
        ),
      ),
      child: child,
    );
    // Container(
    //   height: double.infinity,
    //   width: double.infinity,
    //   decoration: BoxDecoration(
    //     image: DecorationImage(
    //       image: AssetImage(AppImages.backImages),
    //       fit: BoxFit.fill,
    //     ),
    //   ),
    //   child: child,
    // );
  }
}
