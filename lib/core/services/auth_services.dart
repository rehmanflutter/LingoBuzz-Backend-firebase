import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../model/user_model.dart';
import '../../model/language_model.dart';
import '../common/helpers/app_logger.dart';
import '../common/snackbar_utils.dart';

class AuthServices {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return bytes.toString();
  }

  /// ✅ NEW: Check if user has previous learning data for a language
  static Future<LearningLanguageModel?> getPreviousLanguageLearning({
    required String languageName,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        Log.debug('⚠️ No user logged in');
        return null;
      }

      Log.debug('🔍 Checking for previous learning data: $languageName');

      final docSnapshot = await _firestore
          .collection('app_users')
          .doc(uid)
          .collection('languages')
          .doc(languageName)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        Log.debug('✅ Found previous learning data for $languageName');
        return LearningLanguageModel.fromMap(docSnapshot.data()!);
      }

      Log.debug('ℹ️ No previous learning data found for $languageName');
      return null;
    } catch (e, st) {
      Log.debug('❌ Error getting previous language learning: $e\n$st');
      return null;
    }
  }

  /// ✅ CRITICAL FIX: Switch to a new learning language with proper cache management
  static Future<Map<String, dynamic>> switchLearningLanguage({
    required String languageId,
    required String languageName,
    String? defaultLevel,
    int? defaultWordsPerDay,
    int? defaultContentType,
    bool preserveLastPractice = true, // ✅ NEW: Control whether to preserve lastPracticeAt
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        return {'success': false, 'message': 'No logged-in user found.'};
      }

      Log.debug('🔄 Switching language to: $languageName');
      Log.debug('   - Preserve last practice: $preserveLastPractice');
      Log.debug('   - Words per day: $defaultWordsPerDay');

      // Step 1: Get current user data
      final currentUser = await getUserModel(uid);

      // ✅ CRITICAL: Save current learning to its subcollection (if exists and different)
      if (currentUser?.currentLearning != null) {
        final currentLearning = currentUser!.currentLearning!;

        if (currentLearning.languageName != null &&
            currentLearning.languageName != languageName) {

          Log.debug('💾 Saving current progress for ${currentLearning.languageName}');
          Log.debug('   - Last practice: ${currentLearning.lastPracticeAt}');
          Log.debug('   - Total words: ${currentLearning.totalWordsLearned}');

          // ✅ Save complete state to subcollection
          await _firestore
              .collection('app_users')
              .doc(uid)
              .collection('languages')
              .doc(currentLearning.languageName)
              .set({
            ...currentLearning.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          Log.debug('✅ Saved progress for ${currentLearning.languageName}');
        }
      }

      // Step 2: Check if user has previous data for new language
      final previousLearning = await getPreviousLanguageLearning(
        languageName: languageName,
      );

      LearningLanguageModel newLearning;
      bool isNewLanguage = previousLearning == null;
      DateTime? effectiveLastPractice;

      if (previousLearning != null) {
        // ✅ Restore previous learning data
        Log.debug('♻️ Restoring previous learning data for $languageName');
        Log.debug('   - Previous last practice: ${previousLearning.lastPracticeAt}');
        Log.debug('   - Previous total words: ${previousLearning.totalWordsLearned}');

        newLearning = previousLearning;

        // ✅ CRITICAL: Update words per day if changed (e.g., upgraded to premium)
        if (defaultWordsPerDay != null && defaultWordsPerDay != previousLearning.wordsPerDay) {
          Log.debug('📊 Updating words per day: ${previousLearning.wordsPerDay} → $defaultWordsPerDay');
          newLearning = newLearning.copyWith(
            wordsPerDay: defaultWordsPerDay,
          );
        }

        // ✅ Preserve lastPracticeAt from previous learning
        effectiveLastPractice = previousLearning.lastPracticeAt;
      } else {
        // ✅ Create new learning data
        Log.debug('🆕 Creating new learning data for $languageName');

        final level = defaultLevel ?? 'A1';

        // Create initial level progress
        final initialLevelProgress = LevelProgressModel(
          levelName: level,
          startedAt: DateTime.now(),
          categoryProgress: [],
          selectedCategories: [],
        );

        newLearning = LearningLanguageModel(
          id: languageId,
          languageName: languageName,
          currentLevel: level,
          wordsPerDay: defaultWordsPerDay ?? 3,
          contentType: defaultContentType ?? 2,
          totalWordsLearned: 0,
          totalSentencesLearned: 0,
          levelProgress: [initialLevelProgress],
          type: 'learning',
          startedAt: DateTime.now(),
          lastPracticeAt: null, // ✅ New language has no practice yet
        );

        effectiveLastPractice = null;
      }

      // ✅ CRITICAL DECISION: Set lastPracticeAt based on preserveLastPractice flag
      final finalLastPractice = preserveLastPractice
          ? effectiveLastPractice
          : null;

      Log.debug('🎯 Final last practice date: $finalLastPractice');
      Log.debug('   - Preserved from previous: $preserveLastPractice');
      Log.debug('   - Is new language: $isNewLanguage');

      // ✅ Update with final lastPracticeAt
      newLearning = newLearning.copyWith(
        lastPracticeAt: finalLastPractice,
      );

      // Step 3: Update current_learning in main user document
      await _firestore.collection('app_users').doc(uid).update({
        'current_learning': newLearning.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 4: Ensure language subcollection document exists
      await _firestore
          .collection('app_users')
          .doc(uid)
          .collection('languages')
          .doc(languageName)
          .set({
        ...newLearning.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.debug('✅ Successfully switched to $languageName');
      Log.debug('   - Words per day: ${newLearning.wordsPerDay}');
      Log.debug('   - Last practice: ${newLearning.lastPracticeAt}');

      final updatedUser = await getUserModel(uid);

      return {
        'success': true,
        'message': 'Language switched successfully!',
        'user': updatedUser,
        'isNewLanguage': isNewLanguage,
        'cachePreserved': preserveLastPractice,
        'lastPracticeAt': finalLastPractice?.toIso8601String(),
      };
    } catch (e, st) {
      Log.debug('❌ Error switching language: $e\n$st');
      return {
        'success': false,
        'message': 'Error switching language: ${e.toString()}',
      };
    }
  }

  /// ✅ NEW: Get all languages user has learned or is learning
  static Future<List<String>> getUserLanguages() async {
    try {
      final uid = currentUserId;
      if (uid == null) return [];

      final snapshot = await _firestore
          .collection('app_users')
          .doc(uid)
          .collection('languages')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      Log.debug('❌ Error getting user languages: $e');
      return [];
    }
  }

  /// ------------------------ CREATE ACCOUNT ------------------------
  static Future<Map<String, dynamic>> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    LanguageModel? nativeLanguage,
    LearningLanguageModel? currentLearning,
    String? fcmToken,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed.");

      // ✅ Initialize level progress if currentLearning is provided
      LearningLanguageModel? initializedLearning;
      if (currentLearning != null) {
        final currentLevel = currentLearning.currentLevel ?? 'A1';
        final currentCategory = currentLearning.currentCategory ?? '';

        // Create initial level progress
        final initialLevelProgress = LevelProgressModel(
          levelName: currentLevel,
          startedAt: DateTime.now(),
          categoryProgress: currentCategory.isNotEmpty
              ? [
            CategoryProgressModel(
              categoryName: currentCategory,
              categoryId: _generateCategoryId(currentCategory),
              startedAt: DateTime.now(),
            )
          ]
              : [],
        );

        initializedLearning = currentLearning.copyWith(
          levelProgress: [initialLevelProgress],
          totalWordsLearned: 0,
          totalSentencesLearned: 0,
        );
      }

      final data = {
        'uid': user.uid,
        'first_name': firstName,
        'last_name': lastName,
        'email': email.trim(),
        'image': null,
        'native_language': nativeLanguage?.toJson(),
        'current_learning': initializedLearning?.toMap(),
        'learned_languages': [],
        'password_hash': _hashPassword(password),
        'subscription': null,
        'fcm_token': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('app_users').doc(user.uid).set(data);

      // ✅ Create language subcollection document
      if (initializedLearning != null) {
        await _firestore
            .collection('app_users')
            .doc(user.uid)
            .collection('languages')
            .doc(initializedLearning.languageName)
            .set({
          ...initializedLearning.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final userModel = await getUserModel(user.uid);

      return {
        'success': true,
        'message': 'Account created successfully!',
        'user': userModel,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _handleAuthError(e)};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  /// ✅ Update user data with category progress tracking
  static Future<Map<String, dynamic>> updateUserData({
    String? firstName,
    String? lastName,
    String? email,
    String? image,
    String? fcmToken,
    LanguageModel? nativeLanguage,
    LearningLanguageModel? currentLearning,
    List<LearningLanguageModel>? learnedLanguages,
    List<SubscriptionModel>? subscription,
  }) async {
    Log.debug('Current learning to update in services: ${currentLearning?.toMap()}');
    try {
      final uid = currentUserId;
      if (uid == null) {
        return {'success': false, 'message': 'No logged-in user found.'};
      }

      final Map<String, dynamic> updateData = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (image != null) 'image': image,
        if (fcmToken != null) 'fcm_token': image,
        if (nativeLanguage != null) 'native_language': nativeLanguage.toJson(),
        if (learnedLanguages != null)
          'learned_languages': learnedLanguages.map((e) => e.toMap()).toList(),
        if (subscription != null)
          'subscription': subscription.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ Handle currentLearning update (including nested progress)
      if (currentLearning != null) {
        updateData['current_learning'] = currentLearning.toMap();
      }

      if (updateData.length <= 1) {
        return {'success': false, 'message': 'No fields provided to update.'};
      }

      Log.debug('Updating user data for $uid: $updateData');

      // 🔥 Perform document update
      await _firestore.collection('app_users').doc(uid).update(updateData);

      // ✅ Update language subcollection
      if (currentLearning != null && currentLearning.languageName != null) {
        Log.debug('Updating language subcollection for $uid');
        await _firestore
            .collection('app_users')
            .doc(uid)
            .collection('languages')
            .doc(currentLearning.languageName)
            .set({
          ...currentLearning.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final updatedUser = await getUserModel(uid);
      return {
        'success': true,
        'message': 'User updated successfully!',
        'user': updatedUser,
      };
    } catch (e) {
      Log.debug('Error updating user data: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error updating user data: ${e.toString()}',
      };
    }
  }

  /// ✅ Update category progress specifically
  static Future<Map<String, dynamic>> updateCategoryProgress({
    required String languageName,
    required String levelName,
    required CategoryProgressModel categoryProgress,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        return {'success': false, 'message': 'No logged-in user found.'};
      }

      // Get current user data
      final userModel = await getUserModel(uid);
      if (userModel?.currentLearning == null) {
        return {'success': false, 'message': 'No current learning data found.'};
      }

      // Update the learning model with new category progress
      final updatedLearning = userModel!.currentLearning!.updateCategoryProgress(
        levelName: levelName,
        categoryProgress: categoryProgress,
      );

      // Update in Firestore
      return await updateUserData(currentLearning: updatedLearning);
    } catch (e) {
      Log.debug('Error updating category progress: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error updating category progress: ${e.toString()}',
      };
    }
  }

  /// ✅ Get category progress for current user
  static Future<CategoryProgressModel?> getCategoryProgress({
    required String levelName,
    required String categoryId,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;

      final userModel = await getUserModel(uid);
      return userModel?.currentLearning?.getCategoryProgress(levelName, categoryId);
    } catch (e) {
      Log.debug('Error getting category progress: ${e.toString()}');
      return null;
    }
  }

  /// ✅ Get all level progress for current user
  static Future<List<LevelProgressModel>> getAllLevelProgress() async {
    try {
      final uid = currentUserId;
      if (uid == null) return [];

      final userModel = await getUserModel(uid);
      return userModel?.currentLearning?.levelProgress ?? [];
    } catch (e) {
      Log.debug('Error getting level progress: ${e.toString()}');
      return [];
    }
  }

  /// ✅ Helper to generate category ID from name
  static String _generateCategoryId(String categoryName) {
    return categoryName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  /// ------------------------ LOGIN ------------------------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = userCredential.user!.uid;
      await _firestore.collection('app_users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      final userModel = await getUserModel(uid);

      return {
        'success': true,
        'message': 'Login successful!',
        'user': userModel,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _handleAuthError(e)};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }


  // ============================================
// NEW: Save language progress method in AuthServices
// ============================================
  static Future<bool> saveLanguageProgress({
    required String languageName,
    required LearningLanguageModel learningData,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) {
        Log.debug('⚠️ No user logged in - cannot save progress');
        return false;
      }

      Log.debug('💾 Saving language progress for $languageName');

      await _firestore
          .collection('app_users')
          .doc(uid)
          .collection('languages')
          .doc(languageName)
          .set({
        ...learningData.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.debug('✅ Progress saved successfully');
      return true;
    } catch (e, st) {
      Log.debug('❌ Error saving language progress: $e\n$st');
      return false;
    }
  }

  static Future<UserModel?> getUserModel(String uid) async {
    final snapshot = await _firestore.collection('app_users').doc(uid).get();
    if (!snapshot.exists) return null;
    return UserModel.fromMap(snapshot.data()!);
  }

  static Future<void> logout() async => await _auth.signOut();

  static Future<String?> uploadProfileImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        SnackBarUtils.showErrorSnackbar("File not found at path: $filePath");
        return null;
      }

      final random = Random();
      final randomId =
          "${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}";

      final ref = _storage.ref().child('user_profile_images/$randomId.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      Log.debug("Upload error: $e");
      SnackBarUtils.showErrorSnackbar("Error uploading image: $e");
      return null;
    }
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }

  /// Send password reset email with full debugging
  static Future<void> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();

    Log.debug("\n🔵 [PasswordReset] Started process for: $trimmedEmail");

    try {

      // Check if user exists in Firestore before sending reset email
      final userQuery = await _firestore
          .collection('app_users')
          .where('email', isEqualTo: trimmedEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user exists with this email.',
        );
      }

      // --- STEP 2: Send the reset email ---
      Log.debug("📨 [PasswordReset] Sending reset email...");
      await _auth.sendPasswordResetEmail(email: trimmedEmail);

      Log.debug("✅ [PasswordReset] Email successfully sent to: $trimmedEmail");

    } on FirebaseAuthException catch (e) {
      Log.debug("❌ [PasswordReset] FirebaseAuthException");
      Log.debug("➡️ Code: ${e.code}");
      Log.debug("➡️ Message: ${e.message}");

      switch (e.code) {
        case 'invalid-email':
          throw 'The email address is invalid.';
        case 'user-not-found':
          throw 'No user found with this email.';
        case 'too-many-requests':
          throw 'Too many attempts. Try again later.';
        default:
          throw 'Firebase error: ${e.message}';
      }

    } catch (e) {
      Log.debug("🔥 [PasswordReset] Unexpected error: $e");
      throw 'Something went wrong: $e';
    }
  }
}