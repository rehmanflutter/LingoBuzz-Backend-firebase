import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lingobuzz/controller/SettingController/setting_controller.dart';
import 'package:lingobuzz/controller/words_controller/word_controller.dart';
import 'package:lingobuzz/core/Extension/extension.dart';
import 'package:lingobuzz/core/services/quiz_services.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../core/common/helpers/app_logger.dart';
import '../../../model/quiz_model.dart';
import '../../../model/word_model.dart';
import '../../Routes/app_routes.dart';
import '../../core/common/app_text.dart';
import '../../core/common/utils/Themes/app_color.dart';
import '../../core/common/utils/app_images.dart';
import '../../core/common/widgets/custamContainer.dart';
import '../../core/common/widgets/custom_Button.dart';
import '../AuthController/auth_controller.dart';

class QuizController extends GetxController {
  final authController = Get.find<AuthController>();
  final wordController = Get.find<WordController>();
  final settingController = Get.find<SettingController>();
  final QuizService _quizService = QuizService();

  final player = AudioPlayer();


  final RxList<QuizQuestion> questions = <QuizQuestion>[].obs;
  final RxInt currentPage = 0.obs;
  final RxInt score = 0.obs;

  // For UI
  final PageController pageController = PageController();
  final RxList<int?> selectedAnswers = <int?>[].obs;

  int get totalQuestions => questions.length;
  double get completionPercentage =>
      totalQuestions == 0 ? 0 : (currentPage.value) / totalQuestions;
  bool get isCurrentQuestionAnswered =>
      selectedAnswers[currentPage.value] != null;

  @override
  void onInit() {
    super.onInit();
    generateQuiz();
  }

  void generateQuiz() {
    final seenWords = wordController.seenWordsList;
    questions.clear();
    selectedAnswers.clear();

    if (seenWords.isEmpty) {
      Log.debug("⚠️ No seen words found for quiz.");
      return;
    }

    final learningLang = authController.currentUser.value?.nativeLanguage?.name ?? "English";
    final baseLang = authController.currentUser.value?.currentLearning?.languageName ?? ''; // default fallback

    final shuffled = [...seenWords]..shuffle();
    final selected = shuffled.take(8).toList();

    for (var i = 0; i < selected.length; i++) {
      final correctWord = selected[i];

      // Question will be in learning language (e.g., "Bonjour")
      final questionText = WordModel.getWordByLang(correctWord.wordModel, learningLang);

      // Correct answer will be in base language (e.g., "Hello")
      final correctAnswer = WordModel.getWordByLang(correctWord.wordModel, baseLang);

      // ✅ Validate question and answer are not empty
      if (questionText.isEmpty) {
        Log.debug("❌ ERROR: Empty question text for word ID: ${correctWord.id}");
        continue; // Skip this question
      }
      if (correctAnswer.isEmpty) {
        Log.debug("❌ ERROR: Empty correct answer for word ID: ${correctWord.id}");
        continue; // Skip this question
      }

      // Create 3 random incorrect options (from other words)
      final others = seenWords.where((w) => w.id != correctWord.id).toList()..shuffle();
      final incorrect = others.take(3).map(
            (w) => WordModel.getWordByLang(w.wordModel, baseLang),
      ).toList();

      // ✅ Validate all options are not empty
      final validIncorrect = <String>[];
      for (var option in incorrect) {
        if (option.isEmpty) {
          Log.debug("❌ ERROR: Empty option found for word ID: ${correctWord.id}");
        } else {
          validIncorrect.add(option);
        }
      }

      // Ensure we have at least 3 valid incorrect options
      if (validIncorrect.length < 3) {
        Log.debug("⚠️ WARNING: Not enough valid options for word ID: ${correctWord.id}. Skipping.");
        continue;
      }

      final allOptions = [...validIncorrect.take(3), correctAnswer]..shuffle();
      final correctIndex = allOptions.indexOf(correctAnswer);


      questions.add(
        QuizQuestion(
          id: correctWord.id,
          question: questionText,           // e.g., "Bonjour"
          options: allOptions,              // e.g., ["Hello", "Bye", "Thanks", "Hey"]
          correctAnswerIndex: correctIndex,
          correctAnswer: correctAnswer,     // e.g., "Hello"
        ),
      );
      selectedAnswers.add(null);
    }

    Log.debug("✅ Generated ${questions.length} quiz questions with language separation.");
  }


