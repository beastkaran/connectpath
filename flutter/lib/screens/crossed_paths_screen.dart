import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';

class CrossedPathsScreen extends StatefulWidget {
  const CrossedPathsScreen({super.key});

  @override
  State<CrossedPathsScreen> createState() => _CrossedPathsScreenState();
}

class _CrossedPathsScreenState extends State<CrossedPathsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _paths = [];
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<AppState>().api;
      final results = await api.getCrossedPaths();
      if (mounted) setState(() { _paths = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isOpen = context.watch<AppState>().isOpenToConnect;

    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(
        title: const Text('Crossed Paths'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status card ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOpen
                    ? [PPNColors.primary, const Color(0xFF2D4A8A)]
                    : [PPNColors.textMid, const Color(0xFF8090A4)],
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
                  child: Icon(
                    isOpen ? Icons.radar : Icons.radar_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen ? 'Radar Active' : 'Radar Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isOpen
                            ? 'Showing professionals within 50m in the last 24h'
                            : 'Enable "Open to Connect" to discover nearby people',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Results ──
          Expanded(
            child: _loading
                ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => const LoadingCard(),
                  )
                : _error != null
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: 'Something went wrong',
                        subtitle: _error!,
                      )
                    : !isOpen
                        ? const EmptyState(
                            icon: Icons.wifi_tethering_off,
                            title: 'You\'re in private mode',
                            subtitle:
                                'Switch to "Open to Connect" from your home screen to start discovering nearby professionals.',
                          )
                        : _paths.isEmpty
                            ? const EmptyState(
                                icon: Icons.radar_outlined,
                                title: 'No crossed paths yet',
                                subtitle:
                                    'When you\'re near other ConnectPath members, they\'ll appear here. Try exploring campus or an event!',
                              )
                            : RefreshIndicator(
                                onRefresh: _load,
                                color: PPNColors.accent,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: _paths.length,
                                  itemBuilder: (ctx, i) {
                                    final u = _paths[i];
                                    return ProfileCard(
                                      user: u,
                                      showConnectButton: true,
                                      onConnect: () => _sendRequest(ctx, u['id']),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              UserProfileScreen(userId: u['id']),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(BuildContext ctx, int userId) async {
    // Show message dialog
    String? message;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Connection Request',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a personal message (optional):'),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => message = v,
              decoration: const InputDecoration(
                hintText: 'e.g. Hi, we crossed paths at the library today!',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context
          .read<AppState>()
          .api
          .sendConnectionRequest(userId, message: message);
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
