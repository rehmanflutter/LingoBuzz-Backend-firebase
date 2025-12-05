// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../services/words_services.dart';
// import 'app_logger.dart';
//
// /// Debug helper class to diagnose Firestore path and document issues
// class WordServiceDebugHelper {
//   final WordService _wordService = WordService();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   /// Test the path building and document fetching
//   Future<void> debugWordFetching({
//     required String learningLang,
//     required String level,
//     required String topic,
//     required int contentType,
//     required int startIndex,
//     required int limit,
//   }) async {
//     Log.debug("🔧 ===== WORD SERVICE DEBUG START =====");
//
//     // Step 1: Build and verify path
//     final path = _wordService.buildPath(
//       learningLang: learningLang,
//       level: level,
//       topic: topic,
//       contentType: contentType,
//     );
//
//     if (path == null) {
//       Log.debug("❌ Path building failed!");
//       return;
//     }
//
//     Log.debug("📍 Built path: $path");
//
//     // Step 2: Check if path exists
//     Log.debug("\n🔍 Step 1: Verifying path exists...");
//     final pathExists = await _wordService.verifyPath(path);
//
//     if (!pathExists) {
//       Log.debug("❌ Path does not exist or is empty!");
//       Log.debug("💡 Trying alternative path structures...");
//
//       // Try alternative paths
//       final altPaths = [
//         "translation_languages/$learningLang/levels/$level/categories/$topic/${contentType == 1 ? 'words' : 'sentences'}",
//         "translation_languages/$learningLang/levels/$level/catgegories/$topic/${contentType == 1 ? 'words' : 'sentences'}",
//         "languages/$learningLang/$level/${contentType == 1 ? 'words' : 'sentences'}/$topic",
//         "languages/$learningLang/levels/$level/${contentType == 1 ? 'words' : 'sentences'}/$topic",
//       ];
//
//       for (final altPath in altPaths) {
//         Log.debug("   Trying: $altPath");
//         final exists = await _wordService.verifyPath(altPath);
//         if (exists) {
//           Log.debug("   ✅ FOUND! Use this path: $altPath");
//         }
//       }
//       return;
//     }
//
//     // Step 3: List first few documents
//     Log.debug("\n🔍 Step 2: Listing first 10 document IDs...");
//     final docIds = await _wordService.listAllDocumentIds(path, limit: 10);
//
//     if (docIds.isEmpty) {
//       Log.debug("❌ No documents found in collection!");
//       return;
//     }
//
//     // Step 4: Check specific document existence
//     Log.debug("\n🔍 Step 3: Checking if document $startIndex exists...");
//     final docExists = await _wordService.documentExists(path, startIndex);
//     Log.debug(docExists
//         ? "✅ Document $startIndex exists"
//         : "⚠️ Document $startIndex does NOT exist");
//
//     // Step 5: Check documents around the start index
//     Log.debug("\n🔍 Step 4: Checking documents around index $startIndex...");
//     for (int i = startIndex - 2; i <= startIndex + 2; i++) {
//       if (i < 1) continue;
//       final exists = await _wordService.documentExists(path, i);
//       Log.debug("   Document $i: ${exists ? '✅ EXISTS' : '❌ MISSING'}");
//     }
//
//     // Step 6: Try fetching words
//     Log.debug("\n🔍 Step 5: Attempting to fetch words...");
//     Log.debug("   Start index: $startIndex");
//     Log.debug("   Limit: $limit");
//
//     final words = await _wordService.fetchWords(
//       path: path,
//       limit: limit,
//       startAfterIndex: startIndex,
//     );
//
//     if (words.isEmpty) {
//       Log.debug("❌ No words fetched!");
//
//       // Try fetching from document 1
//       Log.debug("\n💡 Trying to fetch from document 1...");
//       final wordsFrom1 = await _wordService.fetchWords(
//         path: path,
//         limit: limit,
//         startAfterIndex: 1,
//       );
//
//       if (wordsFrom1.isNotEmpty) {
//         Log.debug("✅ Successfully fetched ${wordsFrom1.length} words from index 1");
//         Log.debug("   This means your collection starts at 1, but index $startIndex doesn't exist");
//
//         // Get total count
//         Log.debug("\n📊 Calculating total word count...");
//         final totalCount = await _wordService.getTotalWordCount(path);
//         Log.debug("   Total words available: $totalCount");
//         Log.debug("   You tried to start at: $startIndex");
//
//         if (startIndex > totalCount) {
//           Log.debug("⚠️ START INDEX ($startIndex) is GREATER than total count ($totalCount)!");
//           Log.debug("💡 You've reached the end of available words.");
//         }
//       }
//     } else {
//       Log.debug("✅ Successfully fetched ${words.length} words!");
//       for (final word in words) {
//         Log.debug("   - Document ${word.id}: ${word.toJson()}");
//       }
//     }
//
//     // Step 7: Check for more words
//     Log.debug("\n🔍 Step 6: Checking if more words available after index ${startIndex + limit - 1}...");
//     final hasMore = await _wordService.hasMoreWords(
//       path: path,
//       currentIndex: startIndex + limit - 1,
//     );
//     Log.debug(hasMore
//         ? "✅ More words available"
//         : "⚠️ No more words available");
//
//     Log.debug("\n🔧 ===== WORD SERVICE DEBUG END =====");
//   }
//
//   /// Quick test to find where documents actually start
//   Future<int?> findFirstDocumentId(String path) async {
//     Log.debug("🔍 Searching for first document in: $path");
//
//     for (int i = 0; i <= 100; i++) {
//       final exists = await _wordService.documentExists(path, i);
//       if (exists) {
//         Log.debug("✅ First document found at ID: $i");
//         return i;
//       }
//     }
//
//     Log.debug("❌ No documents found in first 100 IDs");
//     return null;
//   }
//
//   /// Check if documents use 0-based or 1-based indexing
//   Future<String> checkIndexingType(String path) async {
//     final doc0 = await _wordService.documentExists(path, 0);
//     final doc1 = await _wordService.documentExists(path, 1);
//
//     if (doc0 && !doc1) {
//       Log.debug("📊 Collection uses 0-based indexing (starts at 0)");
//       return "0-based";
//     } else if (!doc0 && doc1) {
//       Log.debug("📊 Collection uses 1-based indexing (starts at 1)");
//       return "1-based";
//     } else if (doc0 && doc1) {
//       Log.debug("📊 Collection has both 0 and 1 (mixed or full range)");
//       return "mixed";
//     } else {
//       Log.debug("⚠️ Neither 0 nor 1 exists - collection might be empty or use different IDs");
//       return "unknown";
//     }
//   }
// }