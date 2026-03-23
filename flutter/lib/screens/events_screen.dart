import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _events = [];
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await context.read<AppState>().api.getEvents();
      if (mounted) setState(() { _events = events; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(title: const Text('Events')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: PPNColors.accent,
        child: _loading
            ? ListView.builder(
                itemCount: 4, itemBuilder: (_, __) => const LoadingCard())
            : _events.isEmpty
                ? const EmptyState(
                    icon: Icons.event_outlined,
                    title: 'No upcoming events',
                    subtitle: 'Check back later for approved university events.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _events.length,
                    itemBuilder: (_, i) => _EventCard(
                      event: _events[i],
                      onRefresh: _load,
                    ),
                  ),
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onRefresh;

  const _EventCard({required this.event, required this.onRefresh});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _registering = false;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('EEE, d MMM • h:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _register() async {
    setState(() => _registering = true);
    try {
      await context
          .read<AppState>()
          .api
          .registerForEvent(widget.event['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Successfully registered!'),
              backgroundColor: PPNColors.success),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: PPNColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final capacityText =
        e['capacity'] != null ? '${e['capacity']} spots' : 'Open';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: e),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured header strip
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF5B6EF5), PPNColors.accent]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          e['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: PPNColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: PPNColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          capacityText,
                          style: const TextStyle(
                              color: PPNColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                      icon: Icons.access_time_outlined,
                      text: _formatDate(e['start_time']?.toString())),
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: e['location_name'] ?? ''),
                  if (e['organizer'] != null) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                        icon: Icons.person_outline,
                        text: 'Organised by ${e['organizer']}'),
                  ],
                  if (e['description'] != null &&
                      e['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      e['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: PPNColors.textMid, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _registering ? null : _register,
                      icon: _registering
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.how_to_reg_outlined, size: 18),
                      label: Text(_registering ? 'Registering...' : 'RSVP'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: PPNColors.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(color: PPNColors.textMid, fontSize: 13)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<Map<String, dynamic>> _attendees = [];
  bool _loadingAttendees = false;
  bool _isRegistered = false;

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('EEEE, d MMMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return dateStr ?? '';
    }
  }

  Future<void> _loadAttendees() async {
    setState(() => _loadingAttendees = true);
    try {
      final data = await context
          .read<AppState>()
          .api
          .getEventAttendees(widget.event['id']);
      if (mounted) {
        setState(() {
          _attendees = List<Map<String, dynamic>>.from(data['attendees'] ?? []);
          _isRegistered = true;
          _loadingAttendees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAttendees = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: PPNColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(title: Text(e['title'] ?? 'Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: PPNColors.textDark)),
                    const SizedBox(height: 16),
                    _InfoRow(
                        icon: Icons.access_time_outlined,
                        text: _formatDate(e['start_time']?.toString())),
                    const SizedBox(height: 8),
                    _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: e['location_name'] ?? ''),
                    if (e['organizer'] != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.person_outline,
                          text: 'Organised by ${e['organizer']}'),
                    ],
                    if (e['capacity'] != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.group_outlined,
                          text: 'Capacity: ${e['capacity']} people'),
                    ],
                    if (e['description'] != null &&
                        e['description'].toString().isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(e['description'],
                          style: const TextStyle(
                              color: PPNColors.textMid,
                              fontSize: 14,
                              height: 1.6)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // View attendees button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadingAttendees ? null : _loadAttendees,
                icon: _loadingAttendees
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: PPNColors.accent))
                    : const Icon(Icons.people_outline),
                label: const Text('View Attendees'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PPNColors.accent,
                  side: const BorderSide(color: PPNColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            if (_attendees.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('${_attendees.length} Open Attendees',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: PPNColors.textDark)),
              const SizedBox(height: 8),
              ..._attendees.map((u) => ProfileCard(user: u, showConnectButton: false)),
            ],
          ],
        ),
      ),
    );
  }
}
