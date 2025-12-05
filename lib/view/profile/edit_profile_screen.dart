import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/common/widgets/custom_Button.dart';
import 'package:lingobuzz/core/common/widgets/custom_image_widget.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../controller/AuthController/auth_controller.dart';
import '../../core/common/app_text.dart';
import '../../core/common/snackbar_utils.dart';
import '../../core/common/utils/Themes/app_color.dart';
import '../../core/common/utils/text_field_custam.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage; // locally picked image

  @override
  void initState() {
    super.initState();
    controller.firstNameController.text =
        controller.currentUser.value?.firstName ?? '';
    controller.lastNameController.text =
        controller.currentUser.value?.lastName ?? '';
    controller.emailController.text =
        controller.currentUser.value?.email ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // ✅ Optionally, call your API here:
        // await controller.uploadProfileImage(_selectedImage);
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackbar('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            2.h.height,
            _buildProfileImageSection(),
            3.h.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          title: 'First Name',
                          hintText: 'First Name',
                          controller: controller.firstNameController,
                        ),
                      ),
                      2.w.width,
                      Expanded(
                        child: CustomTextField(
                          title: 'Last Name',
                          hintText: 'Last Name',
                          controller: controller.lastNameController,
                        ),
                      ),
                    ],
                  ),
                  1.h.height,
                  CustomTextField(
                    readOnly: true,
                    title: 'Email Address',
                    hintText: 'exampleuser@gmail.com',
                    controller: controller.emailController,
                  ),
                  2.h.height,
                  Obx(
                        () => MainCustomButton(
                      loading: controller.isLoading.value,
                      title: 'Save',
                            onTap: () async {
                              String? uploadedUrl;
                              // ✅ Check if local image picked
                              if (_selectedImage != null) {
                                uploadedUrl = await controller.uploadProfileImage(_selectedImage!.path);
                              }
                              if(uploadedUrl == null && _selectedImage != null){
                                // If upload failed
                                uploadedUrl= controller.currentUser.value?.image;
                                SnackBarUtils.showErrorSnackbar('Image upload failed. Please try again.');
                                return;
                              }
                              // ✅ Now update profile data with imageUrl (if uploaded)
                              final response = await controller.updateUserData(
                                firstName: controller.firstNameController.text,
                                lastName: controller.lastNameController.text,
                                email: controller.emailController.text,
                                image: uploadedUrl,
                              );
                              if (response) {
                                SnackBarUtils.showSuccessSnackbar('Profile Updated Successfully');
                              }
                            }
                        ),
                  ),
                  3.h.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        6.h.height,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back, color: AppColors.black),
              ),
              const CustomTextWidget(
                title: 'Edit Profile',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              SizedBox(width: 10.w),
            ],
          ),
        ),
        Divider(color: AppColors.offGray),
        1.h.height,
      ],
    );
  }

  Widget _buildProfileImageSection() {
    final user = controller.currentUser.value;
    final imageUrl = user?.image;
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';

    // Create initials like "AA"
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();

    // Determine which image to show
    String? displayImageUrl;
    if (_selectedImage != null) {
      // Local image picked
      displayImageUrl = _selectedImage!.path;
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      // Existing user image (Firebase or web)
      displayImageUrl = imageUrl;
    }

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // ✅ Avatar with initials + safe fallback
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 2),
            ),
            child: ClipOval(
              child: _selectedImage != null
              // ✅ Show picked local image
                  ? Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              )
              // ✅ Otherwise use SafeAvatar (handles network & initials)
                  : AvatarImage(
                imageUrl: displayImageUrl,
                name: "$firstName $lastName",
                radius: 50,
                fontSize: 32,
              ),
            ),
          ),

          // ✏️ Edit icon overlay
          Positioned(
            bottom: 5,
            right: 5,
            child: InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
