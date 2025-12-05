import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/AuthController/auth_controller.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/core/common/snackbar_utils.dart';
import 'package:lingobuzz/model/upgrade_plan_model.dart';
import '../../core/common/helpers/app_logger.dart';
import 'package:http/http.dart' as http;
import '../../core/common/stripe_keys.dart';
import '../../model/user_model.dart';

class UpgradeProController extends GetxController {

  final AuthController authController = Get.find<AuthController>();
  final WordController wordController = Get.put(WordController());

  RxInt selectedPlanIndex = 0.obs;
  RxBool isProcessingCardPayment = false.obs;
  RxBool isProcessingApplePayment = false.obs;
  List<UpgradePlanModel> proPlan = [
    UpgradePlanModel(
      title: 'Monthly Plan',
      price: 5.59,
      planLabel: '\$5.59 / month',
      billed: 'Billed monthly',
      save: '',
      description: 'Enjoy full, unlimited access with these features',
      features: [
        'Up to 10 words & phrases on notification, lockscreen and widget',
        'Choose topics you want to learn (travel, work, etc.)',
        'Save and replay every word and sentence',
        'Practice Test',
        'Priority support',
      ],
    ),
    UpgradePlanModel(
      title: '3-Month Plan',
      price: 14.97,
      planLabel: '\$4.99 / month',
      billed: 'Billed \$14.97 every 3 months',
      save: 'Save 17% compared to monthly',
      description: 'Enjoy full, unlimited access with these features',
      features: [
        'Up to 10 words & phrases on notification, lockscreen and widget',
        'Choose topics you want to learn (travel, work, etc.)',
        'Save and replay every word and sentence',
        'Practice Test',
        'Priority support',
      ],
    ),
    UpgradePlanModel(
      title: '6-Month Plan (Popular Choice)',
      price: 24.60,
      planLabel: '\$4.10 / month',
      billed: 'Billed \$24.60 every 6 months',
      save: 'Save 32% compared to monthly',
      isPopular: true,
      description: 'Enjoy full, unlimited access with these features',
      features: [
        'Up to 10 words & phrases on notification, lockscreen and widget',
        'Choose topics you want to learn (travel, work, etc.)',
        'Save and replay every word and sentence',
        'Practice Test',
        'Priority support',
      ],
    ),
    UpgradePlanModel(
      title: '1-Year Plan (Best Plan)',
      price: 42.00,
      planLabel: '\$3.50 / month',
      billed: 'Billed \$42.00 yearly',
      save: 'Save 42% compared to monthly',
      description: 'Enjoy full, unlimited access with these features',
      features: [
        'Up to 10 words & phrases on notification, lockscreen and widget',
        'Choose topics you want to learn (travel, work, etc.)',
        'Save and replay every word and sentence',
        'Practice Test',
        'Priority support',
      ],
    ),
  ];

  void onGooglePayResult(paymentResult) {
    if (paymentResult == paymentResult.success) {
      Log.debug("Payment Success: $paymentResult");
    } else {
      Log.debug("Payment failed: $paymentResult");
    }
  }

