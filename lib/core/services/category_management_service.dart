import 'package:lingobuzz/core/common/helpers/app_logger.dart';
import 'package:lingobuzz/model/user_model.dart';

/// ✅ Service to manage category selection and progression
class CategoryManagementService {

  /// ✅ Initialize selected categories for a level
  static List<SelectedCategoryModel> initializeSelectedCategories(
      List<String> categoryNames,
      ) {
    return categoryNames.asMap().entries.map((entry) {
      final index = entry.key;
      final name = entry.value;
      return SelectedCategoryModel(
        categoryName: name,
        categoryId: _generateCategoryId(name),
        orderIndex: index,
        isActive: index == 0, // First category is active by default
        isCompleted: false,
        addedAt: DateTime.now(),
      );
    }).toList();
  }

  /// ✅ Get active category from list
  static SelectedCategoryModel? getActiveCategory(
      List<SelectedCategoryModel> categories,
      ) {
    try {
      return categories.firstWhere((c) => c.isActive);
    } catch (e) {
      Log.debug("⚠️ No active category found");
      return null;
    }
  }

  /// ✅ Get next incomplete category
  static SelectedCategoryModel? getNextCategory(
      List<SelectedCategoryModel> categories,
      ) {
    final active = getActiveCategory(categories);
    if (active == null) {
      // Return first incomplete category
      try {
        return categories.firstWhere((c) => !c.isCompleted);
      } catch (e) {
        return null;
      }
    }

    // Find next incomplete category after active one
    final sortedCategories = List<SelectedCategoryModel>.from(categories)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (var category in sortedCategories) {
      if (category.orderIndex > active.orderIndex && !category.isCompleted) {
        return category;
      }
    }

    return null; // All categories completed
  }

  /// ✅ Mark category as completed and activate next
  static List<SelectedCategoryModel> markCompletedAndActivateNext(
      List<SelectedCategoryModel> categories,
      String categoryId,
      ) {
    // Mark target category as completed and inactive
    var updatedCategories = categories.map((cat) {
      if (cat.categoryId == categoryId) {
        return cat.copyWith(isCompleted: true, isActive: false);
      }
      return cat;
    }).toList();

    // Find and activate next category
    final nextCategory = getNextCategory(updatedCategories);
    if (nextCategory != null) {
      updatedCategories = updatedCategories.map((cat) {
        if (cat.categoryId == nextCategory.categoryId) {
          return cat.copyWith(isActive: true);
        }
        return cat;
      }).toList();
    }

    return updatedCategories;
  }

  /// ✅ Activate specific category
  static List<SelectedCategoryModel> activateCategory(
      List<SelectedCategoryModel> categories,
      String categoryId,
      ) {
    return categories.map((cat) {
      return cat.copyWith(isActive: cat.categoryId == categoryId);
    }).toList();
  }

  /// ✅ Get completed categories count
  static int getCompletedCount(List<SelectedCategoryModel> categories) {
    return categories.where((c) => c.isCompleted).length;
  }

  /// ✅ Get remaining categories count
  static int getRemainingCount(List<SelectedCategoryModel> categories) {
    return categories.where((c) => !c.isCompleted).length;
  }

  /// ✅ Check if all categories are completed
  static bool areAllCategoriesCompleted(List<SelectedCategoryModel> categories) {
    return categories.every((c) => c.isCompleted);
  }

