import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model/app_info_model.dart';
import '../common/helpers/app_logger.dart';

class AppInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _path = '/admins/AppInfo';

  // Fetch AppInfo document
  Future<AppInfoModel?> fetchAppInfo() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.doc(_path).get();

      if (doc.exists && doc.data() != null) {
        return AppInfoModel.fromMap(doc.data()!);
      } else {
        return null;
      }
    } catch (e) {
      Log.debug('Error fetching AppInfo: $e');
      return null;
    }
  }
}
