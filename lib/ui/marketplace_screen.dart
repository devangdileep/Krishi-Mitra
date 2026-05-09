import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_clients.dart';
import '../theme/app_theme.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({
    super.key,
    required this.api,
    required this.repository,
    required this.userId,
  });

  final SupabaseRestClient api;
  final FarmlandRepository repository;
  final int userId;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late Future<_MarketplaceData> _dataFuture;
  List<Farmland> _cachedFarms = const [];

  @override
  void initState() {
    super.initState();
    _cachedFarms = widget.repository.cached(widget.userId);
    _dataFuture = _loadData();
  }

  Future<_MarketplaceData> _loadData() async {
    var farms = _cachedFarms;
    try {
      final fresh = await widget.repository.refresh(widget.userId);
      if (fresh.isNotEmpty) farms = fresh;
    } catch (_) {
      // Local farm context is enough for the marketplace shell.
    }

    try {
      final listings = await widget.api.getMarketplaceListings(limit: 100);
      return _MarketplaceData(farms: farms, listings: listings);
    } catch (error) {
      return _MarketplaceData(
        farms: farms,
        listings: const [],
        loadError: error.toString(),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  Future<void> _openPostListingSheet() async {
    final data = await _dataFuture;
    if (!mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostListingSheet(
        api: widget.api,
        userId: widget.userId,
        farms: data.farms,
      ),
    );
    if (created == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Peer-to-Peer Market',
            style:
                TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<_MarketplaceData>(
          future: _dataFuture,
          initialData:
              _MarketplaceData(farms: _cachedFarms, listings: const []),
          builder: (context, snapshot) {
            final data = snapshot.data ??
                _MarketplaceData(farms: _cachedFarms, listings: const []);
            final machinery = data.listings
                .where((listing) => !listing.isLabor)
                .toList(growable: false);
            final labor = data.listings
                .where((listing) => listing.isLabor)
                .toList(growable: false);

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _MarketplaceContextCard(data: data),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelColor: colors.primary,
                        unselectedLabelColor: colors.onSurfaceVariant,
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w900),
                        tabs: const [
                          Tab(text: 'Machinery'),
                          Tab(text: 'Labor'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ListingsTab(
                          typeLabel: 'machinery',
                          listings: machinery,
                          loadError: data.loadError,
                          onRefresh: _refresh,
                        ),
                        _ListingsTab(
                          typeLabel: 'labor',
                          listings: labor,
                          loadError: data.loadError,
                          onRefresh: _refresh,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openPostListingSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Post Listing'),
        ),
      ),
    );
  }
}

class _MarketplaceData {
  const _MarketplaceData({
    required this.farms,
    required this.listings,
    this.loadError,
  });

  final List<Farmland> farms;
  final List<MarketplaceListing> listings;
  final String? loadError;

  String get contextLabel {
    final markets = farms
        .map((farm) => farm.nearestMarket?.trim())
        .whereType<String>()
        .where((market) => market.isNotEmpty)
        .toSet();
    if (markets.isNotEmpty) return 'Near ${markets.first}';
    if (farms.isNotEmpty) return 'Near ${farms.first.name}';
    return 'Set up a farm to personalize nearby listings';
  }
}

class _MarketplaceContextCard extends StatelessWidget {
  const _MarketplaceContextCard({required this.data});

  final _MarketplaceData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.contextLabel,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${data.listings.length} active',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsTab extends StatelessWidget {
  const _ListingsTab({
    required this.typeLabel,
    required this.listings,
    required this.onRefresh,
    this.loadError,
  });

  final String typeLabel;
  final List<MarketplaceListing> listings;
  final String? loadError;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          if (listings.isEmpty) {
            return _EmptyListingsCard(
              typeLabel: typeLabel,
              loadError: loadError,
            );
          }
          return _ListingCard(listing: listings[index]);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: listings.isEmpty ? 1 : listings.length,
      ),
    );
  }
}

class _EmptyListingsCard extends StatelessWidget {
  const _EmptyListingsCard({required this.typeLabel, this.loadError});

  final String typeLabel;
  final String? loadError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasConnectionIssue = loadError != null && loadError!.isNotEmpty;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasConnectionIssue
                ? Icons.cloud_off_rounded
                : Icons.inventory_2_outlined,
            color: colors.primary,
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            hasConnectionIssue
                ? 'Marketplace could not refresh'
                : 'No active $typeLabel listings yet',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            hasConnectionIssue
                ? 'Pull to refresh after checking your network connection.'
                : 'Post the first listing from your farm network.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon =
        listing.isLabor ? Icons.groups_rounded : Icons.handyman_rounded;
    final owner = listing.ownerName?.trim().isNotEmpty == true
        ? listing.ownerName!.trim()
        : 'Farmer #${listing.userId}';
    final meta = [
      if ((listing.cropType ?? '').trim().isNotEmpty) listing.cropType!.trim(),
      if ((listing.quantity ?? '').trim().isNotEmpty) listing.quantity!.trim(),
    ].join(' - ');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 32, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Listed by $owner',
                  style:
                      TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _priceLabel(listing.price),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _StatusPill(status: listing.status),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PostListingSheet extends StatefulWidget {
  const _PostListingSheet({
    required this.api,
    required this.userId,
    required this.farms,
  });

  final SupabaseRestClient api;
  final int userId;
  final List<Farmland> farms;

  @override
  State<_PostListingSheet> createState() => _PostListingSheetState();
}

class _PostListingSheetState extends State<_PostListingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String _listingType = 'machinery';
  String? _cropType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final crops = _availableCrops;
    if (crops.isNotEmpty) _cropType = crops.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  List<String> get _availableCrops {
    return widget.farms
        .expand((farm) => farm.crops)
        .map((crop) => crop.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.createMarketplaceListing(
        userId: widget.userId,
        listingType: _listingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text,
        cropType: _cropType,
        quantity: _quantityController.text,
        price: double.tryParse(_priceController.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not post listing: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final crops = _availableCrops;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Listing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'machinery',
                      icon: Icon(Icons.handyman_rounded),
                      label: Text('Machinery'),
                    ),
                    ButtonSegment(
                      value: 'labor',
                      icon: Icon(Icons.groups_rounded),
                      label: Text('Labor'),
                    ),
                  ],
                  selected: {_listingType},
                  onSelectionChanged: (value) {
                    setState(() => _listingType = value.first);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a listing title'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                if (crops.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _cropType,
                    decoration:
                        const InputDecoration(labelText: 'Related crop'),
                    items: crops
                        .map(
                          (crop) => DropdownMenuItem(
                            value: crop,
                            child: Text(crop),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _cropType = value),
                  ),
                if (crops.isNotEmpty) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration:
                            const InputDecoration(labelText: 'Qty / duration'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_saving ? 'Posting...' : 'Post to Supabase'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _priceLabel(double? price) {
  if (price == null || price <= 0) return 'Price on request';
  final whole = price % 1 == 0 ? price.toStringAsFixed(0) : price.toString();
  return '\u20B9$whole';
}
