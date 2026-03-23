import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'crossed_paths_screen.dart';
import 'events_screen.dart';
import 'alumni_screen.dart';
import 'connections_screen.dart';
import 'profile_screen.dart';
import 'matchmaking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardTab(),
    CrossedPathsScreen(),
    EventsScreen(),
    ConnectionsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: PPNColors.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'Paths',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Network',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<Map<String, dynamic>> _suggestions = [];
  int _pendingCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AppState>().api;
    try {
      final results = await Future.wait([
        api.getMatchSuggestions(),
        api.getPendingConnections(),
      ]);
      if (mounted) {
        setState(() {
          _suggestions = (results[0] as List).cast<Map<String, dynamic>>();
          _pendingCount = (results[1] as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final name = profile?['name'] ?? 'there';

    return Scaffold(
      backgroundColor: PPNColors.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: PPNColors.accent,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: PPNColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [PPNColors.primary, Color(0xFF2D4A8A)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${name.split(' ').first} 👋',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile?['profession'] ?? 'ConnectPath Member',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                              UserAvatar(
                                imageUrl: profile?['profile_image_url'],
                                name: name,
                                radius: 24,
                              ),
                            ],
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
                  const SizedBox(height: 16),

                  // ── Connect Toggle ──
                  ConnectToggleCard(
                    isOpen: state.isOpenToConnect,
                    onToggle: () => state.toggleVisibility(),
                  ),

                  // ── Quick actions ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      children: [
                        _QuickAction(
                          icon: Icons.radar,
                          label: 'Crossed\nPaths',
                          color: PPNColors.accent,
                          onTap: () => _navigateTo(context, 1),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.event,
                          label: 'Upcoming\nEvents',
                          color: const Color(0xFF5B6EF5),
                          onTap: () => _navigateTo(context, 2),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.school,
                          label: 'Alumni\nSearch',
                          color: const Color(0xFFFF8C42),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AlumniScreen())),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.auto_awesome,
                          label: 'Match-\nmaking',
                          color: const Color(0xFF9B59B6),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MatchmakingScreen())),
                        ),
                      ],
                    ),
                  ),

                  // ── Pending requests banner ──
                  if (_pendingCount > 0)
                    GestureDetector(
                      onTap: () => _navigateTo(context, 3),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PPNColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PPNColors.warning.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PPNColors.warning.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active,
                                  color: PPNColors.warning, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_pendingCount pending connection request${_pendingCount > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: PPNColors.textDark),
                                  ),
                                  const Text('Tap to review',
                                      style: TextStyle(
                                          color: PPNColors.textMid, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: PPNColors.textMid),
                          ],
                        ),
                      ),
                    ),

                  // ── Suggestions ──
                  SectionHeader(title: '✨ Suggested for You'),
                  if (_loading)
                    ...List.generate(3, (_) => const LoadingCard())
                  else if (_suggestions.isEmpty)
                    const EmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'No suggestions yet',
                      subtitle: 'Update your skills and profession to get matched',
                    )
                  else
                    ..._suggestions.take(5).map((u) => ProfileCard(
                          user: u,
                          showConnectButton: true,
                          onConnect: () => _sendRequest(u['id']),
                          onTap: () => _viewProfile(context, u['id']),
                        )),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    homeState?.setState(() => homeState._currentIndex = index);
  }

  Future<void> _sendRequest(int userId) async {
    try {
      await context.read<AppState>().api.sendConnectionRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent!'),
            backgroundColor: PPNColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: PPNColors.danger),
        );
      }
    }
  }

  void _viewProfile(BuildContext context, int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
