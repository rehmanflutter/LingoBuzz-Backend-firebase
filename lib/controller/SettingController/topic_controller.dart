import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../core/common/snackbar_utils.dart';
import '../../model/user_model.dart';
import '../AuthController/auth_controller.dart';
import '../words_controller/word_controller.dart';

class TopicController extends GetxController {
  final _storage = GetStorage();
  final authController = Get.find<AuthController>();

  /// All available topics
  final List<String> allTopics = [
    'Everyday Conversation',
    'Travel & Transportation',
    'Food & Dining',
    'Work & Business',
    'Home & Family',
    'Culture & Entertainment',
  ];

  /// Reactive list for selected topics (used during setup)
  RxList<String> selectedTopics = <String>['Everyday Conversation'].obs;

  /// Flag to indicate if categories are being set up for the first time
  RxBool isInitialSetup = true.obs;

  /// Loading state
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeTopics();
  }

  /// ✅ Initialize topics - check Firestore first, then load from cache
  Future<void> _initializeTopics() async {
    await _checkIfCategoriesAlreadySet();
    if (isInitialSetup.value) {
      _loadSelectedTopicsFromCache();
    }
  }

  void setSelectedTopics(List<String> topics) {
    selectedTopics.assignAll(topics);
  }

  /// ✅ Set initial topic after profile creation
  Future<bool> setInitialTopic() async {
    try {
      isLoading.value = true;

      Log.debug("🎯 Setting initial topic: Everyday Conversation");
      _saveSelectedTopicsToCache();

      // Save to Firestore
      final success = await confirmCategorySelection();

      if (success) {
        Log.debug("✅ Initial topic set successfully");
        isLoading.value = false;
        return true;
      } else {
        Log.debug("❌ Failed to set initial topic");
        isLoading.value = false;
        return false;
      }
    } catch (e, st) {
      Log.debug("❌ Error setting initial topic: $e\n$st");
      isLoading.value = false;
      return false;
    }
  }


  /// ✅ Check if user already has selected categories in Firestore
  Future<void> _checkIfCategoriesAlreadySet() async {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) {
      isInitialSetup.value = true;
      Log.debug("ℹ️ No learning data - initial setup required");
      return;
    }

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) {
      isInitialSetup.value = true;
      Log.debug("ℹ️ No current level - initial setup required");
      return;
    }

    final levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
    if (levelProgress != null && levelProgress.selectedCategories.isNotEmpty) {
      // User already has categories set up in Firestore
      isInitialSetup.value = false;

      // Load their selected categories from Firestore
      final savedCategories = levelProgress.selectedCategories
          .map((c) => c.categoryName)
          .toList();
      selectedTopics.assignAll(savedCategories);

      Log.debug("✅ Loaded ${savedCategories.length} categories from Firestore");
      Log.debug("   Categories: ${savedCategories.join(', ')}");
      Log.debug("   Active: ${levelProgress.selectedCategories.firstWhere((c) => c.isActive, orElse: () => levelProgress.selectedCategories.first).categoryName}");
    } else {
      isInitialSetup.value = true;
      Log.debug("ℹ️ No categories found in Firestore - user needs to select categories");
    }
  }

  /// ✅ Toggle topic selection and update currentUser data
  Future<void> toggleTopic(String topicName) async {
    final user = authController.currentUser.value;
    if (user == null) return;

    final learning = user.currentLearning;
    if (learning == null) return;

    final currentLevel = learning.currentLevel;
    if (currentLevel == null) return;

    // ✅ Get existing LevelProgress or create a new one
    final levelProgressList = learning.levelProgress ?? [];
    var levelProgress = levelProgressList.firstWhereOrNull(
          (lvl) => lvl.levelName == currentLevel,
    );

    if (levelProgress == null) {
      levelProgress = LevelProgressModel(
        levelName: currentLevel,
        selectedCategories: [],
        categoryProgress: [],
        startedAt: DateTime.now(),
      );
      levelProgressList.add(levelProgress);
    }

    // ✅ Work on selected categories
    final selectedCategories = List<SelectedCategoryModel>.from(levelProgress.selectedCategories);

    // Check if topic already exists
    final existingIndex = selectedCategories.indexWhere(
          (cat) => cat.categoryName == topicName,
    );

    if (existingIndex >= 0) {
      // Prevent removing all categories
      if (selectedCategories.length == 1) {
        SnackBarUtils.showErrorSnackbar('You must select at least one category');
        return;
      }

      selectedCategories.removeAt(existingIndex);
      selectedTopics.remove(topicName);
      Log.debug("🟡 Topic removed: $topicName");
    } else {
      final newCategory = SelectedCategoryModel(
        categoryName: topicName,
        categoryId: topicName.toLowerCase().replaceAll(' ', '_'),
        orderIndex: selectedCategories.length,
        isActive: selectedCategories.isEmpty,
        addedAt: DateTime.now(),
      );
      selectedCategories.add(newCategory);
      selectedTopics.add(topicName);
      Log.debug("🟢 Topic added: $topicName");
    }

    Log.debug("📘 Topics now: ${selectedCategories.map((c) => c.categoryName).join(', ')}");
    confirmCategorySelection();
  }



  /// ✅ Set multiple topics at once
  void setTopics(List<String> topics) {
    if (topics.isEmpty) {
      Log.debug("⚠️ Cannot set empty topics list");
      SnackBarUtils.showErrorSnackbar(
        'Please select at least one category',
      );
      return;
    }

    selectedTopics.assignAll(topics);
    _saveSelectedTopicsToCache();
    Log.debug("✅ Topics set: ${topics.join(', ')}");
  }

  /// ✅ Add topic to selection
  void addTopic(String topic) {
    if (!selectedTopics.contains(topic)) {
      selectedTopics.add(topic);
      _saveSelectedTopicsToCache();
      Log.debug("🟢 Topic added: $topic");
    }
  }

  /// ✅ Remove topic from selection
  void removeTopic(String topic) {
    if (selectedTopics.length == 1) {
      Log.debug("⚠️ Cannot remove the last selected topic");
      SnackBarUtils.showErrorSnackbar(
        'You must have at least one category selected',
      );
      return;
    }

    if (selectedTopics.contains(topic)) {
      selectedTopics.remove(topic);
      _saveSelectedTopicsToCache();
      Log.debug("🟡 Topic removed: $topic");
    }
  }

  /// ✅ Confirm and save selected categories to Firestore
  Future<bool> confirmCategorySelection() async {
    if (selectedTopics.isEmpty) {
      Log.debug("❌ No categories selected");
      SnackBarUtils.showErrorSnackbar(
        'Please select at least one category',
      );
      return false;
    }

    try {
      isLoading.value = true;

      // Get WordController to add categories
      final wordController = Get.find<WordController>();

      Log.debug("💾 Saving ${selectedTopics.length} selected categories to Firestore...");
      Log.debug("   Categories: ${selectedTopics.join(', ')}");

      // Add selected categories to Firestore
      final success = await wordController.addSelectedCategories(
        selectedTopics.toList(),
      );

      if (success) {
        isInitialSetup.value = false;
        _storage.write('categories_setup_done', true);

        // Clear cache after successful Firestore save
        _storage.remove('selected_topics');

        Log.debug("✅ Categories saved successfully to Firestore!");
        Log.debug("   Selected: ${selectedTopics.join(', ')}");
        Log.debug("   Active category: ${selectedTopics.first}");

        // Get.snackbar(
        //   'Categories Saved! 🎉',
        //   'Starting with: ${selectedTopics.first}',
        //   snackPosition: SnackPosition.BOTTOM,
        //   duration: Duration(seconds: 2),
        // );

        isLoading.value = false;
        return true;
      } else {
        Log.debug("❌ Failed to save categories to Firestore");
        SnackBarUtils.showErrorSnackbar(
          'Failed to save categories. Please try again.',
        );
        isLoading.value = false;
        return false;
      }
    } catch (e, st) {
      Log.debug("❌ Error confirming category selection: $e\n$st");
      SnackBarUtils.showErrorSnackbar(
        'An error occurred: ${e.toString()}',
      );
      isLoading.value = false;
      return false;
    }
  }

  /// ✅ Get user's saved categories from Firestore (not local storage)
  List<Map<String, dynamic>> getSavedCategories() {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return [];

    final currentLevel = user!.currentLearning!.currentLevel;
    if (currentLevel == null) return [];

    final levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
    if (levelProgress == null) return [];

    // Sort by order index
    final sortedCategories = List.from(levelProgress.selectedCategories)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return sortedCategories.map((cat) => {
      'name': cat.categoryName,
      'id': cat.categoryId,
      'orderIndex': cat.orderIndex,
      'isActive': cat.isActive,
      'isCompleted': cat.isCompleted,
      'addedAt': cat.addedAt,
    }).toList();
  }

  /// ✅ Get active category
  String? getActiveCategory() {
    final categories = getSavedCategories();
    if (categories.isEmpty) return null;

    try {
      final active = categories.firstWhere((c) => c['isActive'] == true);
      return active['name'] as String;
    } catch (e) {
      // If no active category found, return first one
      return categories.first['name'] as String;
    }
  }

  /// ✅ Get next category
  String? getNextCategory() {
    final user = authController.currentUser.value;
    if (user?.currentLearning == null) return null;

    final nextCat = user!.currentLearning!.getNextCategory();
    return nextCat?.categoryName;
  }

  /// ✅ Get completed categories count
  int getCompletedCategoriesCount() {
    final categories = getSavedCategories();
    return categories.where((c) => c['isCompleted'] == true).length;
  }

  /// ✅ Get total categories count
  int getTotalCategoriesCount() {
    return getSavedCategories().length;
  }

  /// ✅ Check if all categories are completed
  bool areAllCategoriesCompleted() {
    final categories = getSavedCategories();
    if (categories.isEmpty) return false;
    return categories.every((c) => c['isCompleted'] == true);
  }

  /// ✅ Get category progress summary
  Map<String, dynamic> getCategoriesProgressSummary() {
    final categories = getSavedCategories();
    final total = categories.length;
    final completed = getCompletedCategoriesCount();

    return {
      'total': total,
      'completed': completed,
      'remaining': total - completed,
      'activeCategory': getActiveCategory(),
      'nextCategory': getNextCategory(),
      'allCompleted': areAllCategoriesCompleted(),
      'categories': categories,
    };
  }

  /// ✅ Reorder categories (drag and drop functionality)
  Future<bool> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return true;

    try {
      isLoading.value = true;
      final user = authController.currentUser.value;

      if (user?.currentLearning == null) {
        isLoading.value = false;
        return false;
      }

      final currentLevel = user!.currentLearning!.currentLevel;
      if (currentLevel == null) {
        isLoading.value = false;
        return false;
      }

      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
      if (levelProgress == null) {
        isLoading.value = false;
        return false;
      }

      // Reorder the list
      final categories = List<SelectedCategoryModel>.from(levelProgress.selectedCategories);
      final item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);

      // Update order indices
      final reorderedCategories = categories.asMap().entries.map((entry) {
        return entry.value.copyWith(orderIndex: entry.key);
      }).toList();

      // Update level progress
      levelProgress = levelProgress.copyWith(selectedCategories: reorderedCategories);

      // Update learning model
      final updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress);

      // Save to Firestore
      final success = await authController.updateUserData(
        currentLearning: updatedLearning,
        showLoading: false,
      );

      if (success) {
        Log.debug("✅ Categories reordered successfully");
        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e, st) {
      Log.debug("❌ Error reordering categories: $e\n$st");
      isLoading.value = false;
      return false;
    }
  }

  /// ✅ Save selected topics to local storage (temporary during setup only)
  void _saveSelectedTopicsToCache() {
    try {
      _storage.write('selected_topics', selectedTopics.toList());
      Log.debug("💾 Topics saved to cache: ${selectedTopics.toList()}");
    } catch (e) {
      Log.debug("❌ Error saving topics to cache: $e");
    }
  }

  /// ✅ Load selected topics from local storage (only if not in Firestore)
  void _loadSelectedTopicsFromCache() {
    try {
      final savedTopics = _storage.read<List>('selected_topics');
      if (savedTopics != null && savedTopics.isNotEmpty) {
        selectedTopics.assignAll(savedTopics.cast<String>());
        Log.debug("🔄 Loaded topics from cache: $savedTopics");
      } else {
        // Default to first topic if nothing saved
        selectedTopics.assignAll(['Everyday Conversation']);
        Log.debug("ℹ️ No saved topics in cache. Using default: Everyday Conversation");
      }
    } catch (e) {
      Log.debug("❌ Error loading topics from cache: $e");
      selectedTopics.assignAll(['Everyday Conversation']);
    }
  }

  /// ✅ Clear all selected topics (only during setup, before confirmation)
  void clearTopics() {
    if (isInitialSetup.value) {
      selectedTopics.clear();
      _saveSelectedTopicsToCache();
      Log.debug("🧹 Cleared all selected topics from cache");
    } else {
      Log.debug("⚠️ Cannot clear topics - categories already set up in Firestore");
    }
  }

  /// ✅ Reset setup (for testing or re-setup)
  Future<void> resetCategorySetup() async {
    try {
      isLoading.value = true;
      final user = authController.currentUser.value;

      if (user?.currentLearning == null) {
        isLoading.value = false;
        return;
      }

      final currentLevel = user!.currentLearning!.currentLevel;
      if (currentLevel == null) {
        isLoading.value = false;
        return;
      }

      // Clear level progress in Firestore
      var levelProgress = user.currentLearning!.getLevelProgress(currentLevel);
      if (levelProgress != null) {
        levelProgress = levelProgress.copyWith(
          selectedCategories: [],
          categoryProgress: [],
        );

        final updatedLearning = user.currentLearning!.updateLevelProgress(levelProgress);

        await authController.updateUserData(
          currentLearning: updatedLearning,
          showLoading: false,
        );
      }

      // Clear local storage
      _storage.remove('selected_topics');
      _storage.remove('categories_setup_done');

      // Reset state
      isInitialSetup.value = true;
      selectedTopics.assignAll(['Everyday Conversation']);

      Log.debug("🔄 Category setup reset successfully");
      isLoading.value = false;
    } catch (e, st) {
      Log.debug("❌ Error resetting category setup: $e\n$st");
      isLoading.value = false;
    }
  }

  /// ✅ Check if user needs to select categories
  bool needsCategorySelection() {
    return isInitialSetup.value && getSavedCategories().isEmpty;
  }

  /// ✅ Validate category selection
  bool isValidSelection() {
    return selectedTopics.isNotEmpty;
  }

  /// ✅ Get suggested categories based on level
  List<String> getSuggestedCategories(String level) {
    switch (level) {
      case 'A1':
        return [
          'Everyday Conversation',
          'Food & Dining',
          'Home & Family',
        ];
      case 'A2':
        return [
          'Everyday Conversation',
          'Travel & Transportation',
          'Food & Dining',
          'Home & Family',
        ];
      case 'B1':
        return [
          'Travel & Transportation',
          'Work & Business',
          'Culture & Entertainment',
          'Food & Dining',
        ];
      case 'B2':
        return [
          'Work & Business',
          'Culture & Entertainment',
          'Travel & Transportation',
        ];
      default:
        return allTopics;
    }
  }

  /// ✅ Auto-select suggested categories for level
  void autoSelectForLevel(String level) {
    final suggested = getSuggestedCategories(level);
    selectedTopics.assignAll(suggested);
    _saveSelectedTopicsToCache();
    Log.debug("✅ Auto-selected ${suggested.length} categories for level $level");
    Log.debug("   Categories: ${suggested.join(', ')}");
  }

  /// ✅ Refresh topics from Firestore (call after login)
  Future<void> refreshTopicsFromFirestore() async {
    Log.debug("🔄 Refreshing topics from Firestore...");
    await _checkIfCategoriesAlreadySet();
  }
}