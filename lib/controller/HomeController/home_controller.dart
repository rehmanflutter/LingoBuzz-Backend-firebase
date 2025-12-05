import 'package:get/get.dart';
import 'package:lingobuzz/model/words_sentences.dart';

class HomeController extends GetxController {
  //   Today's Words/Sentences List
  List<WordsSentences> wordsSentences = [
    WordsSentences(world: 'Bonjour', sentence: 'Hello'),
    WordsSentences(world: 'Merci', sentence: 'Thank you'),
    WordsSentences(
      world: 'J’aime apprendre le français',
      sentence: 'I like learning French',
    ),
  ];
}
