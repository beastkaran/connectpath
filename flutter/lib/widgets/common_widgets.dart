import 'package:flutter/material.dart';
import '../theme.dart';

// ─── User Avatar ─────────────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const UserAvatar({super.key, this.imageUrl, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: PPNColors.accent.withOpacity(0.2),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: PPNColors.primary,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onConnect;
  final VoidCallback? onTap;
  final bool showConnectButton;

  const ProfileCard({
    super.key,
    required this.user,
    this.onConnect,
    this.onTap,
    this.showConnectButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: user['profile_image_url'],
                name: user['name'] ?? '',
                radius: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: PPNColors.textDark,
                      ),
                    ),
                    if (user['profession'] != null)
                      Text(
                        user['profession'],
                        style: const TextStyle(
                          color: PPNColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (user['department'] != null)
                      Text(
                        user['department'],
                        style: const TextStyle(color: PPNColors.textMid, fontSize: 12),
                      ),
                    if (user['skills'] != null && user['skills'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          children: user['skills']
                              .toString()
                              .split(',')
                              .take(3)
                              .map<Widget>((s) => Chip(
                                    label: Text(s.trim(), style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              if (showConnectButton && onConnect != null)
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: PPNColors.accent),
                  onPressed: onConnect,
                  tooltip: 'Connect',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PPNColors.textDark,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: PPNColors.accent)),
            ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: PPNColors.textLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PPNColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: PPNColors.textMid, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Loading Shimmer ─────────────────────────────────────────────────────────

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: PPNColors.surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: PPNColors.surface),
                  const SizedBox(height: 8),
                  Container(height: 11, width: 80, color: PPNColors.surface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Connect Toggle Card ──────────────────────────────────────────────────────

class ConnectToggleCard extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const ConnectToggleCard({super.key, required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [PPNColors.accent, const Color(0xFF00A87D)]
              : [PPNColors.textMid, PPNColors.textLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? PPNColors.accent : PPNColors.textMid).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Icon(
          isOpen ? Icons.wifi_tethering : Icons.wifi_tethering_off,
          color: Colors.white,
          size: 32,
        ),
        title: Text(
          isOpen ? 'Open to Connect' : 'Private Mode',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          isOpen
              ? 'You\'re discoverable to nearby professionals'
              : 'You\'re invisible to proximity features',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: Switch(
          value: isOpen,
          onChanged: (_) => onToggle(),
          activeColor: Colors.white,
          activeTrackColor: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }
}
