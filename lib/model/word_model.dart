class WordModel {
  final String id; // Document ID
  final String? chinese;
  final String? english;
  final String? french;
  final String? german;
  final String? italian;
  final String? korean;
  final String? portuguese;
  final String? spanish;
  final String? japanese;
  // Add any other language fields you have

  WordModel({
    required this.id,
    this.chinese,
    this.english,
    this.french,
    this.german,
    this.italian,
    this.korean,
    this.portuguese,
    this.spanish,
    this.japanese,
  });

  factory WordModel.fromJson(Map<String, dynamic> json, String docId) {
    return WordModel(
      id: docId,
      chinese: json['chinese'] as String?,
      english: json['english'] as String?,
      french: json['french'] as String?,
      german: json['german'] as String?,
      italian: json['italian'] as String?,
      korean: json['korean'] as String?,
      portuguese: json['portuguese'] as String?,
      spanish: json['spanish'] as String?,
      japanese: json['japanese'] as String?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chinese': chinese,
      'english': english,
      'french': french,
      'german': german,
      'italian': italian,
      'korean': korean,
      'portuguese': portuguese,
      'spanish': spanish,
      'japanese': japanese
    };
  }

  WordModel copyWith({
    String? id,
    String? chinese,
    String? english,
    String? french,
    String? german,
    String? italian,
    String? korean,
    String? portuguese,
    String? spanish,
    String? urdu,
    String? arabic,
    String? hindi,
    String? japanese,
    String? russian,
  }) {
    return WordModel(
      id: id ?? this.id,
      chinese: chinese ?? this.chinese,
      english: english ?? this.english,
      french: french ?? this.french,
      german: german ?? this.german,
      italian: italian ?? this.italian,
      korean: korean ?? this.korean,
      portuguese: portuguese ?? this.portuguese,
      spanish: spanish ?? this.spanish,
      japanese: japanese ?? this.japanese,
    );
  }

  @override
  String toString() {
    return 'WordModel(id: $id, english: $english, german: $german)';
  }

  /// Helper: get word by language string
  static String getWordByLang(WordModel word, String lang) {
    switch (lang.toLowerCase()) {
      case 'german':
        return word.german ?? '';
      case 'english':
        return word.english ?? '';
      case 'french':
        return word.french ?? '';
      case 'italian':
        return word.italian ?? '';
      case 'spanish':
        return word.spanish ?? '';
      case 'chinese':
        return word.chinese ?? '';
      case 'korean':
        return word.korean ?? '';
      case 'portuguese':
        return word.portuguese ?? '';
      case 'japanese':
        return word.japanese ?? '';
      default:
        return '';
    }
  }
}