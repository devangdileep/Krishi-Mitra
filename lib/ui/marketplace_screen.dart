import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'widgets/premium_widgets.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Peer-to-Peer Market',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
              tabs: const [
                Tab(text: 'Machinery Rental'),
                Tab(text: 'Labor Hiring'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MachineryTab(),
                  _LaborTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Post Listing'),
      ),
    );
  }
}

class _MachineryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _ListingCard(
          title: 'Mahindra 575 DI Tractor',
          owner: 'Ramesh Kumar (2.4 km away)',
          price: '₹800 / hour',
          imageIcon: Icons.agriculture_rounded,
          tag: 'Available Today',
        ),
        const SizedBox(height: 12),
        _ListingCard(
          title: 'Heavy Duty Rotavator',
          owner: 'Suresh Singh (5.1 km away)',
          price: '₹400 / hour',
          imageIcon: Icons.settings_applications_rounded,
          tag: 'Available Tomorrow',
        ),
        const SizedBox(height: 12),
        _ListingCard(
          title: 'Water Pump 5HP',
          owner: 'Vikash Farm (8.0 km away)',
          price: '₹150 / day',
          imageIcon: Icons.water_drop_rounded,
          tag: 'Available Today',
        ),
      ],
    );
  }
}

class _LaborTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _ListingCard(
          title: 'Harvesting Laborers (5 people)',
          owner: 'Requested by: Anil (1.2 km away)',
          price: '₹500 / person / day',
          imageIcon: Icons.group_rounded,
          tag: 'Needs next week',
          isRequest: true,
        ),
        const SizedBox(height: 12),
        _ListingCard(
          title: 'Skilled Tractor Driver',
          owner: 'Available: Rajesh (3.5 km away)',
          price: '₹700 / day',
          imageIcon: Icons.person_rounded,
          tag: 'Available Now',
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final String title;
  final String owner;
  final String price;
  final IconData imageIcon;
  final String tag;
  final bool isRequest;

  const _ListingCard({
    required this.title,
    required this.owner,
    required this.price,
    required this.imageIcon,
    required this.tag,
    this.isRequest = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isRequest ? colors.errorContainer : colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              imageIcon,
              size: 36,
              color: isRequest ? colors.error : colors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(owner, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
