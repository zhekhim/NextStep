class SkillCatalogItem {
  const SkillCatalogItem({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final String category;

  factory SkillCatalogItem.fromMap(Map<String, dynamic> map) {
    return SkillCatalogItem(
      id: map['id'].toString(),
      name: map['skill_name'].toString(),
      category: map['category'].toString(),
    );
  }
}

class UserSkill {
  const UserSkill({
    required this.id,
    required this.userId,
    required this.skill,
    required this.level,
  });

  static const levels = <String>['Beginner', 'Intermediate', 'Advanced'];

  final String id;
  final String userId;
  final SkillCatalogItem skill;
  final String level;

  factory UserSkill.fromMap(Map<String, dynamic> map) {
    final relatedSkill = map['skills'];
    final skillMap = relatedSkill is List
        ? Map<String, dynamic>.from(relatedSkill.single as Map)
        : Map<String, dynamic>.from(relatedSkill as Map);

    return UserSkill(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      skill: SkillCatalogItem.fromMap(skillMap),
      level: map['skill_level'].toString(),
    );
  }
}
