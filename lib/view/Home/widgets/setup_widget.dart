import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/app_text.dart';

import '../../../core/common/utils/Themes/app_color.dart';

class HowToSetupWidgetTile extends StatelessWidget {
  final VoidCallback onTap;

  const HowToSetupWidgetTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border.all(
            color: AppColors.primaryColor,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.widgets_rounded,
                size: 20,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 16),

            // Texts
            CustomTextWidget(
             title:  "Setup Widgets",
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            Spacer(),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
