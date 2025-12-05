class UpgradePlanModel {
  final String title;           // e.g. "Monthly Plan"
  final double price;           // e.g. "$5.59 / month"
  final String planLabel;           // e.g. "$5.59 / month"
  final String billed;          // e.g. "Billed monthly"
  final String save;            // e.g. "Save 17% compared to monthly"
  final bool isPopular;         // To mark “Popular Choice” etc.
  final String description;     // e.g. "Enjoy full, unlimited access with these features"
  final List<String> features;  // Features list (like up to 10 words, etc.)

  UpgradePlanModel({
    required this.title,
    required this.price,
    required this.planLabel,
    required this.billed,
    required this.save,
    this.isPopular = false,
    required this.description,
    required this.features,
  });
}