
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../models/user_skill.dart';
import '../repositories/profile_repository.dart';
import '../repositories/skill_repository.dart';
import 'edit_profile_screen.dart';
import 'skill_portfolio_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.profileRepository,
    this.skillRepository,
  });

  final ProfileRepository? profileRepository;
  final SkillRepository? skillRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _profileRepository;
  late final SkillRepository _skillRepository;
  Profile? _profile;
  bool _profileLoading = true;
  bool _profileFailed = false;
  List<UserSkill> _skills = const [];
  bool _skillsLoading = true;
  bool _skillsFailed = false;

  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? ProfileRepository();
    _skillRepository = widget.skillRepository ?? SkillRepository();
    _loadProfile();
    _reloadSkills();
  }

  Future<void> _loadProfile({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _profileLoading = true;
        _profileFailed = false;
      });
    }

    try {
      final profile = await _profileRepository.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileLoading = false;
        _profileFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
        _profileFailed = true;
      });
    }
  }

  Future<void> _openEditProfile(Profile profile) async {
    final updatedProfile = await Navigator.push<Profile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
          profileRepository: _profileRepository,
        ),
      ),
    );
    if (!mounted || updatedProfile == null) return;

    setState(() => _profile = updatedProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  Future<void> _reloadSkills() async {
    setState(() {
      _skillsLoading = true;
      _skillsFailed = false;
    });
    try {
      final skills = await _skillRepository.getUserSkills();
      if (!mounted) return;
      setState(() {
        _skills = skills;
        _skillsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _skillsLoading = false;
        _skillsFailed = true;
      });
    }
  }

  Future<void> _openSkills() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SkillPortfolioScreen(
          skillRepository: _skillRepository,
          onSkillsChanged: (skills) {
            if (mounted) {
              setState(() {
                _skills = skills;
                _skillsLoading = false;
                _skillsFailed = false;
              });
            }
          },
        ),
      ),
    );
    if (mounted) {
      await _reloadSkills();
    }
  }

  void _showNextStep(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be connected in the next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_profileLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A26FF)),
      );
    } else if (_profileFailed || _profile == null) {
      content = _ProfileError(onRetry: () => _loadProfile(showLoading: true));
    } else {
      content = _ProfileContent(
        profile: _profile!,
        skills: _skills,
        skillsLoading: _skillsLoading,
        skillsFailed: _skillsFailed,
        onRetrySkills: _reloadSkills,
        onEditProfile: () => _openEditProfile(_profile!),
        onManageSkills: _openSkills,
        onDeleteAccount: () => _showNextStep('Account deletion'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(child: content),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.skills,
    required this.skillsLoading,
    required this.skillsFailed,
    required this.onRetrySkills,
    required this.onEditProfile,
    required this.onManageSkills,
    required this.onDeleteAccount,
  });

  final Profile profile;
  final List<UserSkill> skills;
  final bool skillsLoading;
  final bool skillsFailed;
  final VoidCallback onRetrySkills;
  final VoidCallback onEditProfile;
  final VoidCallback onManageSkills;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your academic and career identity.',
          style: TextStyle(color: Color(0xFFA8A8A8), fontSize: 14),
        ),
        const SizedBox(height: 24),
        _IdentityCard(profile: profile),
        const SizedBox(height: 20),
        const Text(
          'Academic details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _DetailsCard(profile: profile),
        const SizedBox(height: 20),
        _SkillsPortfolioCard(
          skills: skills,
          isLoading: skillsLoading,
          hasError: skillsFailed,
          onManageSkills: onManageSkills,
          onRetry: onRetrySkills,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Edit Profile'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0007CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Divider(color: Color(0xFF222222)),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onDeleteAccount,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete Account'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFF4D4D),
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF0007CD),
            foregroundImage: profile.avatarUrl == null
                ? null
                : NetworkImage(profile.avatarUrl!),
            child: profile.avatarUrl == null
                ? Text(
                    profile.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillsPortfolioCard extends StatelessWidget {
  const _SkillsPortfolioCard({
    required this.skills,
    required this.isLoading,
    required this.hasError,
    required this.onManageSkills,
    required this.onRetry,
  });

  final List<UserSkill> skills;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onManageSkills;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SKILLS PORTFOLIO',
                      style: TextStyle(
                        color: Color(0xFFA8A8A8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (!isLoading && !hasError)
                    Text(
                      '${skills.length} ${skills.length == 1 ? 'skill' : 'skills'}',
                      style: const TextStyle(
                        color: Color(0xFF1A26FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A26FF),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (hasError)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Unable to load your skills.',
                        style: TextStyle(color: Color(0xFFA8A8A8)),
                      ),
                    ),
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                )
              else if (skills.isEmpty)
                const Text(
                  'No skills added yet.',
                  style: TextStyle(color: Color(0xFFA8A8A8), fontSize: 14),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map(
                        (userSkill) => Chip(
                          label: Text(userSkill.skill.name),
                          backgroundColor: const Color(0xFF222222),
                          side: const BorderSide(color: Color(0xFF333333)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onManageSkills,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF222222),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Manage Skills'),
                ),
              ),
            ],
          ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.account_balance_outlined,
            label: 'University',
            value: profile.university,
          ),
          _DetailRow(
            icon: Icons.menu_book_outlined,
            label: 'Major',
            value: profile.major,
          ),
          _DetailRow(
            icon: Icons.school_outlined,
            label: 'Year of Study',
            value: profile.yearOfStudy == null
                ? null
                : 'Year ${profile.yearOfStudy}',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? 'Not provided';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFA8A8A8), size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: TextStyle(
                        color: value == null
                            ? const Color(0xFF666666)
                            : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 51, color: Color(0xFF222222)),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              color: Color(0xFFA8A8A8),
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load your profile.',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your session and try again.',
              style: TextStyle(color: Color(0xFFA8A8A8)),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
