class AppInfoModel {
  String? appstoreUrl;
  String? playstoreUrl;
  String? sendEmailPassword;
  String? senderEmail;

  AppInfoModel({
    this.appstoreUrl,
    this.playstoreUrl,
    this.sendEmailPassword,
    this.senderEmail,
  });

  // Factory constructor to create an instance from Firestore document
  factory AppInfoModel.fromMap(Map<String, dynamic> map) {
    return AppInfoModel(
      appstoreUrl: map['appstore_url'] as String?,
      playstoreUrl: map['playstore_url'] as String?,
      sendEmailPassword: map['sendEmailPassword'] as String?,
      senderEmail: map['senderEmail'] as String?,
    );
  }

  // Convert the model to a map (useful for saving/updating Firestore)
  Map<String, dynamic> toMap() {
    return {
      'appstore_url': appstoreUrl,
      'playstore_url': playstoreUrl,
      'sendEmailPassword': sendEmailPassword,
      'senderEmail': senderEmail,
    };
  }
}
