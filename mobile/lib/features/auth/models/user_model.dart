class UserModel {
  final String id;
  final String email;
  final String? username;
  final String fullName;
  final String? dateOfBirth;
  final int? age;
  final String preferredMeasurement;
  final String? assessmentCompletedAt;
  final String? subscriptionTier;

  const UserModel({
    required this.id,
    required this.email,
    this.username,
    required this.fullName,
    this.dateOfBirth,
    this.age,
    this.preferredMeasurement = 'metric',
    this.assessmentCompletedAt,
    this.subscriptionTier = 'free',
  });

  String get displayHandle => username != null && username!.isNotEmpty
      ? (username!.startsWith('@') ? username! : '@$username')
      : (fullName.isNotEmpty ? fullName : email);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map ? json['profile'] as Map<String, dynamic> : {};
    final firstName = profile['firstName'] ?? json['firstName'] ?? '';
    final lastName = profile['lastName'] ?? json['lastName'] ?? '';
    final rawFullName = json['fullName'] as String?;
    final derivedName = ('$firstName $lastName').trim();
    final fullName = (rawFullName != null && rawFullName.isNotEmpty)
        ? rawFullName
        : (derivedName.isNotEmpty ? derivedName : (json['email'] as String? ?? ''));

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      fullName: fullName,
      dateOfBirth: profile['dateOfBirth'] as String? ?? json['dateOfBirth'] as String?,
      age: json['age'] as int?,
      preferredMeasurement: profile['unitSystem'] as String? ?? json['preferredMeasurement'] as String? ?? 'metric',
      assessmentCompletedAt: json['assessmentCompletedAt'] as String?,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'preferredMeasurement': preferredMeasurement,
      'assessmentCompletedAt': assessmentCompletedAt,
      'subscriptionTier': subscriptionTier,
    };
  }
}

