import 'package:flutter/material.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shimmer/shimmer.dart';

class TakeQuizLoadingWidget extends StatelessWidget {
  const TakeQuizLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(height: 18, width: 40.w),
          2.h.height,
          _shimmerBox(height: 12, width: 60.w),
          1.h.height,
          _shimmerBox(height: 12, width: 50.w),
          2.h.height,
          _shimmerBox(height: 14, width: double.infinity),
          1.h.height,
          _shimmerBox(height: 40, width: double.infinity, radius: 40),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    double height = 14,
    double width = 100,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
