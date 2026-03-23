import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';

class AlumniScreen extends StatefulWidget {
  const AlumniScreen({super.key});

  @override
  State<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends State<AlumniScreen> {
  final _searchCtrl = TextEditingController();
  final _deptCtrl   = TextEditingController();
  final _skillCtrl  = TextEditingController();
  int? _gradYear;

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _deptCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() { _loading = true; _searched = true; });
    try {
      final results = await context.read<AppState>().api.searchAlumni(
        name: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
        skill: _skillCtrl.text.trim().isEmpty ? null : _skillCtrl.text.trim(),
        graduationYear: _gradYear,
      );
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PPNColors.surface,
      appBar: AppBar(title: const Text('Alumni Search')),
      body: Column(
        children: [
          // ── Search panel ──
          Container(
            color: PPNColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: PPNColors.accent, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _deptCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _filterDecoration('Department'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _skillCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _filterDecoration('Skill'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _filterDecoration('Grad Year'),
                        onChanged: (v) => _gradYear = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search'),
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
                    itemBuilder: (_, __) => const LoadingCard())
                : !_searched
                    ? const EmptyState(
                        icon: Icons.school_outlined,
                        title: 'Search the alumni network',
                        subtitle:
                            'Find students and professionals by name, department, skill, or graduation year.',
                      )
                    : _results.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off,
                            title: 'No results found',
                            subtitle: 'Try different filters or a broader search.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _results.length,
                            itemBuilder: (_, i) => ProfileCard(
                              user: _results[i],
                              showConnectButton: true,
                              onConnect: () => _sendRequest(_results[i]['id']),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfileScreen(userId: _results[i]['id']),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
    filled: true,
    fillColor: Colors.white.withOpacity(0.1),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PPNColors.accent),
    ),
  );

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
          SnackBar(content: Text(e.toString()), backgroundColor: PPNColors.danger),
        );
      }
    }
  }
}