  /// ✅ Get category by ID
  static SelectedCategoryModel? getCategoryById(
      List<SelectedCategoryModel> categories,
      String categoryId,
      ) {
    try {
      return categories.firstWhere((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// ✅ Get category by name
  static SelectedCategoryModel? getCategoryByName(
      List<SelectedCategoryModel> categories,
      String categoryName,
      ) {
    try {
      return categories.firstWhere((c) => c.categoryName == categoryName);
    } catch (e) {
      return null;
    }
  }

  /// ✅ Add new category to list
  static List<SelectedCategoryModel> addCategory(
      List<SelectedCategoryModel> categories,
      String categoryName, {
        bool setAsActive = false,
      }) {
    final maxOrderIndex = categories.isEmpty
        ? -1
        : categories.map((c) => c.orderIndex).reduce((a, b) => a > b ? a : b);

    final newCategory = SelectedCategoryModel(
      categoryName: categoryName,
      categoryId: _generateCategoryId(categoryName),
      orderIndex: maxOrderIndex + 1,
      isActive: setAsActive,
      isCompleted: false,
      addedAt: DateTime.now(),
    );

    final updatedCategories = [...categories, newCategory];

    // If setting as active, deactivate others
    if (setAsActive) {
      return updatedCategories.map((cat) {
        return cat.copyWith(
          isActive: cat.categoryId == newCategory.categoryId,
        );
      }).toList();
    }

    return updatedCategories;
  }

  /// ✅ Remove category from list
  static List<SelectedCategoryModel> removeCategory(
      List<SelectedCategoryModel> categories,
      String categoryId,
      ) {
    final filtered = categories.where((c) => c.categoryId != categoryId).toList();

    // Reorder indices
    return filtered.asMap().entries.map((entry) {
      return entry.value.copyWith(orderIndex: entry.key);
    }).toList();
  }

  /// ✅ Reorder categories
  static List<SelectedCategoryModel> reorderCategories(
      List<SelectedCategoryModel> categories,
      int oldIndex,
      int newIndex,
      ) {
    if (oldIndex < 0 || oldIndex >= categories.length) return categories;
    if (newIndex < 0 || newIndex >= categories.length) return categories;

    final list = List<SelectedCategoryModel>.from(categories);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Update order indices
    return list.asMap().entries.map((entry) {
      return entry.value.copyWith(orderIndex: entry.key);
    }).toList();
  }

  /// ✅ Get progress summary
  static Map<String, dynamic> getProgressSummary(
      List<SelectedCategoryModel> categories,
      List<CategoryProgressModel> categoryProgress,
      ) {
    final total = categories.length;
    final completed = getCompletedCount(categories);
    final remaining = getRemainingCount(categories);
    final active = getActiveCategory(categories);
    final next = getNextCategory(categories);

    // Calculate total words learned
    int totalWords = 0;
    for (var cat in categories) {
      final progress = categoryProgress.firstWhere(
            (p) => p.categoryId == cat.categoryId,
        orElse: () => CategoryProgressModel(
          categoryName: cat.categoryName,
          categoryId: cat.categoryId,
        ),
      );
      totalWords += progress.learnedWordsCount;
    }

    return {
      'totalCategories': total,
      'completedCategories': completed,
      'remainingCategories': remaining,
      'totalWordsLearned': totalWords,
      'progressPercentage': total > 0 ? (completed / total * 100).toDouble() : 0.0,
      'activeCategory': active?.toMap(),
      'nextCategory': next?.toMap(),
      'allCompleted': areAllCategoriesCompleted(categories),
    };
  }

  /// ✅ Validate category list
  static bool validateCategories(List<SelectedCategoryModel> categories) {
    if (categories.isEmpty) return false;

    // Check if exactly one category is active
    final activeCount = categories.where((c) => c.isActive).length;
    if (activeCount > 1) {
      Log.debug("❌ Validation failed: Multiple active categories");
      return false;
    }

    // Check order indices are sequential
    final sortedCategories = List<SelectedCategoryModel>.from(categories)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    for (int i = 0; i < sortedCategories.length; i++) {
      if (sortedCategories[i].orderIndex != i) {
        Log.debug("❌ Validation failed: Non-sequential order indices");
        return false;
      }
    }

    return true;
  }

  /// ✅ Fix category list (auto-correct issues)
  static List<SelectedCategoryModel> fixCategories(
      List<SelectedCategoryModel> categories,
      ) {
    if (categories.isEmpty) return categories;

    // Fix order indices
    var fixed = categories.asMap().entries.map((entry) {
      return entry.value.copyWith(orderIndex: entry.key);
    }).toList();

    // Ensure exactly one active category (or none if all completed)
    final activeCount = fixed.where((c) => c.isActive).length;

    if (activeCount == 0) {
      // Set first incomplete category as active
      final firstIncomplete = fixed.firstWhere(
            (c) => !c.isCompleted,
        orElse: () => fixed.first,
      );
      fixed = fixed.map((cat) {
        return cat.copyWith(
          isActive: cat.categoryId == firstIncomplete.categoryId,
        );
      }).toList();
    } else if (activeCount > 1) {
      // Keep only first active, deactivate others
      bool foundFirst = false;
      fixed = fixed.map((cat) {
        if (cat.isActive && !foundFirst) {
          foundFirst = true;
          return cat;
        }
        return cat.copyWith(isActive: false);
      }).toList();
    }

    return fixed;
  }

  /// ✅ Helper to generate category ID from name
  static String _generateCategoryId(String categoryName) {
    return categoryName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}