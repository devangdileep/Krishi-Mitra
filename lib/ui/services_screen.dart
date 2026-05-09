import 'package:flutter/material.dart';
import '../services/api_clients.dart';
import '../theme/app_theme.dart';
import 'marketplace_screen.dart';
import 'subsidies_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({
    super.key,
    required this.api,
    required this.repository,
    required this.userId,
  });

  final SupabaseRestClient api;
  final FarmlandRepository repository;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Agri Services',
          style:
              TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _ServiceCard(
            title: 'Govt Subsidies',
            icon: Icons.account_balance_rounded,
            color: Colors.blueAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubsidiesScreen(
                  repository: repository,
                  userId: userId,
                ),
              ),
            ),
          ),
          _ServiceCard(
            title: 'Peer Market',
            icon: Icons.handshake_rounded,
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MarketplaceScreen(
                  api: api,
                  repository: repository,
                  userId: userId,
                ),
              ),
            ),
          ),
          _ServiceCard(
            title: 'Disease Scanner',
            icon: Icons.document_scanner_rounded,
            color: Colors.teal,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Vision Scanner coming soon!')),
              );
            },
          ),
          _ServiceCard(
            title: 'Community Forum',
            icon: Icons.forum_rounded,
            color: Colors.purpleAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Community Forum coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
