// import 'package:flutter/material.dart';
// import 'package:lingobuzz/core/utils/Themes/app_color.dart';

// class CustomProgressIndicator extends StatelessWidget {
//   final BuildContext context;
//   final double progress;
//   final Color? barColor;

//   const CustomProgressIndicator({
//     super.key,
//     required this.context,
//     required this.progress,
//     this.barColor = const Color(0xff57BA89),
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.zero,
//       width: double.infinity,
//       height: 10,
//       decoration: BoxDecoration(
//         color: AppColors.lightGray,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: AppColors.lightGray),
//       ),
//       child: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
//           ),
//           LayoutBuilder(
//             builder: (context, constraints) {
//               return Container(
//                 width: constraints.maxWidth * progress,
//                 decoration: BoxDecoration(
//                   // color: AppColors.primaryColor,
//                   borderRadius: BorderRadius.circular(10),
//                   gradient: LinearGradient(
//                     colors: [barColor!, barColor!],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double progress; // can be 0.0–1.0 or 1–totalSteps
  final int totalSteps; // total number of steps (e.g. 5)
  final Color? barColor;

  const CustomProgressIndicator({
    super.key,
    required this.progress,
    required this.totalSteps,
    this.barColor = const Color(0xff57BA89),
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Automatically detect whether 'progress' is a fraction or step count
    final double percentage = progress > 1
        ? (progress / totalSteps).clamp(0.0, 1.0)
        : progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * percentage,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [barColor!, barColor!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
