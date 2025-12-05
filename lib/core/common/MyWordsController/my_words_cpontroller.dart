import 'package:get/get.dart';

class MyWordsCpontroller extends GetxController {
  RxBool saveWords = true.obs;

  List level = ['All', 'A1', 'A2', 'B1', 'B2'];
  RxInt levelSelect = 0.obs;
}
