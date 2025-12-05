import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingobuzz/model/language_model.dart';

class UserModel {
  final String? uid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? image;

  /// ✅ Native language model
  final LanguageModel? nativeLanguage;

  /// ✅ Currently learning (contains all learning progress)
  final LearningLanguageModel? currentLearning;

  /// ✅ List of all learned languages
  final List<LearningLanguageModel>? learnedLanguages;

  final List<SubscriptionModel>? subscription;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.uid,
    this.firstName,
    this.lastName,
    this.email,
    this.image,
    this.nativeLanguage,
    this.currentLearning,
    this.learnedLanguages,
    this.subscription,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return UserModel();

    return UserModel(
      uid: map['uid'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      email: map['email'],
      image: map['image'],
      fcmToken: map['fcm_token'],
      /// ✅ Safe subscription parsing (handles null, list, or single map)
      subscription: (map['subscription'] is List)
          ? (map['subscription'] as List)
          .map((e) => SubscriptionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : map['subscription'] != null
          ? [SubscriptionModel.fromJson(Map<String, dynamic>.from(map['subscription']))]
          : [],

      nativeLanguage: map['native_language'] != null
          ? LanguageModel.fromJson(Map<String, dynamic>.from(map['native_language']))
          : null,
      currentLearning: map['current_learning'] != null
          ? LearningLanguageModel.fromMap(Map<String, dynamic>.from(map['current_learning']))
          : null,
      learnedLanguages: map['learned_languages'] != null
          ? List<Map<String, dynamic>>.from(map['learned_languages'])
          .map((e) => LearningLanguageModel.fromMap(e))
          .toList()
          : [],
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'image': image,
      'fcm_token': fcmToken,
      'native_language': nativeLanguage?.toJson(),
      'current_learning': currentLearning?.toMap(),
      'learned_languages': learnedLanguages?.map((lang) => lang.toMap()).toList(),
      if (subscription != null)
        'subscription': subscription!.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? image,
    LanguageModel? nativeLanguage,
    LearningLanguageModel? currentLearning,
    List<LearningLanguageModel>? learnedLanguages,
    DateTime? createdAt,
    DateTime? updatedAt
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      image: image ?? this.image,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      currentLearning: currentLearning ?? this.currentLearning,
      learnedLanguages: learnedLanguages ?? this.learnedLanguages,
      subscription: subscription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class SubscriptionModel {
  final String? planId;          // e.g. "monthly", "3-month", etc.
  final String? planName;        // e.g. "Monthly Plan"
  final double? amount;          // e.g. 5.59
  final DateTime? startDate;     // Subscription start date
  final DateTime? endDate;       // Subscription end date
  final bool? isActive;          // True if currently active
  final String? paymentIntentId; // Stripe Payment Intent ID

  SubscriptionModel({
    this.planId,
    this.planName,
    this.amount,
    this.startDate,
    this.endDate,
    this.isActive,
    this.paymentIntentId,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      planId: json['planId'],
      planName: json['planName'],
      amount: (json['amount'] != null)
          ? double.tryParse(json['amount'].toString())
          : null,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate:
      json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      isActive: json['isActive'],
      paymentIntentId: json['paymentIntentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (planId != null) 'planId': planId,
      if (planName != null) 'planName': planName,
      if (amount != null) 'amount': amount,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (isActive != null) 'isActive': isActive,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
    };
  }
}


/// ✅ CategoryProgressModel - NO lastPracticeAt here
class CategoryProgressModel {
  final String categoryName;
  final String categoryId;
  final int learnedWordsCount;
  final int learnedSentencesCount;
  final int lastWordIndex;
  final int lastSentenceIndex;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final double progressPercentage;

  CategoryProgressModel({
    required this.categoryName,
    required this.categoryId,
    this.learnedWordsCount = 0,
    this.learnedSentencesCount = 0,
    this.lastWordIndex = 0,
    this.lastSentenceIndex = 0,
    this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.progressPercentage = 0.0,
  });

  factory CategoryProgressModel.fromMap(Map<String, dynamic> map) {
    return CategoryProgressModel(
      categoryName: map['categoryName'] ?? '',
      categoryId: map['categoryId'] ?? '',
      learnedWordsCount: map['learnedWordsCount'] ?? 0,
      learnedSentencesCount: map['learnedSentencesCount'] ?? 0,
      lastWordIndex: map['lastWordIndex'] ?? 0,
      lastSentenceIndex: map['lastSentenceIndex'] ?? 0,
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseDate(map['completedAt']),
      isCompleted: map['isCompleted'] ?? false,
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'categoryId': categoryId,
      'learnedWordsCount': learnedWordsCount,
      'learnedSentencesCount': learnedSentencesCount,
      'lastWordIndex': lastWordIndex,
      'lastSentenceIndex': lastSentenceIndex,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'progressPercentage': progressPercentage,
    };
  }

  CategoryProgressModel copyWith({
    String? categoryName,
    String? categoryId,
    int? learnedWordsCount,
    int? learnedSentencesCount,
    int? lastWordIndex,
    int? lastSentenceIndex,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isCompleted,
    double? progressPercentage,
  }) {
    return CategoryProgressModel(
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      learnedWordsCount: learnedWordsCount ?? this.learnedWordsCount,
      learnedSentencesCount: learnedSentencesCount ?? this.learnedSentencesCount,
      lastWordIndex: lastWordIndex ?? this.lastWordIndex,
      lastSentenceIndex: lastSentenceIndex ?? this.lastSentenceIndex,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// ✅ SelectedCategoryModel - Tracks user's selected categories in order
class SelectedCategoryModel {
  final String categoryName;
  final String categoryId;
  final int orderIndex;
  final bool isActive;
  final bool isCompleted;
  final DateTime? addedAt;

  SelectedCategoryModel({
    required this.categoryName,
    required this.categoryId,
    required this.orderIndex,
    this.isActive = false,
    this.isCompleted = false,
    this.addedAt,
  });

  factory SelectedCategoryModel.fromMap(Map<String, dynamic> map) {
    return SelectedCategoryModel(
      categoryName: map['categoryName'] ?? '',
      categoryId: map['categoryId'] ?? '',
      orderIndex: map['orderIndex'] ?? 0,
      isActive: map['isActive'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      addedAt: _parseDate(map['addedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'categoryId': categoryId,
      'orderIndex': orderIndex,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  SelectedCategoryModel copyWith({
    String? categoryName,
    String? categoryId,
    int? orderIndex,
    bool? isActive,
    bool? isCompleted,
    DateTime? addedAt,
  }) {
    return SelectedCategoryModel(
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      orderIndex: orderIndex ?? this.orderIndex,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// ✅ LevelProgressModel - NO lastPracticeAt here either
class LevelProgressModel {
  final String levelName;
  final int totalWordsLearned;
  final int totalSentencesLearned;
  final List<CategoryProgressModel> categoryProgress;
  final List<SelectedCategoryModel> selectedCategories;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final double progressPercentage;

  LevelProgressModel({
    required this.levelName,
    this.totalWordsLearned = 0,
    this.totalSentencesLearned = 0,
    this.categoryProgress = const [],
    this.selectedCategories = const [],
    this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.progressPercentage = 0.0,
  });

  factory LevelProgressModel.fromMap(Map<String, dynamic> map) {
    return LevelProgressModel(
      levelName: map['levelName'] ?? '',
      totalWordsLearned: map['totalWordsLearned'] ?? 0,
      totalSentencesLearned: map['totalSentencesLearned'] ?? 0,
      categoryProgress: map['categoryProgress'] != null
          ? List<Map<String, dynamic>>.from(map['categoryProgress'])
          .map((e) => CategoryProgressModel.fromMap(e))
          .toList()
          : [],
      selectedCategories: map['selectedCategories'] != null
          ? List<Map<String, dynamic>>.from(map['selectedCategories'])
          .map((e) => SelectedCategoryModel.fromMap(e))
          .toList()
          : [],
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseDate(map['completedAt']),
      isCompleted: map['isCompleted'] ?? false,
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelName': levelName,
      'totalWordsLearned': totalWordsLearned,
      'totalSentencesLearned': totalSentencesLearned,
      'categoryProgress': categoryProgress.map((e) => e.toMap()).toList(),
      'selectedCategories': selectedCategories.map((e) => e.toMap()).toList(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'progressPercentage': progressPercentage,
    };
  }

  LevelProgressModel copyWith({
    String? levelName,
    int? totalWordsLearned,
    int? totalSentencesLearned,
    List<CategoryProgressModel>? categoryProgress,
    List<SelectedCategoryModel>? selectedCategories,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isCompleted,
    double? progressPercentage,
  }) {
    return LevelProgressModel(
      levelName: levelName ?? this.levelName,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      totalSentencesLearned: totalSentencesLearned ?? this.totalSentencesLearned,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  bool checkIsCompleted() {
    // A level is complete when all selected categories are completed
    if (selectedCategories.isEmpty) return false;
    return selectedCategories.every((cat) => cat.isCompleted);
  }

  /// ✅ Mark this level as completed
  LevelProgressModel markAsCompleted() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      progressPercentage: 100.0,
    );
  }

  CategoryProgressModel? getCategoryProgress(String categoryId) {
    try {
      return categoryProgress.firstWhere((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  SelectedCategoryModel? getActiveCategory() {
    try {
      return selectedCategories.firstWhere((c) => c.isActive);
    } catch (e) {
      return null;
    }
  }

  SelectedCategoryModel? getNextCategory() {
    final active = getActiveCategory();
    if (active == null) {
      return selectedCategories.isNotEmpty ? selectedCategories.first : null;
    }

    final sortedCategories = List<SelectedCategoryModel>.from(selectedCategories)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (var category in sortedCategories) {
      if (category.orderIndex > active.orderIndex && !category.isCompleted) {
        return category;
      }
    }

    return null;
  }

  int getCompletedCategoriesCount() {
    return selectedCategories.where((c) => c.isCompleted).length;
  }

  LevelProgressModel updateCategoryProgress(CategoryProgressModel newProgress) {
    final existingIndex = categoryProgress.indexWhere(
          (c) => c.categoryId == newProgress.categoryId,
    );

    List<CategoryProgressModel> updatedCategories;
    if (existingIndex >= 0) {
      updatedCategories = List.from(categoryProgress);
      updatedCategories[existingIndex] = newProgress;
    } else {
      updatedCategories = [...categoryProgress, newProgress];
    }

    final totalWords = updatedCategories.fold<int>(
      0,
          (sum, cat) => sum + cat.learnedWordsCount,
    );
    final totalSentences = updatedCategories.fold<int>(
      0,
          (sum, cat) => sum + cat.learnedSentencesCount,
    );

    return copyWith(
      categoryProgress: updatedCategories,
      totalWordsLearned: totalWords,
      totalSentencesLearned: totalSentences,
    );
  }

  LevelProgressModel updateSelectedCategories(List<SelectedCategoryModel> categories) {
    return copyWith(selectedCategories: categories);
  }

  LevelProgressModel markCategoryCompletedAndActivateNext(String categoryId) {
    final updatedCategories = selectedCategories.map((cat) {
      if (cat.categoryId == categoryId) {
        return cat.copyWith(isCompleted: true, isActive: false);
      }
      return cat;
    }).toList();

    final nextCategory = _getNextIncompleteCategory(updatedCategories, categoryId);
    if (nextCategory != null) {
      final finalCategories = updatedCategories.map((cat) {
        if (cat.categoryId == nextCategory.categoryId) {
          return cat.copyWith(isActive: true);
        }
        return cat;
      }).toList();

      return copyWith(selectedCategories: finalCategories);
    }

    return copyWith(selectedCategories: updatedCategories);
  }

  SelectedCategoryModel? _getNextIncompleteCategory(
      List<SelectedCategoryModel> categories,
      String completedCategoryId,
      ) {
    final completedCategory = categories.firstWhere(
          (c) => c.categoryId == completedCategoryId,
      orElse: () => categories.first,
    );

    final sortedCategories = List<SelectedCategoryModel>.from(categories)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (var category in sortedCategories) {
      if (category.orderIndex > completedCategory.orderIndex && !category.isCompleted) {
        return category;
      }
    }

    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// ✅ LearningLanguageModel - ONLY place with lastPracticeAt
class LearningLanguageModel {
  final String? id;
  final String? languageName;

  final String? currentLevel;
  final String? currentCategory;
  final int? wordsPerDay;
  final int? contentType;

  final int? totalWordsLearned;
  final int? totalSentencesLearned;
  final List<LevelProgressModel>? levelProgress;

  final int? previousDayLastSentence;
  final int? previousDayLastWord;

  final String? type;
  final DateTime? startedAt;

  /// ✅ ONLY lastPracticeAt in the entire model - at language level
  final DateTime? lastPracticeAt;

  LearningLanguageModel({
    this.id,
    this.languageName,
    this.currentLevel,
    this.currentCategory,
    this.wordsPerDay,
    this.contentType,
    this.totalWordsLearned,
    this.totalSentencesLearned,
    this.levelProgress,
    this.previousDayLastSentence,
    this.previousDayLastWord,
    this.type,
    this.startedAt,
    this.lastPracticeAt,
  });

  factory LearningLanguageModel.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return LearningLanguageModel();

    return LearningLanguageModel(
      id: map['id'],
      languageName: map['languageName'],
      currentLevel: map['currentLevel'],
      currentCategory: map['currentCategory'],
      wordsPerDay: map['wordsPerDay'],
      contentType: map['contentType'],
      totalWordsLearned: map['totalWordsLearned'] ?? 0,
      totalSentencesLearned: map['totalSentencesLearned'] ?? 0,
      levelProgress: map['levelProgress'] != null
          ? List<Map<String, dynamic>>.from(map['levelProgress'])
          .map((e) => LevelProgressModel.fromMap(e))
          .toList()
          : [],
      previousDayLastSentence: map['previousDayLastSentence'],
      previousDayLastWord: map['previousDayLastWord'],
      type: map['type'],
      startedAt: _parseDate(map['startedAt']),
      lastPracticeAt: _parseDate(map['lastPracticeAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'languageName': languageName,
      'currentLevel': currentLevel,
      'currentCategory': currentCategory,
      'wordsPerDay': wordsPerDay,
      'contentType': contentType,
      'totalWordsLearned': totalWordsLearned,
      'totalSentencesLearned': totalSentencesLearned,
      'levelProgress': levelProgress?.map((e) => e.toMap()).toList(),
      'previousDayLastSentence': previousDayLastSentence,
      'previousDayLastWord': previousDayLastWord,
      'type': type,
      'startedAt': startedAt?.toIso8601String(),
      'lastPracticeAt': lastPracticeAt?.toIso8601String(),
    };
  }

  LearningLanguageModel copyWith({
    String? id,
    String? languageName,
    String? currentLevel,
    String? currentCategory,
    int? wordsPerDay,
    int? contentType,
    int? totalWordsLearned,
    int? totalSentencesLearned,
    List<LevelProgressModel>? levelProgress,
    int? previousDayLastSentence,
    int? previousDayLastWord,
    String? type,
    DateTime? startedAt,
    DateTime? lastPracticeAt,
  }) {
    return LearningLanguageModel(
      id: id ?? this.id,
      languageName: languageName ?? this.languageName,
      currentLevel: currentLevel ?? this.currentLevel,
      currentCategory: currentCategory ?? this.currentCategory,
      wordsPerDay: wordsPerDay ?? this.wordsPerDay,
      contentType: contentType ?? this.contentType,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      totalSentencesLearned: totalSentencesLearned ?? this.totalSentencesLearned,
      levelProgress: levelProgress ?? this.levelProgress,
      previousDayLastSentence: previousDayLastSentence ?? this.previousDayLastSentence,
      previousDayLastWord: previousDayLastWord ?? this.previousDayLastWord,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      lastPracticeAt: lastPracticeAt ?? this.lastPracticeAt,
    );
  }

  LevelProgressModel? getLevelProgress(String levelName) {
    if (levelProgress == null || levelProgress!.isEmpty) return null;
    try {
      return levelProgress!.firstWhere((l) => l.levelName == levelName);
    } catch (e) {
      return null;
    }
  }

  CategoryProgressModel? getCategoryProgress(String levelName, String categoryId) {
    final level = getLevelProgress(levelName);
    return level?.getCategoryProgress(categoryId);
  }

  SelectedCategoryModel? getActiveCategory() {
    if (currentLevel == null) return null;
    final level = getLevelProgress(currentLevel!);
    return level?.getActiveCategory();
  }

  SelectedCategoryModel? getNextCategory() {
    if (currentLevel == null) return null;
    final level = getLevelProgress(currentLevel!);
    return level?.getNextCategory();
  }

  List<SelectedCategoryModel> getSelectedCategories() {
    if (currentLevel == null) return [];
    final level = getLevelProgress(currentLevel!);
    return level?.selectedCategories ?? [];
  }

  int getCompletedCategoriesCount() {
    if (currentLevel == null) return 0;
    final level = getLevelProgress(currentLevel!);
    return level?.getCompletedCategoriesCount() ?? 0;
  }

  LearningLanguageModel updateLevelProgress(LevelProgressModel newLevelProgress) {
    List<LevelProgressModel> updatedLevels;

    if (levelProgress == null || levelProgress!.isEmpty) {
      updatedLevels = [newLevelProgress];
    } else {
      final existingIndex = levelProgress!.indexWhere(
            (l) => l.levelName == newLevelProgress.levelName,
      );

      if (existingIndex >= 0) {
        updatedLevels = List.from(levelProgress!);
        updatedLevels[existingIndex] = newLevelProgress;
      } else {
        updatedLevels = [...levelProgress!, newLevelProgress];
      }
    }

    final totalWords = updatedLevels.fold<int>(
      0,
          (sum, level) => sum + level.totalWordsLearned,
    );
    final totalSentences = updatedLevels.fold<int>(
      0,
          (sum, level) => sum + level.totalSentencesLearned,
    );

    return copyWith(
      levelProgress: updatedLevels,
      totalWordsLearned: totalWords,
      totalSentencesLearned: totalSentences,
    );
  }
  bool isCurrentLevelCompleted() {
    if (currentLevel == null) return false;
    final level = getLevelProgress(currentLevel!);
    if (level == null) return false;

    // A level is completed when:
    // 1. It has selected categories
    // 2. All selected categories are marked as completed
    return level.selectedCategories.isNotEmpty &&
        level.selectedCategories.every((cat) => cat.isCompleted);
  }

  /// ✅ Get next available level in progression
  String? getNextLevel() {
    if (currentLevel == null) return null;

    const levels = ['A1', 'A2', 'B1', 'B2'];
    final currentIndex = levels.indexOf(currentLevel!);

    // If current level not found or already at highest level
    if (currentIndex == -1 || currentIndex >= levels.length - 1) {
      return null;
    }

    return levels[currentIndex + 1];
  }

  /// ✅ Check if all levels are completed for this language
  bool areAllLevelsCompleted() {
    const levels = ['A1', 'A2', 'B1', 'B2'];

    for (var levelName in levels) {
      final level = getLevelProgress(levelName);

      // If level doesn't exist, it's not completed
      if (level == null) return false;

      // If level exists but isn't marked completed, return false
      if (!level.isCompleted) return false;
    }

    return true;
  }

  /// ✅ Get total progress across all levels
  int getTotalCompletedLevels() {
    const levels = ['A1', 'A2', 'B1', 'B2'];
    int completedCount = 0;

    for (var levelName in levels) {
      final level = getLevelProgress(levelName);
      if (level != null && level.isCompleted) {
        completedCount++;
      }
    }

    return completedCount;
  }

  /// ✅ Get comprehensive completion summary
  Map<String, dynamic> getCompletionSummary() {
    const levels = ['A1', 'A2', 'B1', 'B2'];
    int completedLevels = 0;
    int totalCategories = 0;
    int completedCategories = 0;
    List<Map<String, dynamic>> levelDetails = [];

    for (var levelName in levels) {
      final level = getLevelProgress(levelName);
      if (level != null) {
        final levelCompleted = level.isCompleted;
        if (levelCompleted) completedLevels++;

        final categoriesInLevel = level.selectedCategories.length;
        final completedInLevel = level.getCompletedCategoriesCount();

        totalCategories += categoriesInLevel;
        completedCategories += completedInLevel;

        levelDetails.add({
          'levelName': levelName,
          'isCompleted': levelCompleted,
          'totalCategories': categoriesInLevel,
          'completedCategories': completedInLevel,
          'progressPercentage': level.progressPercentage,
          'totalWords': level.totalWordsLearned,
        });
      }
    }

    return {
      'languageName': languageName,
      'completedLevels': completedLevels,
      'totalLevels': levels.length,
      'completedCategories': completedCategories,
      'totalCategories': totalCategories,
      'currentLevel': currentLevel,
      'nextLevel': getNextLevel(),
      'isCurrentLevelCompleted': isCurrentLevelCompleted(),
      'areAllLevelsCompleted': areAllLevelsCompleted(),
      'levelDetails': levelDetails,
      'overallProgressPercentage': totalCategories > 0
          ? (completedCategories / totalCategories * 100).toDouble()
          : 0.0,
    };
  }


  LearningLanguageModel updateCategoryProgress({
    required String levelName,
    required CategoryProgressModel categoryProgress,
  }) {
    final currentLevelProgress = getLevelProgress(levelName) ??
        LevelProgressModel(
          levelName: levelName,
          startedAt: DateTime.now(),
        );

    final updatedLevelProgress = currentLevelProgress.updateCategoryProgress(categoryProgress);
    return updateLevelProgress(updatedLevelProgress);
  }

  LearningLanguageModel markCategoryCompletedAndMoveToNext({
    required String levelName,
    required String categoryId,
  }) {
    final currentLevelProgress = getLevelProgress(levelName);
    if (currentLevelProgress == null) return this;

    final updatedLevelProgress = currentLevelProgress.markCategoryCompletedAndActivateNext(categoryId);
    final result = updateLevelProgress(updatedLevelProgress);

    final nextActive = updatedLevelProgress.getActiveCategory();
    if (nextActive != null) {
      return result.copyWith(currentCategory: nextActive.categoryName);
    }

    return result;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}