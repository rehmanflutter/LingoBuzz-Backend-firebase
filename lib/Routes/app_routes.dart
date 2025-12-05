import 'package:flutter/material.dart';
import 'package:lingobuzz/core/common/bottomAppBar/bottom_app_bar.dart';
import 'package:lingobuzz/view/Home/home_screen.dart';
import 'package:lingobuzz/view/MyWords/my_words.dart';
import 'package:lingobuzz/view/Oboarding/onboarding.dart';
import 'package:lingobuzz/view/Quiz/new_words.dart';
import 'package:lingobuzz/view/Quiz/practice_test_completed.dart';
import 'package:lingobuzz/view/Quiz/quiz_question.dart';
import 'package:lingobuzz/view/Quiz/welcon_quiz.dart';
import 'package:lingobuzz/view/Settings/category_selection.dart';
import 'package:lingobuzz/view/Settings/setting.dart';
import 'package:lingobuzz/view/SplashScreen/splash1.dart';
import 'package:lingobuzz/view/UpgradePro/manage_subscription.dart';
import 'package:lingobuzz/view/UpgradePro/upgrade_pro.dart';
import 'package:lingobuzz/view/SplashScreen/splash.dart';
import 'package:lingobuzz/view/UpgradePro/welcome_pro.dart';

import '../view/profile/edit_profile_screen.dart';

class AppRoutes {
  static const String splashPage = '/SplashPage';
  static const String splishScreen = '/SplishScreen';
  static const String oboarding = '/Oboarding';
  static const String homeScreen = '/HomeScreen';
  static const String bottomAppBarScreen = '/BottomAppBarScreen';
  static const String upgradePro = '/UpgradePro';
  static const String welcomeProScreen = '/welcomeProScreen';
  static const String manageSubscription = '/ManageSubscription';
  static const String myWords = '/MyWords';

  static const String setting = '/Setting';
  static const String topicSelection = '/TopicSelection';
  static const String welconQuiz = '/WelconQuiz';
  static const String quizScreen = '/QuizScreen';
  static const String practiceTestCompleted = '/PracticeTestCompleted';
  static const String newWordsLesson = '/NewWordsLesson';
  static const String editProfileScreen = '/EditProfileScreen';
  // static const String testScreenText = '/TestScreenText';
  // static const String testScreenText = '/TestScreenText';

  static Map<String, WidgetBuilder> get routes => {
    splashPage: (_) => SplashPage(),
    splishScreen: (_) => SplashScreen(), ////HomeWidgetExample(), //
    oboarding: (_) => Oboarding(),
    homeScreen: (_) => HomeScreen(),
    bottomAppBarScreen: (_) => BottomAppBarScreen(),
    upgradePro: (_) => UpgradePro(),
    welcomeProScreen: (_) => WelcomeProScreen(),
    manageSubscription: (_) => ManageSubscription(),
    myWords: (_) => MyWords(),
    setting: (_) => Setting(),
    topicSelection: (_) => TopicSelection(),
    welconQuiz: (_) => WelconQuiz(),
    quizScreen: (_) => QuizScreen(),
    practiceTestCompleted: (_) => PracticeTestCompleted(),
    newWordsLesson: (_) => NewWordsLesson(),
    editProfileScreen: (_) => EditProfileScreen()

  };
}
