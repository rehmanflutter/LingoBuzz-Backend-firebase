import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';

class CustomContainer extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? col;
  final Widget? child;
  final double? cir;
  final bool? borders;
  final Color? borderCol;
  final bool grading;
  final VoidCallback? onTap;
  final bool? shadow;
  final DecorationImage? imageDecoration;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final double? borderWidth;
  final BoxConstraints? boxConstraints;

  CustomContainer({
    this.height,
    this.width,
    this.child,
    this.col,
    this.borders = false,
    this.cir = 1,
    this.borderCol = AppColors.lightGray,
    this.grading = false,
    this.onTap,
    this.shadow,
    this.imageDecoration,
    this.boxConstraints,
    this.margin,
    this.radius = 2,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: boxConstraints,
        height: height,
        width: width,
        margin: margin, // Set margin around the container
        decoration: BoxDecoration(
          boxShadow: shadow == true
              ? [
                  BoxShadow(
                    color: Colors
                        .grey
                        .shade200, // Colors.grey.withOpacity(0.3), // Shadow color
                    spreadRadius: 1, // The extent of the shadow
                    blurRadius: 5, // The blurring of the shadow
                    offset: const Offset(0, 1), // Positioning of the shadow
                  ),
                ]
              : null,
          color: grading ? null : col,
          // gradient: grading
          //     ? RadialGradient(
          //         colors: [AppColors.primaryColor2, AppColors.black],
          //         radius: radius!,
          //         // center: Alignment(0, -0.1),
          //       )
          //     : null,
          border: borders == true
              ? Border.all(color: borderCol!, width: borderWidth!)
              : null,

          borderRadius: BorderRadius.circular(cir!),
          image: imageDecoration, // Use the provided imageDecoration
        ),
        child: Center(child: child),
      ),
    );
  }
}
