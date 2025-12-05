import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingobuzz/model/language_model.dart';

class LanguageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'languages';

  // Fetch all languages from Firebase
  Future<List<LanguageModel>> fetchLanguages() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection(_collectionName).get();

      return querySnapshot.docs.map((doc) {
        return LanguageModel.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch languages: $e');
    }
  }

  // Fetch a single language by ID
  Future<LanguageModel?> fetchLanguageById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return LanguageModel.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch language: $e');
    }
  }

  // Stream languages for real-time updates
  Stream<List<LanguageModel>> languagesStream() {
    return _firestore.collection(_collectionName).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
        return LanguageModel.fromJson(
          doc.data(),
          id: doc.id,
        );
      }).toList(),
    );
  }

  // Fetch language by code
  Future<LanguageModel?> fetchLanguageByCode(String code) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return LanguageModel.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch language by code: $e');
    }
  }
}