import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lingobuzz/core/common/snackbar_utils.dart';
import '../app_text.dart';
import '../utils/Themes/app_color.dart';
import 'open_settings_helper.dart';


/// Mixin to handle app lifecycle events for widget confirmation
mixin WidgetSetupLifecycleHandler<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // User returned to app, check if we need to show widget confirmation
      WidgetSetupHelper.onAppResumed(context);
    }
  }
}



class WidgetSetupHelper {
  static const String _widgetAddedKey = 'widget_added';
  static const String _widgetPromptShownKey = 'widget_prompt_shown';
  static const String _widgetSetupCompletedKey = 'widget_setup_completed';

  static final storage = GetStorage();

  /// Check if user has completed widget setup
  static bool isWidgetSetupCompleted() {
    return storage.read(_widgetSetupCompletedKey) ?? false;
  }

  /// Mark widget setup as completed
  static Future<void> markWidgetSetupCompleted() async {
    await storage.write(_widgetSetupCompletedKey, true);
  }

  /// Check if widget prompt was shown
  static bool wasWidgetPromptShown() {
    return storage.read(_widgetPromptShownKey) ?? false;
  }

  /// Mark that widget prompt was shown
  static Future<void> markWidgetPromptShown() async {
    await storage.write(_widgetPromptShownKey, true);
  }

  /// User confirmed they added the widget
  static Future<void> markWidgetAsAdded() async {
    await storage.write(_widgetAddedKey, true);
    await markWidgetSetupCompleted();
  }

  /// Show widget setup dialog on first home screen visit
  static Future<void> showWidgetSetupPromptIfNeeded(BuildContext context) async {
    if (isWidgetSetupCompleted() || wasWidgetPromptShown()) {
      return;
    }

    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      await markWidgetPromptShown();
      await showWidgetSetupDialog(context);
    }
  }

  /// Show enhanced widget setup dialog
  static Future<void> showWidgetSetupDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.widgets_rounded,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: CustomTextWidget(
                title: 'Add Home Widget 🎯',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomTextWidget(
                title: 'Learn faster with LingoBuzz on your home screen!',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                Icons.auto_awesome,
                'See new words throughout the day',
              ),
              _buildFeatureItem(
                context,
                Icons.volume_up_rounded,
                'Quick audio playback',
              ),
              _buildFeatureItem(
                context,
                Icons.star_rounded,
                'Save favorites instantly',
              ),
              _buildFeatureItem(
                context,
                Icons.phone_android_rounded,
                'Available on home & lock screen',
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextWidget(
                        title: Platform.isAndroid
                            ? 'Tap the button below and we\'ll help you add the widget!'
                            : 'Tap below to see step-by-step instructions',
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              markWidgetSetupCompleted();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
            child: const CustomTextWidget(
              title: 'Maybe Later',
              fontSize: 14,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await openWidgetSettings(context);
            },
            icon: Icon(
              Platform.isAndroid ? Icons.add_circle_outline : Icons.arrow_forward_rounded,
              size: 20,
            ),
            label: CustomTextWidget(
              title: Platform.isAndroid ? 'Add Widget' : 'Show Me How',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build feature item
  static Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomTextWidget(
              title: text,
              fontSize: 14,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Open widget settings with enhanced UX
  static Future<void> openWidgetSettings(BuildContext context) async {
    try {
      final opened = await WidgetSettingsOpener.openWidgetSettings(context);

      if (opened && context.mounted) {
        // For Android, show success message and wait for user to return
        if (Platform.isAndroid) {
          SnackBarUtils.showSuccessSnackbar('Select LingoBuzz from the widget list');

          // Wait for user to come back from widget picker
          // Show confirmation dialog when app resumes
          _scheduleConfirmationDialog(context);
        }
      }
    } catch (e) {
      debugPrint('❌ Error opening widget settings: $e');

      if (context.mounted) {
        SnackBarUtils.showErrorSnackbar('Unable to open settings automatically. Please follow manual instructions.');
      }
    }
  }

  /// Schedule confirmation dialog to show when user returns to app
  static void _scheduleConfirmationDialog(BuildContext context) {
    // Store flag to show dialog when app resumes
    storage.write('show_widget_confirmation', true);

    // Set up listener for when app comes back to foreground
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowConfirmation(context);
    });
  }

  /// Check if we should show confirmation and show it
  static Future<void> _checkAndShowConfirmation(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final shouldShow = storage.read('show_widget_confirmation') ?? false;
    if (shouldShow && context.mounted) {
      await storage.write('show_widget_confirmation', false);
      await _showWidgetAddedConfirmation(context);
    }
  }

  /// Call this from your app's resume handler
  static Future<void> onAppResumed(BuildContext context) async {
    await _checkAndShowConfirmation(context);
  }

  /// Show enhanced confirmation dialog
  static Future<void> _showWidgetAddedConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: CustomTextWidget(
                title: 'Widget Added?',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomTextWidget(
              title: 'Did you successfully add the LingoBuzz widget to your home screen?',
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextWidget(
                      title: 'You can always add it later from Settings',
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Optionally show instructions again
              WidgetSettingsOpener.showManualInstructions(context);
            },
            icon: const Icon(Icons.help_outline, size: 18),
            label: const CustomTextWidget(
              title: 'Show Instructions',
              fontSize: 13,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              markWidgetAsAdded();
              Navigator.pop(context);
               SnackBarUtils.showSuccessSnackbar('Perfect! Enjoy your LingoBuzz widget 🎉');
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const CustomTextWidget(
              title: 'Yes, Added!',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Create an enhanced settings page widget component
  static Widget buildWidgetSettingsCard(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.widgets_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextWidget(
                          title: 'Home Screen Widget',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4),
                        CustomTextWidget(
                          title: 'Quick access to daily words',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CustomTextWidget(
                title: 'Learn new words right from your home screen. Get instant access to pronunciation and save your favorites without opening the app.',
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openWidgetSettings(context),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const CustomTextWidget(
                    title: 'Add Widget to Home Screen',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
