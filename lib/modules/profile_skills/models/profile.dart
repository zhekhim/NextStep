class Profile {
  const Profile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.university,
    this.major,
    this.yearOfStudy,
    this.preferredEmploymentState,
    this.avatarUrl,
    this.title,
    this.bio,
    this.targetedJobRoles = const [],
  });

  final String userId;
  final String fullName;
  final String email;
  final String? university;
  final String? major;
  final String? yearOfStudy;
  final String? preferredEmploymentState;
  final String? avatarUrl;
  final String? title;
  final String? bio;
  final List<String> targetedJobRoles;

  Profile copyWith({
    String? fullName,
    String? university,
    String? major,
    String? yearOfStudy,
    String? title,
    String? bio,
    List<String>? targetedJobRoles,
    String? avatarUrl,
  }) {
    return Profile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email,
      university: university ?? this.university,
      major: major ?? this.major,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      preferredEmploymentState: preferredEmploymentState,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      targetedJobRoles: targetedJobRoles ?? this.targetedJobRoles,
    );
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
