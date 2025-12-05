import 'package:get/get.dart';

import '../core/common/helpers/app_logger.dart';
import '../core/services/app_info_services.dart';
import '../model/app_info_model.dart';

class AppInfoController extends GetxController {
  var appInfo = Rx<AppInfoModel?>(null);
  final AppInfoService _service = AppInfoService();

  @override
  void onInit() {
    super.onInit();
    loadAppInfo(); // Fetch AppInfo automatically on controller init
  }

  // Fetch and store AppInfo in Rx
  Future<void> loadAppInfo() async {
    AppInfoModel? info = await _service.fetchAppInfo();
    if (info != null) {
      appInfo.value = info;
      Log.info('AppInfo loaded: ${info.toMap()}');
    }
  }
}
