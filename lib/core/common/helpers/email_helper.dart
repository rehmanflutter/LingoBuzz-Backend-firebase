import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/app_info_controller.dart';
import 'app_logger.dart';

/// ✅ A helper class to send emails via Firebase Cloud Functions.
class EmailHelper {
  // Singleton instance
  final appInfoController = Get.find<AppInfoController>();
  static final EmailHelper _instance = EmailHelper._internal();
  factory EmailHelper() => _instance;
  EmailHelper._internal();

  // Firebase Functions instance (same region as deployed)
  final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: 'us-central1');

  /// ✅ Sends a welcome email using Cloud Function `sendWelcomeEmail`.
  Future<bool> sendWelcomeEmail({
    required String email,
    String? firstName,
  }) async {
    String sendEmailPassword = appInfoController.appInfo.value?.sendEmailPassword ?? 'N/A';
    String sendEmail = appInfoController.appInfo.value?.senderEmail ?? 'N/A';
    try {
      Log.debug('📧 Preparing to send welcome email...');
      Log.debug('📧 Email: $email');
      Log.debug('📧 First Name: $firstName');
      Log.debug('📧 Sender Password : ${sendEmailPassword}');
      Log.debug('📧 Sender Email: ${sendEmail}');
    // Sender Email: icyo sbkf iwxq bjjf<…>
    // Sender Password: khawajafareed0320@gmail.com<…>
      final callable = _functions.httpsCallable('sendWelcomeEmail');
      final result = await callable.call({
        'email': email.trim(),
        'firstName': firstName?.trim() ?? '',
        'senderPassword': appInfoController.appInfo.value?.sendEmailPassword ?? '',
        'senderEmail': appInfoController.appInfo.value?.senderEmail ?? '',
      });

      final data = result.data;
      if (data != null && data['success'] == true) {
        Log.info('✅ Welcome email sent successfully to $email');
        return true;
      } else {
        Log.warn('⚠️ Unexpected email send response: $data');
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      Log.err('❌ Firebase Functions error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      Log.err('❌ Unexpected error while sending email: $e');
      return false;
    }
  }
}
