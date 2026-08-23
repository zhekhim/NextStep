import 'package:flutter/material.dart';

import '../models/user_skill.dart';

class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.userSkill,
    required this.onEdit,
    required this.onDelete,
  });

  final UserSkill userSkill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userSkill.skill.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${userSkill.level}  •  ${userSkill.skill.category}',
                  style: const TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit ${userSkill.skill.name}',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFA8A8A8)),
          ),
          IconButton(
            tooltip: 'Delete ${userSkill.skill.name}',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4D4D)),
          ),
        ],
      ),
    );
  }
}
