import os
import re

file_path = r"e:\Dev\krishi-mitra\make-a-ton\lib\ui\screens.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update CropsScreen to accept intelligence
content = content.replace(
    "class CropsScreen extends StatefulWidget {\n  const CropsScreen(\n      {super.key, required this.repository, required this.userId});\n\n  final FarmlandRepository repository;\n  final int userId;",
    "class CropsScreen extends StatefulWidget {\n  const CropsScreen(\n      {super.key, required this.repository, required this.intelligence, required this.userId});\n\n  final FarmlandRepository repository;\n  final FarmlandIntelligence intelligence;\n  final int userId;"
)

# 2. Update HomeShell to pass intelligence
content = content.replace(
    "CropsScreen(repository: widget.repository, userId: user.id),",
    "CropsScreen(repository: widget.repository, intelligence: widget.intelligence, userId: user.id),"
)

# 3. Replace _BrandHeader subtitle in CropsScreen
content = content.replace(
    "const _BrandHeader(\n                title: 'My Farms', subtitle: 'Offline-first farm workspace'),",
    "_BrandHeader(\n                title: 'My Farms', subtitle: AppStateScope.of(context).userLocationName != null ? 'Farms near ${AppStateScope.of(context).userLocationName}' : 'Offline-first farm workspace'),"
)
content = content.replace(
    "const _BrandHeader(title: 'My Farms', subtitle: 'Offline-first farm workspace'),",
    "_BrandHeader(title: 'My Farms', subtitle: AppStateScope.of(context).userLocationName != null ? 'Farms near ${AppStateScope.of(context).userLocationName}' : 'Offline-first farm workspace'),"
)

# 4. Change search hint and onTap
content = content.replace(
    "hint: 'Search crops, farms, soil, alerts',",
    "hint: 'Search crops & get AI insights',",
)

content = content.replace(
    "onTap: _showSearchSheet,",
    "onTap: _showCropIntelligenceSheet,"
)

# 5. Add _showCropIntelligenceSheet and replace _showSearchSheet
crop_intelligence_sheet_method = """
  Future<void> _showCropIntelligenceSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => _CropIntelligenceSheet(
          farms: _farms,
          intelligence: widget.intelligence,
          scrollController: controller,
        ),
      ),
    );
  }
"""
content = re.sub(
    r"Future<void> _showSearchSheet\(\) async \{.*?\n  \}",
    crop_intelligence_sheet_method.strip(),
    content,
    flags=re.DOTALL
)

# 6. Add _CropIntelligenceSheet class (replacing _FarmSearchSheet)
crop_intelligence_sheet_class = """
class _CropIntelligenceSheet extends StatefulWidget {
  const _CropIntelligenceSheet({
    required this.farms,
    required this.intelligence,
    required this.scrollController,
  });

  final List<Farmland> farms;
  final FarmlandIntelligence intelligence;
  final ScrollController scrollController;

  @override
  State<_CropIntelligenceSheet> createState() => _CropIntelligenceSheetState();
}

class _CropIntelligenceSheetState extends State<_CropIntelligenceSheet> {
  final _query = TextEditingController();
  CropIntelligenceReport? _report;
  bool _loading = false;
  Farmland? _selectedFarm;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _searchCrop() async {
    final cropName = _query.text.trim();
    if (cropName.isEmpty) return;
    setState(() {
      _loading = true;
      _report = null;
      _selectedFarm = null;
    });

    final location = AppStateScope.of(context).userLocationName;
    final report = await widget.intelligence.analyzeCrop(cropName, widget.farms, location);

    if (mounted) {
      setState(() {
        _loading = false;
        _report = report;
        if (widget.farms.isNotEmpty) {
          _selectedFarm = widget.farms.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return GlassCard(
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchCrop(),
                  decoration: InputDecoration(
                    hintText: 'Enter a crop name (e.g., Wheat, Tomato)',
                    prefixIcon: const Icon(Icons.psychology_rounded),
                    suffixIcon: _query.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _query.clear();
                              _report = null;
                            }),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _searchCrop,
                child: const Text('Ask AI'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_report != null) ...[
            Text('AI Crop Intelligence', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildReportSection(colors, Icons.landscape_rounded, 'Suitable Area', _report!.suitableArea),
            const SizedBox(height: 12),
            _buildReportSection(colors, Icons.agriculture_rounded, 'Harvesting Info', _report!.harvestingInfo),
            const SizedBox(height: 12),
            _buildReportSection(colors, Icons.storefront_rounded, 'Local Market Price', _report!.marketPriceEstimate),
            const SizedBox(height: 12),
            _buildReportSection(colors, Icons.trending_up_rounded, 'ROI Estimate', _report!.roiEstimate),
            
            if (widget.farms.isNotEmpty) ...[
              const Divider(height: 32),
              Text('Farmland Suitability', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              DropdownButtonFormField<Farmland>(
                value: _selectedFarm,
                decoration: const InputDecoration(labelText: 'Select your farmland'),
                items: widget.farms.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                onChanged: (f) => setState(() => _selectedFarm = f),
              ),
              if (_selectedFarm != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.analytics_rounded, color: colors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _report!.farmlandEvaluations[_selectedFarm!.id] ?? 'No evaluation available for this farm.',
                          style: TextStyle(color: colors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const Divider(height: 32),
              const Text('Add farmlands to get personalized suitability analysis.'),
            ],
          ] else if (_query.text.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Search for a crop to get AI-powered insights, pricing, and suitability evaluation for your mapped farmlands.'),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReportSection(ColorScheme colors, IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(content, style: TextStyle(color: colors.onSurfaceVariant, height: 1.4)),
      ],
    );
  }
}
"""

