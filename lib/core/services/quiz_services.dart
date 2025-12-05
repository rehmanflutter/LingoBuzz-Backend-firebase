import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingobuzz/core/common/helpers/app_logger.dart';
import 'package:lingobuzz/model/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Dynamic quiz collection based on user & language
  CollectionReference<Map<String, dynamic>> _quizCollection(String userId, String language) {
    return _firestore
        .collection('app_users')
        .doc(userId)
        .collection('languages')
        .doc(language)
        .collection('quizes'); // 👈 same structure as seen/saved words
  }

  /// ✅ Save a completed quiz
  Future<bool> saveQuiz({
    required String userId,
    required String language,
    required QuizResultModel result,
    required List<QuizQuestion> questions,
  }) async {
    try {
      final docRef = _quizCollection(userId, language).doc();

      await docRef.set({
        'quizId': docRef.id,
        'totalQuestions': result.totalQuestions,
        'correctAnswers': result.correctAnswers,
        'scorePercentage': result.percentage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Log.debug("✅ Quiz saved successfully for user '$userId' in language '$language'");
      return true;
    } catch (e, st) {
      Log.debug("❌ Error saving quiz: $e\n$st");
      return false;
    }
  }

  /// ✅ Fetch all quizzes for a user & language
  Future<List<Map<String, dynamic>>> fetchUserQuizzes({
    required String userId,
    required String language,
  }) async {
    try {
      final snapshot = await _quizCollection(userId, language)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, st) {
      Log.debug("❌ Error fetching quizzes: $e\n$st");
      return [];
    }
  }
}
