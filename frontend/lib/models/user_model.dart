class DietaryPreferences {
  final List<String> dietary;
  final List<String> allergies;
  final String language;
  final bool notificationsEnabled;

  const DietaryPreferences({
    this.dietary = const [],
    this.allergies = const [],
    this.language = 'tr',
    this.notificationsEnabled = true,
  });

  factory DietaryPreferences.fromJson(Map<String, dynamic> json) =>
      DietaryPreferences(
        dietary: List<String>.from(json['dietary'] ?? []),
        allergies: List<String>.from(json['allergies'] ?? []),
        language: json['language'] ?? 'tr',
        notificationsEnabled: json['notifications_enabled'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'dietary': dietary,
        'allergies': allergies,
        'language': language,
        'notifications_enabled': notificationsEnabled,
      };

  DietaryPreferences copyWith({
    List<String>? dietary,
    List<String>? allergies,
    String? language,
    bool? notificationsEnabled,
  }) =>
      DietaryPreferences(
        dietary: dietary ?? this.dietary,
        allergies: allergies ?? this.allergies,
        language: language ?? this.language,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DietaryPreferences preferences;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.preferences = const DietaryPreferences(),
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] ?? '',
        email: json['email'] ?? '',
        displayName: json['display_name'] ?? '',
        preferences: json['preferences'] != null
            ? DietaryPreferences.fromJson(json['preferences'])
            : const DietaryPreferences(),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'display_name': displayName,
        'preferences': preferences.toJson(),
      };
}