  // Create Payment Intent
  Future<Map<String, dynamic>?> createPaymentIntent(
      double amount,
      String currency,
      ) async {
    try {
      // Calculate amount in cents
      int amountInCents = (amount * 100).toInt();

      Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        Log.debug('❌ Error: ${response.body}');
        return null;
      }
    } catch (err) {
      Log.debug('❌ Error creating payment intent: $err');
      return null;
    }
  }

  /// ✅ Stack trace logger
  void _logStackTrace(String functionName) {
    try {
      final traceLines = StackTrace.current.toString().split('\n');
      if (traceLines.length > 2) {
        final match = RegExp(r'(\w+\.dart):(\d+):(\d+)').firstMatch(traceLines[2]);
        if (match != null) {
          final file = match.group(1);
          final line = match.group(2);
          Log.debug('📍 [$functionName] called from $file:$line');
          return;
        }
      }
      Log.debug('📍 [$functionName] call trace not available.');
    } catch (e) {
      Log.debug('⚠️ Stack trace parse error in $functionName: $e');
    }
  }

  Future<void> makeStripePayment() async {
    if (isProcessingCardPayment.value) return;

    try {
      isProcessingCardPayment.value = true;

      final userController = Get.find<AuthController>();
      final currentUser = userController.currentUser.value;
      final existingSubscriptions = currentUser?.subscription ?? [];

      // Check if user has any active subscription BEFORE payment
      final hasActiveSubscription = existingSubscriptions.any(
              (sub) => sub.endDate != null &&
              sub.endDate!.isAfter(DateTime.now())
      );

      // Selected plan
      final selectedPlan = proPlan[selectedPlanIndex.value];
      final price = selectedPlan.price;

      Log.debug('💳 Creating payment intent for \$${price.toStringAsFixed(2)}');
      Log.debug('🔍 Has active subscription: $hasActiveSubscription');

      // Step 1: Create Payment Intent
      final paymentIntent = await createPaymentIntent(price, 'USD');
      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }

      Log.debug('✅ Payment Intent created: ${paymentIntent['id']}');

      // Step 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: StripeConfig.merchantDisplayName,
          style: ThemeMode.light,
          billingDetailsCollectionConfiguration:
          const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
          ),
        ),
      );

      Log.debug('✅ Payment sheet initialized');

      // Step 3: Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();
      Log.debug('✅ Payment successful!');

      // ✅ Step 4: Process subscription after successful payment
      await _processSubscription(selectedPlan, paymentIntent['id'], hasActiveSubscription);

    } on StripeException catch (e) {
      Log.err('❌ Stripe Error: ${e.error.localizedMessage}');
      if (e.error.code != FailureCode.Canceled) {
        SnackBarUtils.showErrorSnackbar(
          e.error.localizedMessage ?? 'An error occurred',
        );
      }
    } catch (e) {
      Log.err('❌ Payment failed: $e');
      SnackBarUtils.showErrorSnackbar('Payment failed. Please try again.');
    } finally {
      isProcessingCardPayment.value = false;
    }
  }

  // Make Apple Pay Payment
  Future<void> makeApplePayPayment({String? selectedPrice}) async {
    if (isProcessingApplePayment.value) return;

    try {
      isProcessingApplePayment.value = true;

      final userController = Get.find<AuthController>();
      final currentUser = userController.currentUser.value;
      final existingSubscriptions = currentUser?.subscription ?? [];

      // Check if user has any active subscription BEFORE payment
      final hasActiveSubscription = existingSubscriptions.any(
              (sub) => sub.endDate != null &&
              sub.endDate!.isAfter(DateTime.now())
      );

      // Selected plan
      final selectedPlan = proPlan[selectedPlanIndex.value];
      final price = selectedPlan.price;

      Log.debug('🍎 Creating Apple Pay payment for \$${price.toStringAsFixed(2)}');
      Log.debug('🔍 Has active subscription: $hasActiveSubscription');

      // Step 1: Check if Apple Pay is supported
      final isApplePaySupported = await Stripe.instance.isPlatformPaySupported();
      if (!isApplePaySupported) {
        throw Exception('Apple Pay is not supported on this device');
      }

      // Step 2: Create Payment Intent
      final paymentIntent = await createPaymentIntent(price, 'USD');
      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }

      Log.debug('✅ Payment Intent created: ${paymentIntent['id']}');

      // Step 3: Present and Confirm Apple Pay Payment
      await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: paymentIntent['client_secret'],
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            cartItems: [
              ApplePayCartSummaryItem.immediate(
                label: selectedPlan.title,
                amount: price.toStringAsFixed(2),
              ),
            ],
          ),
        ),
      );

      Log.debug('✅ Apple Pay payment successful!');

      // ✅ Step 4: Process subscription after successful payment
      await _processSubscription(selectedPlan, paymentIntent['id'], hasActiveSubscription);

    } on StripeException catch (e) {
      Log.err('❌ Apple Pay Stripe Error: ${e.error.localizedMessage}');
      if (e.error.code != FailureCode.Canceled) {
        SnackBarUtils.showErrorSnackbar(
          e.error.localizedMessage ?? 'An error occurred',
        );
      }
    } catch (e) {
      Log.err('❌ Apple Pay payment failed: $e');
      SnackBarUtils.showErrorSnackbar(
        e.toString().contains('not supported')
            ? 'Apple Pay is not supported on this device'
            : 'Payment failed. Please try again.',
      );
    } finally {
      isProcessingApplePayment.value = false;
    }
  }

  /// ✅ Common subscription processing logic for both payment methods
  Future<void> _processSubscription(
      UpgradePlanModel selectedPlan,
      String paymentIntentId,
      bool hasActiveSubscription,
      ) async {
    final userController = Get.find<AuthController>();
    final currentUser = userController.currentUser.value;
    final existingSubscriptions = currentUser?.subscription ?? [];

    // ✅ Determine start & end dates
    final now = DateTime.now();

    // Find the latest subscription end date
    DateTime startDate = now;
    if (existingSubscriptions.isNotEmpty) {
      final latestEnd = existingSubscriptions
          .map((s) => s.endDate)
          .whereType<DateTime>()
          .fold<DateTime>(now, (prev, curr) => curr.isAfter(prev) ? curr : prev);
      if (latestEnd.isAfter(now)) {
        startDate = latestEnd; // chain next plan start
      }
    }

    late DateTime endDate;
    switch (selectedPlan.title) {
      case 'Monthly Plan':
        endDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
        break;
      case '3-Month Plan':
        endDate = DateTime(startDate.year, startDate.month + 3, startDate.day);
        break;
      case '6-Month Plan (Popular Choice)':
        endDate = DateTime(startDate.year, startDate.month + 6, startDate.day);
        break;
      case '1-Year Plan (Best Plan)':
        endDate = DateTime(startDate.year + 1, startDate.month, startDate.day);
        break;
      default:
        endDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
    }

    // ✅ Create new subscription object
    final newSubscription = SubscriptionModel(
      planId: selectedPlan.title.replaceAll(' ', '_').toLowerCase(),
      planName: selectedPlan.title,
      amount: selectedPlan.price,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      paymentIntentId: paymentIntentId,
    );

    // ✅ Combine with existing subscriptions
    final updatedSubscriptions = [
      ...existingSubscriptions,
      newSubscription,
    ];

    // ✅ Update user data - Pass whether this is a first-time upgrade
    await upgradeToPremium(
        updatedSubscriptions,
        isFirstTimeUpgrade: !hasActiveSubscription
    );

    Log.debug('⭐ User upgraded successfully');

    if (hasActiveSubscription) {
      SnackBarUtils.showSuccessSnackbar('Subscription extended successfully!');
    } else {
      SnackBarUtils.showSuccessSnackbar('Welcome to Premium! Enjoy 10 words per day!');
    }
  }

  Future upgradeToPremium(
      List<SubscriptionModel> subscription,
      {required bool isFirstTimeUpgrade}
      ) async {
    final currentUser = authController.currentUser;
    _logStackTrace('upgradeToPremium');

    int totalWordsLearned = (currentUser.value!.currentLearning!.totalWordsLearned ?? 0);
    Log.debug('Total words learned before upgrade: $totalWordsLearned');
    Log.debug('Is first time upgrade: $isFirstTimeUpgrade');

    if (currentUser.value?.currentLearning != null) {
      // Update words per day to 10 for premium
      final updatedLearning = currentUser.value?.currentLearning!.copyWith(
          wordsPerDay: 10
      );

      // Update user data with new subscription
      await authController.updateUserData(
        subscription: subscription,
        currentLearning: updatedLearning,
      );

      // Only fetch new words if this is the FIRST time upgrading to premium
      if (isFirstTimeUpgrade) {
        Log.debug('🆕 First time premium upgrade - fetching new words');
        authController.clearTodayWordsCache();
        await wordController.fetchWordList(upgradedToPremium: true);
      } else {
        Log.debug('🔄 Extending existing premium - not fetching new words');
      }
    }
  }

}