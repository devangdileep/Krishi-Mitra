import 'package:flutter/material.dart';
import 'widgets/premium_widgets.dart';

class SubsidiesScreen extends StatelessWidget {
  const SubsidiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Govt Subsidies',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: colors.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto-Matched', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
                      const Text('Based on your mapped 2.4 acres of Wheat in your profile, you qualify for 3 schemes.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Recommended for you', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          _SubsidyCard(
            title: 'PM-Kisan Samman Nidhi',
            description: 'Income support of ₹6,000 per year in three equal installments.',
            amount: '₹6,000/yr',
            deadline: 'Closes in 12 days',
            matchPercentage: 98,
          ),
          const SizedBox(height: 12),
          _SubsidyCard(
            title: 'Pradhan Mantri Fasal Bima Yojana',
            description: 'Crop insurance scheme providing financial support in case of crop failure.',
            amount: 'Full Cover',
            deadline: 'Open year-round',
            matchPercentage: 92,
          ),
          const SizedBox(height: 12),
          _SubsidyCard(
            title: 'Solar Pump Subsidy (KUSUM)',
            description: 'Up to 60% subsidy on standalone solar agriculture pumps.',
            amount: '60% Off',
            deadline: 'Closes in 30 days',
            matchPercentage: 75,
          ),
        ],
      ),
    );
  }
}

class _SubsidyCard extends StatelessWidget {
  final String title;
  final String description;
  final String amount;
  final String deadline;
  final int matchPercentage;

  const _SubsidyCard({
    required this.title,
    required this.description,
    required this.amount,
    required this.deadline,
    required this.matchPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$matchPercentage% Match',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
              const Spacer(),
              Icon(Icons.timer_outlined, size: 16, color: colors.error),
              const SizedBox(width: 4),
              Text(deadline, style: TextStyle(fontSize: 12, color: colors.error)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply Now via Gov API'),
            ),
          ),
        ],
      ),
    );
  }
}
