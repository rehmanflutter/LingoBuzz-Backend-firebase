import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:lingobuzz/core/common/utils/app_images.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../view/Home/home_screen.dart';
import '../../../view/MyWords/my_words.dart';
import '../../../view/Settings/setting.dart';
import '../../../view/UpgradePro/upgrade_pro.dart';
import '../widgets/custamContainer.dart';

class BottomNavController extends GetxController {
  RxInt selectedIndex = 0.obs;

  final List screens = [
    HomeScreen(),
    MyWords(),
    UpgradePro(),
    Setting(),
  ];

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}
class BottomAppBarScreen extends StatelessWidget {
  const BottomAppBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BottomNavController());

    return Scaffold(
      body: Obx(() => Center(
        child: controller.screens[controller.selectedIndex.value],
      )),
      bottomNavigationBar: CustomContainer(
        height: 11.h,
        col: AppColors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 0.w), // no horizontal padding, let Expanded handle spacing
          child: Obx(() => Row(
            children: [
              Expanded(
                child: _buildNavItem(
                    controller, 0, 'Home', AppImages.home, AppImages.homefill),
              ),
              Expanded(
                child: _buildNavItem(controller, 1, 'My words', AppImages.myWorld,
                    AppImages.myWorld),
              ),
              Expanded(
                child: _buildNavItem(controller, 2, 'Upgrade to Pro', AppImages.pro,
                    AppImages.proFill),
              ),
              Expanded(
                child: _buildNavItem(controller, 3, 'Settings', AppImages.setting,
                    AppImages.setting),
              ),
            ],
          )),
        ),
      ),

    );
  }

  Widget _buildNavItem(
      BottomNavController controller,
      int index,
      String title,
      String iconPath,
      String fillIconPath,
      ) {
    final isSelected = controller.selectedIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        height: 11.h,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isSelected ? fillIconPath : iconPath,
              color: isSelected ? AppColors.primaryColor : AppColors.gray,
            ),
            1.h.height,
            CustomTextWidget(
              title: title,
              fontSize: 12,
              color: isSelected ? AppColors.primaryColor : AppColors.gray,
            ),
            2.h.height,
          ],
        ),
      ),
    );
  }
}
