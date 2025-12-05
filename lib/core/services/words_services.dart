import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/common/helpers/app_logger.dart';
import '../../model/word_model.dart';

class WordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Common helper for consistent Firestore ID formatting (e.g. "01", "02", "10")
  String _formatId(int id) => id.toString().padLeft(2, '0');

  /// ✅ Build Firestore path dynamically
  String? buildPath({
    required String learningLang,
    required String level,
    required String topic,
    required int contentType,
  })
  {
    if (learningLang.isEmpty || topic.isEmpty) {
      Log.debug("❌ Missing language or topic information.");
      return null;
    }

    String contentFolder;
    switch (contentType) {
      case 1:
        contentFolder = "phrases";
        break;
      case 2:
        contentFolder = "phrases";
        break;
      case 3:
        contentFolder = "phrases";
        break;
      default:
        contentFolder = "phrases";
    }

    final path = "translation_languages/$learningLang/levels/$level/categories/$topic/$contentFolder";

    Log.debug("📘 Built Firestore path: $path");
    return path;
  }

  Future<List<WordModel>> fetchWords({
    required String path,
    required int limit,
    int startAfterIndex = 1,
  })
  async {
    final startTime = DateTime.now();
    Log.debug("⏱️ Fetch started at: $startTime");

    try {
      Log.debug("🔍 Fetching words from: $path");
      Log.debug("   - Start index: $startAfterIndex");
      Log.debug("   - Limit: $limit");

      final allDocIds =
      List.generate(limit, (i) => _formatId(startAfterIndex + i));

      Log.debug("   - Document IDs to fetch: $allDocIds");

      final List<WordModel> allWords = [];
      const batchSize = 10;

      for (var i = 0; i < allDocIds.length; i += batchSize) {
        final batch = allDocIds.skip(i).take(batchSize).toList();
        final snapshot = await _firestore
            .collection(path)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final words = snapshot.docs
            .map((doc) => WordModel.fromJson(doc.data(), doc.id))
            .toList();
        allWords.addAll(words);
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      Log.debug(
          "✅ Successfully fetched ${allWords.length} words in ${duration.inMilliseconds} ms");

      return allWords;
    } catch (e, st) {
      final duration = DateTime.now().difference(startTime);
      Log.debug("❌ Error fetching words after ${duration.inMilliseconds} ms: $e\n$st");
      return [];
    }
  }

  /// ✅ NEW: Fetch words within a specific range (for getting already-learned words)
  Future<List<WordModel>> fetchWordsRange({
    required String path,
    required int startIndex,
    required int endIndex,
  }) async {
    try {
      if (startIndex > endIndex) {
        Log.debug("❌ Invalid range: start=$startIndex > end=$endIndex");
        return [];
      }

      if (startIndex < 1) {
        Log.debug("❌ Invalid start index: $startIndex (must be >= 1)");
        return [];
      }

      Log.debug("🔍 Fetching word range from $path:");
      Log.debug("   - Start: $startIndex");
      Log.debug("   - End: $endIndex");

      final count = endIndex - startIndex + 1;
      final docIds = List.generate(count, (i) => _formatId(startIndex + i));

      Log.debug("   - Document IDs: $docIds");

      final List<WordModel> words = [];
      const batchSize = 10;

      // Fetch in batches
      for (var i = 0; i < docIds.length; i += batchSize) {
        final batch = docIds.skip(i).take(batchSize).toList();

        final snapshot = await _firestore
            .collection(path)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchWords = snapshot.docs
            .map((doc) => WordModel.fromJson(doc.data(), doc.id))
            .toList();

        words.addAll(batchWords);
      }

      // Sort by document ID to maintain order
      words.sort((a, b) {
        final aIndex = int.tryParse(a.id) ?? 0;
        final bIndex = int.tryParse(b.id) ?? 0;
        return aIndex.compareTo(bIndex);
      });

      Log.debug("✅ Fetched ${words.length} words in range");
      return words;
    } catch (e, st) {
      Log.debug('❌ Error fetching words range: $e\n$st');
      return [];
    }
  }

  Future<List<WordModel>> fetchWordsBatch({
    required String path,
    required int limit,
    int startAfterIndex = 1,
  }) async {
    try {
      Log.debug("🔍 Batch fetching words from: $path");

      final docIds =
      List.generate(limit, (i) => _formatId(startAfterIndex + i));

      final futures =
      docIds.map((id) => _firestore.collection(path).doc(id).get());

      final snapshots = await Future.wait(futures);
      final words = <WordModel>[];

      for (final snapshot in snapshots) {
        if (snapshot.exists && snapshot.data() != null) {
          words.add(WordModel.fromJson(snapshot.data()!, snapshot.id));
        }
      }

      Log.debug("✅ Fetched ${words.length} words (Batch mode)");
      return words;
    } catch (e, st) {
      Log.debug("❌ Error in batch fetch: $e\n$st");
      return [];
    }
  }

  Future<int> getTotalWordCount(String path) async {
    try {
      final snapshot = await _firestore.collection(path).get();
      final count = snapshot.docs.length;

      Log.debug("📊 Total word count for $path: $count");
      return count;
    } catch (e, st) {
      Log.debug("❌ Error getting word count: $e\n$st");
      return 0;
    }
  }

  Future<bool> documentExists(String path, int docId) async {
    try {
      final doc = await _firestore
          .collection(path)
          .doc(_formatId(docId))
          .get();
      return doc.exists;
    } catch (e) {
      Log.debug('❌ Error checking document existence: $e');
      return false;
    }
  }

  Future<bool> hasMoreWords({
    required String path,
    required int currentIndex,
  }) async {
    try {
      final nextDoc = await _firestore
          .collection(path)
          .doc(_formatId(currentIndex + 1))
          .get();
      return nextDoc.exists;
    } catch (e) {
      Log.debug('❌ Error checking next word: $e');
      return false;
    }
  }

  Future<WordModel?> fetchWordById({
    required String path,
    required int docId,
  }) async {
    try {
      final doc = await _firestore
          .collection(path)
          .doc(_formatId(docId))
          .get();

      if (doc.exists && doc.data() != null) {
        return WordModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      Log.debug('❌ Error fetching word by ID: $e');
      return null;
    }
  }

  Future<bool> verifyPathExists(String path) async {
    try {
      final snap = await _firestore.collection(path).limit(1).get();
      final exists = snap.docs.isNotEmpty;
      Log.debug(exists
          ? "✅ Path verified: $path"
          : "⚠️ Path empty or incorrect: $path");
      return exists;
    } catch (e) {
      Log.debug('❌ Error verifying path: $e');
      return false;
    }
  }

}
