class WeekSettings {
  final String id;
  final String weekKey; // Format: YYYY-MM-DD
  final bool isDefinitive;

  WeekSettings({
    required this.id,
    required this.weekKey,
    required this.isDefinitive,
  });

  factory WeekSettings.fromMap(String id, Map<String, dynamic> data) {
    return WeekSettings(
      id: id,
      weekKey: data['weekKey'] ?? '',
      isDefinitive: data['isDefinitive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekKey': weekKey,
      'isDefinitive': isDefinitive,
    };
  }
}
