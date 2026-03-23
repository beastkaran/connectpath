import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pending   = [];
  List<Map<String, dynamic>> _accepted  = [];
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppState>().api;
      final results = await Future.wait([
        api.getPendingConnections(),
        api.getAcceptedConnections(),
      ]);
      if (mounted) {
        setState(() {
          _pending  = results[0];
          _accepted = results[1];
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(
        title: const Text('My Network'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: PPNColors.accent,
          unselectedLabelColor: Colors.white60,
          indicatorColor: PPNColors.accent,
          tabs: [
            Tab(text: 'Requests${_pending.isEmpty ? '' : ' (${_pending.length})'}'),
            Tab(text: 'Connections${_accepted.isEmpty ? '' : ' (${_accepted.length})'}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildAcceptedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_loading) {
      return ListView.builder(itemCount: 3, itemBuilder: (_, __) => const LoadingCard());
    }
    if (_pending.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No pending requests',
        subtitle: 'When someone sends you a connection request, it\'ll appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: PPNColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _pending.length,
        itemBuilder: (_, i) => _PendingRequestCard(
          request: _pending[i],
          onRespond: (accept) => _respond(_pending[i]['id'], accept),
        ),
      ),
    );
  }

  Widget _buildAcceptedTab() {
    if (_loading) {
      return ListView.builder(itemCount: 3, itemBuilder: (_, __) => const LoadingCard());
    }
    if (_accepted.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'Your network is empty',
        subtitle:
            'Start connecting through Crossed Paths, Alumni Search, or Matchmaking.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: PPNColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _accepted.length,
        itemBuilder: (_, i) => ProfileCard(
          user: _accepted[i],
          showConnectButton: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: _accepted[i]['id']),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _respond(int connectionId, bool accept) async {
    try {
      await context.read<AppState>().api.respondToConnection(connectionId, accept);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Connection accepted!' : 'Request declined'),
            backgroundColor: accept ? PPNColors.success : PPNColors.textMid,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: PPNColors.danger),
        );
      }
    }
  }
}

// ─── Pending Request Card ──────────────────────────────────────────────────────

class _PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final void Function(bool) onRespond;

  const _PendingRequestCard({required this.request, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    final sender = request['sender'] as Map<String, dynamic>? ?? {};
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  imageUrl: sender['profile_image_url'],
                  name: sender['name'] ?? '',
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sender['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: PPNColors.textDark)),
                      if (sender['profession'] != null)
                        Text(sender['profession'],
                            style: const TextStyle(
                                color: PPNColors.accent, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            if (request['message'] != null &&
                request['message'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PPNColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote,
                        size: 16, color: PPNColors.textLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request['message'],
                        style: const TextStyle(
                            color: PPNColors.textMid,
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onRespond(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PPNColors.danger,
                      side: BorderSide(color: PPNColors.danger.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onRespond(true),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