  void selectAnswer(int questionIndex, int optionIndex) {
    selectedAnswers[questionIndex] = optionIndex;
  }

  void goToNextQuestion() {
    if (currentPage.value < totalQuestions - 1) {
      currentPage.value++;
      pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Log.debug("🏁 Quiz completed!");
    }
  }



  QuizResultModel getResult() {
    return QuizResultModel.fromScore(
      total: totalQuestions,
      correct: score.value,
    );
  }

  void resetQuiz() {
    // Reset quiz-related values
    questions.clear();
    selectedAnswers.clear();
    currentPage.value = 0;
    score.value = 0;

    // Reset the page controller to first page
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }

    Log.debug("🔄 Quiz has been reset and regenerated.");
  }

  Future<void> showResultBottomSheet(bool isCorrect, BuildContext context) async {
    final questionIndex = currentPage.value;
    final question = questions[questionIndex];

    final learningLang = authController.currentUser.value?.currentLearning?.languageName ?? "";
    final baseLang = authController.currentUser.value?.nativeLanguage?.name ?? "English";

    if(settingController.soundEffects.value){
      Log.debug('🔊 Playing ${isCorrect ? 'celebration' : 'failure'} sound effect. with volume: ${settingController.volume.value}');
      player.setVolume(settingController.volume.value);
      if(isCorrect){
        await player.play(AssetSource('audios/celebrate.wav'));
      }else{
        await player.play(AssetSource('audios/fail.wav'));
      }
    }


    showModalBottomSheet(
      backgroundColor: AppColors.backgroundColor,
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🟡 Top Icon Section
              CustomContainer(
                height: 17.h,
                width: double.infinity,
                imageDecoration: isCorrect
                    ? DecorationImage(image: AssetImage(AppImages.orange))
                    : null,
                child: Image.asset(
                  isCorrect ? AppImages.buzzy : AppImages.buzzysad,
                  height: 15.h,
                ),
              ),

              /// 🟢 Title
              CustomTextWidget(
                title: isCorrect ? 'Amazing Work!' : 'Oops!',
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: isCorrect ? AppColors.green : AppColors.red,
              ),

              2.h.height,

              /// 🟠 Word Pair Container
              CustomContainer(
                height: 9.h,
                width: double.infinity,
                borders: true,
                cir: 10,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomTextWidget(
                          title: question.question, // e.g. "Bonjour"
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        CustomTextWidget(
                          title: question.correctAnswer, // e.g. "Hello"
                          color: AppColors.gray,
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              0.5.h.height,

              /// 🩵 Meaning Sentence
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  children: [
                    CustomTextWidget(
                      textAlign: TextAlign.left,
                      title: 'We say ',
                      color: AppColors.gray,
                    ),
                    CustomTextWidget(
                      textAlign: TextAlign.left,
                      title: '“${question.question}”',
                      fontWeight: FontWeight.w600,
                    ),
                    CustomTextWidget(
                      textAlign: TextAlign.left,
                      title: ' for “${question.correctAnswer}” in $learningLang.',
                      color: AppColors.gray,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              /// 🔵 Continue Button
              MainCustomButton(
                title: 'Continue',
                onTap: () async {
                  Navigator.pop(context);

                  if (isCorrect) score.value++;

                  if (currentPage.value == questions.length - 1) {

                    // Navigate to result page
                    Navigator.pushNamed(
                      context,
                      AppRoutes.practiceTestCompleted,
                    );

                    // ✅ Save quiz result in Firebase
                    final userId = authController.currentUser.value?.uid ?? '';
                    final learningLang = authController.currentUser.value?.currentLearning?.languageName ?? '';

                    final result = getResult();
                    final success = await _quizService.saveQuiz(
                      userId: userId,
                      language: learningLang,
                      result: result,
                      questions: questions,
                    );

                    if (success) {
                      Log.debug("🏁 Quiz saved to Firebase successfully!");
                    }

                  } else {
                    goToNextQuestion();
                  }
                },
              ),

            ],
          ),
        );
      },
    );
  }



}
