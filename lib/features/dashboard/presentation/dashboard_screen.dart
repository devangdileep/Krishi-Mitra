import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/glassmorphism_container.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: DesignTokens.spaceSm),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient (Premium Feel)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildWelcomeHeader().animate().fade().slideY(
                      begin: 0.2,
                      curve: DesignTokens.defaultCurve,
                      duration: DesignTokens.animationMedium,
                    ),
                const SizedBox(height: DesignTokens.spaceLg),
                _buildQuickStats().animate().fade(delay: 100.ms).slideY(
                      begin: 0.2,
                      curve: DesignTokens.defaultCurve,
                      duration: DesignTokens.animationMedium,
                    ),
                const SizedBox(height: DesignTokens.spaceLg),
                _buildAIInsights().animate().fade(delay: 200.ms).slideY(
                      begin: 0.2,
                      curve: DesignTokens.defaultCurve,
                      duration: DesignTokens.animationMedium,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good Morning, Farmer',
          style: DesignTokens.caption,
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          'Farm Overview',
          style: DesignTokens.heading1.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Crop Health',
            value: '94%',
            icon: Icons.eco,
            color: DesignTokens.accentColor,
          ),
        ),
        SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: _StatCard(
            title: 'Weather Alert',
            value: 'Clear',
            icon: Icons.wb_sunny,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsights() {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white),
              const SizedBox(width: DesignTokens.spaceSm),
              Text(
                'AI Assistant Insights',
                style: DesignTokens.heading2.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(
            'Soil moisture is optimal. Consider applying nitrogen fertilizer within the next 48 hours for maximum yield.',
            style: DesignTokens.body.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismContainer(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(
            value,
            style: DesignTokens.heading1.copyWith(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceXs),
          Text(
            title,
            style: DesignTokens.caption,
          ),
        ],
      ),
    );
  }
}
