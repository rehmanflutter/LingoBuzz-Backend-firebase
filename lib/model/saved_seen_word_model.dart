import 'package:cloud_firestore/cloud_firestore.dart';
import 'word_model.dart';

class SavedSeenWordModel {
  final String id;
  final WordModel wordModel;
  final String? level;
  final DateTime? dateTime; // seenDateTime OR savedDateTime
  final bool isSaved; // true = saved word, false = seen word

  SavedSeenWordModel({
    required this.id,
    required this.wordModel,
    this.level,
    required this.dateTime,
    required this.isSaved,
  });

  /// ✅ Create from Firestore document snapshot
  factory SavedSeenWordModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        required bool isSaved,
      }) {
    final data = doc.data() ?? {};

    // Extract wordModel map
    final wordModelData = data['wordModel'] as Map<String, dynamic>? ?? {};

    return SavedSeenWordModel(
      id: data['id'] ?? doc.id,
      wordModel: WordModel.fromJson(wordModelData, data['id'] ?? doc.id),
      level: data['level'] ?? '',
      dateTime: (data[isSaved ? 'savedDateTime' : 'seenDateTime'] as Timestamp?)?.toDate(),
      isSaved: isSaved,
    );
  }

  /// ✅ Convert model to JSON (for writing to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordModel': wordModel.toJson(),
      'level': level,
      if (dateTime != null)
        (isSaved ? 'savedDateTime' : 'seenDateTime'): Timestamp.fromDate(dateTime!),
    };
  }

  /// ✅ Create from a Map (for local reads)
  factory SavedSeenWordModel.fromJson(Map<String, dynamic> json, {required bool isSaved}) {
    final wordModelData = json['wordModel'] as Map<String, dynamic>? ?? {};

    return SavedSeenWordModel(
      id: json['id'] ?? '',
      wordModel: WordModel.fromJson(wordModelData, json['id'] ?? ''),
      level: json['level'] ?? '',
      dateTime: (json[isSaved ? 'savedDateTime' : 'seenDateTime'] is Timestamp)
          ? (json[isSaved ? 'savedDateTime' : 'seenDateTime'] as Timestamp).toDate()
          : json[isSaved ? 'savedDateTime' : 'seenDateTime'],
      isSaved: isSaved,
    );
  }

  /// ✅ Copy with modification
  SavedSeenWordModel copyWith({
    String? id,
    WordModel? wordModel,
    String? level,
    DateTime? dateTime,
    bool? isSaved,
  }) {
    return SavedSeenWordModel(
      id: id ?? this.id,
      wordModel: wordModel ?? this.wordModel,
      level: level ?? this.level,
      dateTime: dateTime ?? this.dateTime,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}