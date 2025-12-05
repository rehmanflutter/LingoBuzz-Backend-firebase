import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_text.dart';
import '../utils/Themes/app_color.dart';

class WidgetSettingsOpener {
  static const MethodChannel _channel = MethodChannel('com.lingobuzz.app/widget_settings');

  /// Open widget picker/configuration directly
  static Future<bool> openWidgetSettings(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        return await _openAndroidWidgetPicker(context);
      } else if (Platform.isIOS) {
        return await _openIOSWidgetSettings(context);
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error opening widget settings: $e');
      if (context.mounted) {
        await showManualInstructions(context);
      }
      return false;
    }
  }

  /// Android: Open widget picker directly
  static Future<bool> _openAndroidWidgetPicker(BuildContext context) async {
    try {
      debugPrint('📱 Attempting to open Android widget picker...');

      final result = await _channel.invokeMethod('openWidgetPicker');

      if (result == true) {
        debugPrint('✅ Successfully opened Android widget picker');
        return true;
      } else {
        debugPrint('⚠️ Widget picker not opened, showing instructions');
        if (context.mounted) {
          await showManualInstructions(context);
        }
        return true; // Still return true since we showed instructions
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Platform exception: ${e.message}');
      if (context.mounted) {
        await showManualInstructions(context);
      }
      return true; // Instructions shown
    } catch (e) {
      debugPrint('❌ Failed to open Android widget picker: $e');
      if (context.mounted) {
        await showManualInstructions(context);
      }
      return true; // Instructions shown
    }
  }

  /// iOS: Show instructions (can't open programmatically)
  static Future<bool> _openIOSWidgetSettings(BuildContext context) async {
    if (context.mounted) {
      await showManualInstructions(context);
    }
    return true;
  }

  /// Show enhanced manual instructions
  static Future<void> showManualInstructions(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8, // ⭐ Prevent overflow
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Platform.isAndroid
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.grey.shade700, Colors.grey.shade900],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Platform.isAndroid ? Icons.android : Icons.apple,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: CustomTextWidget(
                          title: 'How to Add Widget',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (Platform.isAndroid) ...[
                          _buildInstructionSection(
                            'Home Screen Widget',
                            [
                              _InstructionStep(
                                number: '1',
                                text: 'Long press on an empty space on your home screen',
                                icon: Icons.touch_app,
                              ),
                              _InstructionStep(
                                number: '2',
                                text: 'Tap "Widgets" from the bottom menu',
                                icon: Icons.widgets,
                              ),
                              _InstructionStep(
                                number: '3',
                                text: 'Scroll down and find "LingoBuzz"',
                                icon: Icons.search,
                              ),
                              _InstructionStep(
                                number: '4',
                                text: 'Long press the widget and drag it to your home screen',
                                icon: Icons.open_with,
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildInstructionSection(
                            'Home Screen Widget',
                            [
                              _InstructionStep(
                                number: '1',
                                text: 'Long press on an empty space on your home screen',
                                icon: Icons.touch_app,
                              ),
                              _InstructionStep(
                                number: '2',
                                text: 'Tap the "+" button in the top-left corner',
                                icon: Icons.add_circle_outline,
                              ),
                              _InstructionStep(
                                number: '3',
                                text: 'Search for "LingoBuzz" or scroll to find it',
                                icon: Icons.search,
                              ),
                              _InstructionStep(
                                number: '4',
                                text: 'Tap "Add Widget" to place it on your home screen',
                                icon: Icons.check_circle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                          _buildInstructionSection(
                            'Lock Screen Widget (iOS 16+)',
                            [
                              _InstructionStep(
                                number: '1',
                                text: 'Long press on your lock screen',
                                icon: Icons.lock_clock,
                              ),
                              _InstructionStep(
                                number: '2',
                                text: 'Tap "Customize" at the bottom',
                                icon: Icons.edit,
                              ),
                              _InstructionStep(
                                number: '3',
                                text: 'Tap on the widget area to add widgets',
                                icon: Icons.touch_app,
                              ),
                              _InstructionStep(
                                number: '4',
                                text: 'Find and add the LingoBuzz widget',
                                icon: Icons.add,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10)
                      ],
                    ),
                  ),
                ),

                // Footer button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Platform.isAndroid
                            ? Colors.green.shade600
                            : Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const CustomTextWidget(
                        title: 'Got it!',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  static Widget _buildInstructionSection(String title, List<_InstructionStep> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: title,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        const SizedBox(height: 16),
        ...steps.map((step) => _buildStepWidget(step)),
      ],
    );
  }

  static Widget _buildStepWidget(_InstructionStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: CustomTextWidget(
                title: step.number,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      step.icon,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CustomTextWidget(
                        title: step.text,
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep {
  final String number;
  final String text;
  final IconData icon;

  _InstructionStep({
    required this.number,
    required this.text,
    required this.icon,
  });
}
