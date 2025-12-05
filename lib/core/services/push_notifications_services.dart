import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../common/helpers/app_logger.dart';

class PushNotificationService {
  static final box = GetStorage();

  /// ✅ Fetch a fresh access token from Google using the Lingo Buzz service account
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "lingo-buzz",
      "private_key_id": "1e426cf316ac2feadfd3988ea50a7d36aada6e2d",
      "private_key":
      "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC6XD394BmwE3xp\ns8rB1VJE+ojxKI88v2IIVPLb8kgI1MQpGvuFHnanY6WBVU8RqLwYm5HO2m/6Tund\nWNfhjpVtagwSn3n1KT9dToiG+ivUNSsctmLCE850uevP+oAXE8WwEQP4dF9XehNN\nFJZ6J+qGePA3VhlA2rT4cb349/msA4Q5DIuTBpeL3x9z941ZyYnXXpTxLvDCAcaS\nXknVZjbK85pkwzlmfItXKO5OYMbgtJBlaONfJdmFDttdmpMGVNLkknghyRh5nBwK\nys/HdW0Dm1A1NYljC6BPQlTJy7zSgXWMCMFHUUDE3m97Grh/gL6KBLuWWIDM7YL2\nkYhgXv8DAgMBAAECggEABQznTbafgf4h/xSsm0XlTKuGSANZ+qlF6GL2kSKzsB9y\nZgBhh6vRWAp+8wGZtn6aFH9PEt9KmB3q92EFD6UQ1VvsTdWykwP2JmEfmWc9jtWO\nCRSQiP7cSJ1m3IqkxRTvOfnQVyH6XVi6lU+VDkJMq2F3yzo/53w9UUpUW7iX3zy9\nDUSU34wO+1Os/NJvflyZl5C+Cmc7pluO2wVX8DFuh9v7Gc86LY29CnI/xDxwrIIG\nzrGtdEHDUy1PdQFkplULPrat/SmFr16xTCTZzHF8NWFFAloDmo4sO/WMcuulsDUP\nuC38C5070w2sa6jDDOnabc7JsyI/R1sFobdOcev0UQKBgQDekbntSEI6k2eG55/E\n+6lqW1sUeXE6KWxG3keO3nomiL8L08WeMqsgw3RZIgtosn3FXXGizBY8VL8MiEgc\nQRecRJg7pGq99R2CN0dQ8vHv41LsNUNKr4DuaunSrvoI0xec8ooYUzaD1WmFdaqb\nLbm/c7r/ud6xV06GuEzPbM8NGwKBgQDWWjQlcmLeTbZO/ppn+kqGkV2CwziAkIfB\ndm0m9mDzqHD072IQKz/AIVyR2vYdYhvVBszr3meW3WhdQSZeZw4S3YuSLdEZtYik\nd895dGFW8uMU9e4ZpJLueAhimH6IpvLHYi21Q16N9mFljs4AE8XrPDQlRErM1fLn\nnItJ7oR8OQKBgQC0wpHIPolbXWAVVoSRzPo44N1F8aOd4wqHO/vN8q4uIZ1Xk7TJ\n2MjXISabRWUSsPQomM2ztCDS+tj26q/2En+EcMlalxwCDtLacN7Axa7sbylnoZJ3\nU7ZY7AffDjEPfbGNzAWP3/VEeMzskTXwNeDHtsxG6MQOL6QdEg1/4RT/xQKBgFbb\nXl3+J8nku4bu7CpN5Xz50mZ2LKML7babAkfTdh3Fl1/o0Fe07rQv0I7ZpvjpFFYR\n11+MU3VyaiO/joiaQb2rQC8PmbdNM/1Q/yU732WYLiQEM2L4qQEwalVpbXx6Cc55\nHgRhNCNaPsUkRJ0LZhuX3ZlsPtMZrr/jUx22JMEhAoGBAJyfdhZxiAiij6az0tnX\nc476vSP4v87e2I2ExtEnnwiopaOYDTz4rB1Axec8XWLm4wj0owr+QZBbJMV8Yx3O\n9HR0ZuJmubdo5rLrYbUM/N3pnRvIo6rcG1LJz5AMsGeAHuJpDoHnLnXcmQs7g9u/\n7vF2bZuGHFPSX+z59X2YpxNd\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@lingo-buzz.iam.gserviceaccount.com",
      "client_id": "103800364683946394389",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
      "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40lingo-buzz.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    final scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
    final client = await auth.clientViaServiceAccount(credentials, scopes);

    final accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
      credentials,
      scopes,
      client,
    );

    client.close();
    return accessCredentials.accessToken.data;
  }

  /// ✅ Send push notification using Firebase Cloud Messaging (v1) with custom sound
  static Future<void> sendPushNotification(String title, String description) async {

    final showNotifications = box.read('pushNotifications') ?? true;
    Log.debug('Show Notifications: $showNotifications');
    if(!showNotifications){
      return;
    }


    try {
      final serverKey = await getAccessToken();
      final deviceToken = box.read('fcm_token');

      if (deviceToken == null) {
        Log.err('❌ Device token not found — cannot send push notification.');
        return;
      }

      const String endpoint = 'https://fcm.googleapis.com/v1/projects/lingo-buzz/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': description,
          },
          'data': {
            'title': title,
            'body': description,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'lingobuzz_channel',
              'sound': 'notification', // Custom sound (without extension)
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': description},
                'sound': 'notification.wav', // Custom sound for iOS (with extension)
                'badge': 1,
              }
            }
          }
        }
      };

      Log.debug('🚀 Sending push notification to token: $deviceToken');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        Log.debug('✅ Notification sent successfully!');
      } else {
        Log.err('❌ Failed to send notification: ${response.statusCode} | ${response.body}');
      }
    } catch (e, s) {
      Log.err('⚠️ Error sending notification: $e');
      Log.err('Stacktrace: $s');
    }
  }
}