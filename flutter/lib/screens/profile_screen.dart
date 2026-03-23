import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OWN PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _badges = [];
  bool _loadingBadges = true;
  void _showImageUrlDialog(BuildContext context) {
  final state = context.read<AppState>();
  final controller = TextEditingController(
    text: state.profile?['profile_image_url'] ?? '',
  );
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update Profile Picture'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Paste image URL here',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final url = controller.text.trim();
            if (url.isEmpty) return;
            try {
              await state.api.updateProfileImage(url);
              await state.refreshProfile();
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated!')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await context.read<AppState>().api.getMyBadges();
      if (mounted) setState(() { _badges = badges; _loadingBadges = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingBadges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state   = context.watch<AppState>();
    final profile = state.profile ?? {};

    return Scaffold(
      backgroundColor: PPNColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: PPNColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _openEditSheet(context, profile),
                tooltip: 'Edit profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _confirmLogout(context),
                tooltip: 'Sign out',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [PPNColors.primary, Color(0xFF1E3A6E)],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                            children: [
                              UserAvatar(
                                imageUrl: profile['profile_image_url'],
                                name: profile['name'] ?? '',
                                radius: 40,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showImageUrlDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: PPNColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Text(
                          profile['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (profile['profession'] != null)
                          Text(
                            profile['profession'],
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Connect Toggle ──
                ConnectToggleCard(
                  isOpen: state.isOpenToConnect,
                  onToggle: () => state.toggleVisibility(),
                ),

                // ── Info card ──
                _ProfileInfoCard(profile: profile),

                // ── Skills ──
                if (profile['skills'] != null &&
                    profile['skills'].toString().isNotEmpty) ...[
                  const SectionHeader(title: 'Skills'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile['skills']
                          .toString()
                          .split(',')
                          .map<Widget>((s) => Chip(label: Text(s.trim())))
                          .toList(),
                    ),
                  ),
                ],

                // ── Badges ──
                const SectionHeader(title: '🏅 Badges'),
                _loadingBadges
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: PPNColors.accent),
                        ),
                      )
                    : _badges.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No badges earned yet. Attend events, grow your network, and complete your profile to earn them!',
                              style: TextStyle(
                                  color: PPNColors.textMid, fontSize: 14),
                            ),
                          )
                        : SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _badges.length,
                              itemBuilder: (_, i) =>
                                  _BadgeChip(badge: _badges[i]),
                            ),
                          ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: PPNColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Info Card ─────────────────────────────────────────────────────

class _ProfileInfoCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile['bio'] != null &&
                profile['bio'].toString().isNotEmpty) ...[
              const Text('About',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: PPNColors.textDark)),
              const SizedBox(height: 8),
              Text(profile['bio'],
                  style: const TextStyle(
                      color: PPNColors.textMid, fontSize: 14, height: 1.5)),
              const Divider(height: 24),
            ],
            if (profile['course'] != null)
              _Row(icon: Icons.school_outlined, text: profile['course']),
            if (profile['department'] != null)
              _Row(icon: Icons.apartment_outlined, text: profile['department']),
            if (profile['graduation_year'] != null)
              _Row(
                  icon: Icons.calendar_today_outlined,
                  text: 'Class of ${profile['graduation_year']}'),
            _Row(icon: Icons.email_outlined, text: profile['email'] ?? ''),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: PPNColors.textLight),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: PPNColors.textMid, fontSize: 14))),
        ],
      ),
    );
  }
}

// ─── Badge Chip ───────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final Map<String, dynamic> badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PPNColors.badge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PPNColors.badge.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.military_tech, color: PPNColors.badge, size: 32),
          const SizedBox(height: 6),
          Text(
            badge['name'] ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: PPNColors.textDark),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileSheet({super.key, required this.profile});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _profCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _deptCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl   = TextEditingController(text: p['name']?.toString() ?? '');
    _profCtrl   = TextEditingController(text: p['profession']?.toString() ?? '');
    _bioCtrl    = TextEditingController(text: p['bio']?.toString() ?? '');
    _skillsCtrl = TextEditingController(text: p['skills']?.toString() ?? '');
    _courseCtrl = TextEditingController(text: p['course']?.toString() ?? '');
    _deptCtrl   = TextEditingController(text: p['department']?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _profCtrl, _bioCtrl, _skillsCtrl, _courseCtrl, _deptCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AppState>().api.updateProfile(
        name: _nameCtrl.text.trim(),
        profession: _profCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        skills: _skillsCtrl.text.trim(),
        course: _courseCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
      );
      await context.read<AppState>().refreshProfile();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated!'),
              backgroundColor: PPNColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: PPNColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PPNColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Edit Profile',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: PPNColors.textDark)),
            const SizedBox(height: 20),
            _field('Full Name', _nameCtrl, Icons.person_outline),
            _field('Profession / Role', _profCtrl, Icons.work_outline),
            _field('Course / Degree', _courseCtrl, Icons.school_outlined),
            _field('Department', _deptCtrl, Icons.apartment_outlined),
            _field('Skills (comma separated)', _skillsCtrl, Icons.star_outline),
            _field('Bio', _bioCtrl, Icons.notes, maxLines: 4),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines == 1 ? Icon(icon) : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER PROFILE SCREEN (view another user's profile)
// ─────────────────────────────────────────────────────────────────────────────

class UserProfileScreen extends StatefulWidget {
  final int userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await context.read<AppState>().api.getUserProfile(widget.userId);
      if (mounted) setState(() { _profile = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    setState(() => _requesting = true);
    try {
      await context.read<AppState>().api.sendConnectionRequest(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Connection request sent!'),
              backgroundColor: PPNColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: PPNColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(
        title: Text(_profile?['name'] ?? 'Profile'),
        actions: [
          if (!_loading && _profile != null)
            IconButton(
              icon: _requesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.person_add_outlined),
              onPressed: _requesting ? null : _connect,
              tooltip: 'Connect',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PPNColors.accent))
          : _profile == null
              ? const EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Profile not found',
                  subtitle: 'This user may not exist or has restricted visibility.',
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: PPNColors.primary,
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Column(
                          children: [
                            UserAvatar(
                              imageUrl: _profile!['profile_image_url'],
                              name: _profile!['name'] ?? '',
                              radius: 44,
                            ),
                            const SizedBox(height: 14),
                            Text(_profile!['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                            if (_profile!['profession'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(_profile!['profession'],
                                    style: TextStyle(
                                        color: PPNColors.accent,
                                        fontSize: 15)),
                              ),
                          ],
                        ),
                      ),

                      _ProfileInfoCard(profile: _profile!),

                      if (_profile!['skills'] != null &&
                          _profile!['skills'].toString().isNotEmpty) ...[
                        const SectionHeader(title: 'Skills'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _profile!['skills']
                                .toString()
                                .split(',')
                                .map<Widget>((s) => Chip(label: Text(s.trim())))
                                .toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
