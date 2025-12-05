import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../model/word_model.dart';
import '../../model/saved_seen_word_model.dart';

class SeenSavedWordsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Dynamic language-based subcollections
  CollectionReference<Map<String, dynamic>> _seenWordsCollection(String userId, String language) {
    return _firestore
        .collection('app_users')
        .doc(userId)
        .collection('languages')
        .doc(language)
        .collection('seen_words');
  }

  CollectionReference<Map<String, dynamic>> _savedWordsCollection(String userId, String language) {
    return _firestore
        .collection('app_users')
        .doc(userId)
        .collection('languages')
        .doc(language)
        .collection('saved_words');
  }

  /// ✅ Add seen word
  Future<bool> addSeenWord({
    required String userId,
    required String language,
    required WordModel word,
    required String level,
  }) async {
    try {
      final docRef = _seenWordsCollection(userId, language).doc(word.id);
      await docRef.set({
        'id': word.id,
        'wordModel': word.toJson(),
        'level': level,
        'seenDateTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.debug("✅ Word '${word.id}' added to $language/seen_words");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error adding seen word: $e\n$st');
      return false;
    }
  }

  /// ✅ Add multiple words to seen_words (optimized batch operation)
  Future<bool> addMultipleSeenWords({
    required String userId,
    required String language,
    required List<WordModel> words,
    required String level,
  })
  async {
    try {
      if (words.isEmpty) {
        Log.debug("⚠️ No words to add to seen_words");
        return true;
      }

      if (userId.isEmpty) {
        Log.debug("⚠️ Invalid userId");
        return false;
      }

      final userSeenRef = _seenWordsCollection(userId,language);

      // More efficient: Use set with merge to avoid checking existing docs
      // Firestore will handle duplicates gracefully
      final batch = _firestore.batch();
      int processedCount = 0;

      for (var word in words) {
        if (word.id.isEmpty) {
          Log.debug("⚠️ Skipping word with empty ID");
          continue;
        }

        final docRef = userSeenRef.doc(word.id);
        batch.set(docRef, {
          'id': word.id,
          'wordModel': word.toJson(),
          'level': level,
          'seenDateTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        processedCount++;

        // Firestore batch limit is 500 operations
        if (processedCount % 500 == 0) {
          await batch.commit();
          Log.debug("✅ Committed batch of 500 words");
        }
      }

      // Commit remaining operations
      if (processedCount % 500 != 0) {
        await batch.commit();
      }

      Log.debug("✅ Added/Updated $processedCount words to seen_words");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error adding multiple seen words: $e\n$st');
      return false;
    }
  }

  /// ✅ Save word
  Future<bool> saveWord({
    required String userId,
    required String language,
    required WordModel word,
    required String level,
  }) async {
    try {
      final docRef = _savedWordsCollection(userId, language).doc(word.id);
      await docRef.set({
        'id': word.id,
        'wordModel': word.toJson(),
        'level': level,
        'savedDateTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Log.debug("✅ Word '${word.id}' saved to $language/saved_words");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error saving word: $e\n$st');
      return false;
    }
  }

  /// ✅ Unsave a word
  Future<bool> unsaveWord({
    required String userId,
    required String wordId,
    required String language,
  }) async {
    try {
      if (userId.isEmpty || wordId.isEmpty) {
        Log.debug("⚠️ Invalid userId or wordId");
        return false;
      }

      await _savedWordsCollection(userId,language).doc(wordId).delete();
      Log.debug("✅ Word '$wordId' removed from saved_words");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error removing saved word: $e\n$st');
      return false;
    }
  }

  /// ✅ Check if saved
  Future<bool> isWordSaved({
    required String userId,
    required String wordId,
    required String language,
  }) async {
    try {
      if (userId.isEmpty || wordId.isEmpty) return false;

      final doc = await _savedWordsCollection(userId,language).doc(wordId).get();
      return doc.exists;
    } catch (e) {
      Log.debug('❌ Error checking if word is saved: $e');
      return false;
    }
  }

  /// ✅ Check if seen
  Future<bool> isWordSeen({
    required String userId,
    required String wordId,
    required String language,
  }) async {
    try {
      if (userId.isEmpty || wordId.isEmpty) return false;

      final doc = await _seenWordsCollection(userId,language).doc(wordId).get();
      return doc.exists;
    } catch (e) {
      Log.debug('❌ Error checking if word is seen: $e');
      return false;
    }
  }

  /// ✅ Get seen words
  Future<List<SavedSeenWordModel>> getSeenWords({
    required String userId,
    required String language,
    String? level,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _seenWordsCollection(userId, language);
      if (level != null) query = query.where('level', isEqualTo: level);
      query = query.orderBy('seenDateTime', descending: true);
      if (limit != null) query = query.limit(limit);

      final snapshot = await query.get();
      final words = snapshot.docs
          .map((doc) => SavedSeenWordModel.fromDoc(doc, isSaved: false))
          .toList();

      Log.debug("✅ Loaded ${words.length} seen words for $language");
      return words;
    } catch (e) {
      Log.debug('❌ Error getting seen words: $e');
      return [];
    }
  }

  /// ✅ Get saved words
  Future<List<SavedSeenWordModel>> getSavedWords({
    required String userId,
    required String language,
    String? level,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _savedWordsCollection(userId, language);
      if (level != null) query = query.where('level', isEqualTo: level);
      query = query.orderBy('savedDateTime', descending: true);
      if (limit != null) query = query.limit(limit);

      final snapshot = await query.get();
      final words = snapshot.docs
          .map((doc) => SavedSeenWordModel.fromDoc(doc, isSaved: true))
          .toList();

      Log.debug("✅ Loaded ${words.length} saved words for $language");
      return words;
    } catch (e) {
      Log.debug('❌ Error getting saved words: $e');
      return [];
    }
  }

  /// ✅ Get seen word count
  Future<int> getSeenWordsCount({
    required String userId,
    required String language,
    String? level,
  }) async {
    try {
      if (userId.isEmpty) return 0;

      Query<Map<String, dynamic>> query = _seenWordsCollection(userId,language);

      if (level != null && level.isNotEmpty) {
        query = query.where('level', isEqualTo: level);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      Log.debug('❌ Error getting seen words count: $e');
      return 0;
    }
  }

  /// ✅ Get saved word count
  Future<int> getSavedWordsCount({
    required String userId,
    required String language,
    String? level,
  }) async {
    try {
      if (userId.isEmpty) return 0;

      Query<Map<String, dynamic>> query = _savedWordsCollection(userId,language);

      if (level != null && level.isNotEmpty) {
        query = query.where('level', isEqualTo: level);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      Log.debug('❌ Error getting saved words count: $e');
      return 0;
    }
  }

  /// ✅ Clear all seen words (with batch size limit)
  Future<bool> clearSeenWords({required String userId,required String language}) async {
    try {
      if (userId.isEmpty) {
        Log.debug("⚠️ Invalid userId");
        return false;
      }

      final snapshot = await _seenWordsCollection(userId,language).get();

      if (snapshot.docs.isEmpty) {
        Log.debug("✅ No seen words to clear");
        return true;
      }

      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;

        // Commit every 500 operations
        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      // Commit remaining operations
      if (count % 500 != 0) {
        await batch.commit();
      }

      Log.debug("✅ Cleared $count seen words for user $userId");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error clearing seen words: $e\n$st');
      return false;
    }
  }

  /// ✅ Clear all saved words (with batch size limit)
  Future<bool> clearSavedWords({required String userId,required String language}) async {
    try {
      if (userId.isEmpty) {
        Log.debug("⚠️ Invalid userId");
        return false;
      }

      final snapshot = await _savedWordsCollection(userId,language).get();

      if (snapshot.docs.isEmpty) {
        Log.debug("✅ No saved words to clear");
        return true;
      }

      final batch = _firestore.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;

        // Commit every 500 operations
        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      // Commit remaining operations
      if (count % 500 != 0) {
        await batch.commit();
      }

      Log.debug("✅ Cleared $count saved words for user $userId");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error clearing saved words: $e\n$st');
      return false;
    }
  }

  /// ✅ Remove a word from seen_words
  Future<bool> removeSeenWord({
    required String userId,
    required String wordId,
    required String language,
  }) async {
    try {
      if (userId.isEmpty || wordId.isEmpty) {
        Log.debug("⚠️ Invalid userId or wordId");
        return false;
      }

      await _seenWordsCollection(userId,language).doc(wordId).delete();
      Log.debug("✅ Word '$wordId' removed from seen_words");
      return true;
    } catch (e, st) {
      Log.debug('❌ Error removing seen word: $e\n$st');
      return false;
    }
  }

  /// ✅ Get both saved and seen status for multiple words at once
  Future<Map<String, bool>> getBulkSavedStatus({
    required String userId,
    required String language,
    required List<String> wordIds,
  }) async {
    try {
      if (userId.isEmpty || wordIds.isEmpty) return {};

      final results = <String, bool>{};

      // Process in chunks of 10 (Firestore 'in' query limit)
      for (var i = 0; i < wordIds.length; i += 10) {
        final chunk = wordIds.sublist(i, i + 10 > wordIds.length ? wordIds.length : i + 10);

        final snapshot = await _savedWordsCollection(userId,language)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var id in chunk) {
          results[id] = snapshot.docs.any((doc) => doc.id == id);
        }
      }

      return results;
    } catch (e) {
      Log.debug('❌ Error getting bulk saved status: $e');
      return {};
    }
  }

  /// ✅ Clear all words
  Future<void> clearAllLanguageData({
    required String userId,
    required String language,
  }) async {
    await _deleteAllFromCollection(_seenWordsCollection(userId, language));
    await _deleteAllFromCollection(_savedWordsCollection(userId, language));
    Log.debug("✅ Cleared all seen/saved words for $language");
  }

  Future<void> _deleteAllFromCollection(
      CollectionReference<Map<String, dynamic>> ref) async {
    final snapshot = await ref.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}