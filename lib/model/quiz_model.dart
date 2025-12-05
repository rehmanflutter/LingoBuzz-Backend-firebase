class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}


class QuizQuestion {
  final String id;
  final String question; // could be the word itself or meaning depending on your use case
  final List<String> options;
  final String correctAnswer;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.correctAnswerIndex,
  });
}


class QuizResultModel {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final num percentage;
  final DateTime completedAt;

  QuizResultModel({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.completedAt,
  });

  factory QuizResultModel.fromScore({
    required int total,
    required int correct,
  }) {
    final wrong = total - correct;
    final percentage = total > 0 ? (correct / total) * 100 : 0;
    return QuizResultModel(
      totalQuestions: total,
      correctAnswers: correct,
      wrongAnswers: wrong,
      percentage: percentage,
      completedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'percentage': percentage,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'QuizResultModel(total: $totalQuestions, correct: $correctAnswers, wrong: $wrongAnswers, percentage: ${percentage.toStringAsFixed(1)}%)';
}

