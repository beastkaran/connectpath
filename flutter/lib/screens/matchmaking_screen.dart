import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results =
          await context.read<AppState>().api.getMatchSuggestions();
      if (mounted) setState(() { _suggestions = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(
        title: const Text('Smart Matchmaking'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // ── Explainer banner ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complementary Matching',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      SizedBox(height: 3),
                      Text(
                        'We match your skills with professionals who complement them — coders with designers, analysts with marketers.',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: _loading
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => const LoadingCard())
                : _suggestions.isEmpty
                    ? const EmptyState(
                        icon: Icons.auto_awesome_outlined,
                        title: 'No suggestions yet',
                        subtitle:
                            'Add your skills and profession to your profile to get smart match suggestions.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: PPNColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _suggestions.length,
                          itemBuilder: (_, i) => ProfileCard(
                            user: _suggestions[i],
                            showConnectButton: true,
                            onConnect: () =>
                                _sendRequest(_suggestions[i]['id']),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                    userId: _suggestions[i]['id']),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(int userId) async {
    try {
      await context.read<AppState>().api.sendConnectionRequest(userId);
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
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: PPNColors.danger),
        );
      }
    }
  }
}