content = re.sub(
    r"class _FarmSearchSheet extends StatefulWidget \{.*?\n\s*\n\s*\n.*?(?=class _ProfileInfoRow|\nclass _BrandHeader)",
    crop_intelligence_sheet_class.strip() + "\n\n",
    content,
    flags=re.DOTALL
)

# 7. Add Profile Map Selector to ProfileScreen
# First, add the location map variables to _ProfileScreenState
profile_vars = """
  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  
  bool _selectingLocation = false;
  MapLibreMapController? _profileMapController;
  LatLng? _profileLocation;
  String _profileLocationName = '';
  double? _profileAccuracy;
"""
content = content.replace(
    "  bool _editing = false;\n  bool _saving = false;\n  bool _deleting = false;\n  String? _error;",
    profile_vars
)

# Add method to get current location in profile
profile_location_methods = """
  Future<void> _getCurrentLocationForProfile() async {
    setState(() => _saving = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission is off.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      setState(() {
        _profileLocation = LatLng(position.latitude, position.longitude);
        _profileAccuracy = position.accuracy;
        _profileLocationName = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      });
      _profileMapController?.animateCamera(CameraUpdate.newLatLngZoom(_profileLocation!, 15.0));
    } catch (e) {
      setState(() => _error = 'Could not get location: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onProfileMapClick(math.Point<double> point, LatLng coordinates) {
    setState(() {
      _profileLocation = coordinates;
      _profileLocationName = 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, Lng: ${coordinates.longitude.toStringAsFixed(4)}';
    });
  }

  Future<void> _saveProfileLocation(AppState state) async {
    if (_profileLocation == null) return;
    await state.setUserLocation(
      _profileLocationName,
      _profileLocation!.latitude,
      _profileLocation!.longitude,
    );
    setState(() => _selectingLocation = false);
  }
"""
content = content.replace("  void _startEdit(UserProfile user) {", profile_location_methods + "\n  void _startEdit(UserProfile user) {")

# Add the UI for profile location
profile_location_ui = """
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(
                            icon: Icons.location_on_rounded,
                            title: 'My Region / Location',
                          ),
                        ),
                        if (!_selectingLocation)
                          TextButton.icon(
                            onPressed: () => setState(() => _selectingLocation = true),
                            icon: const Icon(Icons.edit_location_alt_rounded),
                            label: const Text('Set'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_selectingLocation) ...[
                      Text('Tap on the map or use GPS to set your default farm location.', style: TextStyle(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MapLibreMap(
                            initialCameraPosition: CameraPosition(
                              target: _profileLocation ?? (state.userLat != null ? LatLng(state.userLat!, state.userLng!) : const LatLng(20.5937, 78.9629)),
                              zoom: state.userLat != null ? 12 : 4,
                            ),
                            styleString: '''{
                              "version": 8,
                              "sources": {
                                "osm": {
                                  "type": "raster",
                                  "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
                                  "tileSize": 256
                                }
                              },
                              "layers": [{
                                "id": "osm",
                                "type": "raster",
                                "source": "osm",
                                "minzoom": 0,
                                "maxzoom": 19
                              }]
                            }''',
                            onMapCreated: (controller) => _profileMapController = controller,
                            onMapClick: _onProfileMapClick,
                            myLocationEnabled: true,
                            myLocationRenderMode: MyLocationRenderMode.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_profileLocation != null)
                        Text('Selected: $_profileLocationName', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _getCurrentLocationForProfile,
                              icon: const Icon(Icons.my_location_rounded),
                              label: const Text('My GPS'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _profileLocation == null ? null : () => _saveProfileLocation(state),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Save Location'),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectingLocation = false),
                        child: const Text('Cancel'),
                      ),
                    ] else ...[
                      _ProfileInfoRow(
                        icon: Icons.map_rounded,
                        label: 'Location',
                        value: state.userLocationName ?? 'Not set',
                      ),
                    ],
                  ],
                ),
              ),
"""

# Insert profile_location_ui right after the first GlassCard in ProfileScreen (the one with the avatar and name)
avatar_card_end = "                    Chip(\n                      avatar: const Icon(Icons.verified_rounded, size: 16),\n                      label: const Text('OTP'),\n                      backgroundColor: colors.primaryContainer,\n                    ),\n                  ],\n                ),\n              ),"
content = content.replace(avatar_card_end, avatar_card_end + "\n" + profile_location_ui)


with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated screens.dart successfully")
