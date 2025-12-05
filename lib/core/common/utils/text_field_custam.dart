import 'package:flutter/material.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import 'package:lingobuzz/core/common/utils/Themes/app_color.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CustomTextField extends StatelessWidget {
  String? title;

  final String hintText;
  final String? labelText;
  final Widget? startIcon;
  final Widget? lastIcon;
  final bool? obscur;
  final VoidCallback? fun;
  final bool? focus;
  final bool isValid;
  final bool? boarder;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final int? maxline;
  final bool filled;
  final bool readOnly;
  final Function(String)? onChanged;

   CustomTextField({
    super.key,
    this.title,
    required this.hintText,
    this.controller,
    this.labelText,
    this.lastIcon,
    this.obscur = false,
    this.startIcon,
    this.keyboardType,
    this.fun,
    this.focus = false,
    this.isValid = true,
    this.boarder = false,
    this.maxline = 1,
    this.filled = true,
    this.readOnly = false,
    this.onChanged,
  });

  OutlineInputBorder _getBorder(bool isValid) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isValid
            ? AppColors.primaryColor
            : isValid == false
            ? Colors.red
            : Colors.grey,
        //  width: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title!=null?Padding(
          padding:  EdgeInsets.only(bottom: 0.3.h),
          child: CustomTextWidget(
            title: " $title",
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ):SizedBox.shrink(),
        SizedBox(
          height: 5.7.h,
          child: TextField(
            readOnly: readOnly,
            autofocus: focus!,
            obscureText: obscur!,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14,fontFamily: 'nunito'),
            controller: controller,
            cursorColor: AppColors.primaryColor,
            maxLines: maxline,
            onChanged: onChanged,
            decoration: InputDecoration(
              suffixIcon: lastIcon,
              prefixIcon: startIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 0,
              ),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black54,fontFamily: 'nunito'),
              filled: filled,
              fillColor: Color(0xffFCFCFC), //fillColorShow! ? fillColor : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE5E5E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE5E7EB)),
              ),
              focusedBorder: _getBorder(isValid),
            ),
          ),
        ),
      ],
    );
  }
}



// void validateInput() {
//     setState(() {
//       controller.isEmailValid = RegExp(
//         r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
//       ).hasMatch(controller.email.text.trim());
//       controller.isPasswordValid = controller.password.text.trim().length >= 6;
//     });
//   }



  // bool isEmailValid = true;
  // bool isPasswordValid = true;
//  CustomTextField(
//                 controller: controller.email,
//                 hintText: 'Enter Your Email',
//                 keyboardType: TextInputType.emailAddress,
//                 isValid: controller.isEmailValid,
//                 onChanged: (_) => validateInput(),
//               ),