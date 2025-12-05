import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/app_text.dart';
import '../utils/Themes/app_color.dart';

class AvatarImage extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final double fontSize;

  const AvatarImage({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _extractInitials(name);

    // ✅ No URL — show initials immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildInitialsAvatar(initials);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        backgroundImage: imageProvider,
        radius: radius,
      ),
      placeholder: (context, url) => _buildInitialsAvatar(initials),
      errorWidget: (context, url, error) => _buildInitialsAvatar(initials),
    );
  }

  /// Builds initials avatar for fallback/placeholder
  Widget _buildInitialsAvatar(String initials) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
      child: CustomTextWidget(
       title:  initials,
          color: AppColors.primaryColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Extracts initials from the given name
  String _extractInitials(String? name) {
    try {
      if (name == null || name.trim().isEmpty) return "U";
      final parts = name.trim().split(" ");
      if (parts.length == 1) return parts.first.characters.first.toUpperCase();
      return (parts.first.characters.first + parts.last.characters.first)
          .toUpperCase();
    } catch (_) {
      return "U";
    }
  }
}
