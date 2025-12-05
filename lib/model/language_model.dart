class LanguageModel {
  final String? id;
  final String? code;
  final String? name;

  LanguageModel({this.id, this.code, this.name});

  factory LanguageModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return LanguageModel(
      id: id ?? json['id'] as String?,
      code: json['code'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'code': code,
      'name': name,
    };
    if (id != null) data['id'] = id;
    return data;
  }

  // ✅ Add equality operator so DropdownButton can compare correctly
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LanguageModel(id: $id, code: $code, name: $name)';
}
