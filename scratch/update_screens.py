import os
import re

file_path = r"e:\Dev\krishi-mitra\make-a-ton\lib\ui\screens.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update imports
content = content.replace(
    "import 'package:flutter_map/flutter_map.dart';\nimport 'package:geolocator/geolocator.dart';\nimport 'package:go_router/go_router.dart';\nimport 'package:intl/intl.dart';\nimport 'package:latlong2/latlong.dart';",
    "import 'package:geolocator/geolocator.dart';\nimport 'package:go_router/go_router.dart';\nimport 'package:intl/intl.dart';\nimport 'package:maplibre_gl/maplibre_gl.dart';"
)

# 2. Extract the state class
class_start = content.find("class _FarmlandEditorScreenState extends State<FarmlandEditorScreen> {")
class_end = content.find("class ReportScreen extends StatefulWidget {")

if class_start != -1 and class_end != -1:
    new_class = """class _FarmlandEditorScreenState extends State<FarmlandEditorScreen> {
  MaplibreMapController? _mapController;
  final _name = TextEditingController();
  final _soil = TextEditingController();
  final _cropName = TextEditingController();
  final _cropCoverage = TextEditingController();
  
  // Advanced fields
  String? _irrigationType;
  String? _waterSource;
  String? _terrainType;
  double? _elevation;
  String? _farmingPractice;
  String? _previousCrop;
  final _soilPH = TextEditingController();
  String? _landOwnership;
  final _nearestMarket = TextEditingController();
  final _farmAge = TextEditingController();
  
  LatLng _center = const LatLng(20.5937, 78.9629);
  List<BoundaryPoint> _boundary = [];
  List<CropItem> _crops = [];
  String _message = 'Use GPS scan or tap map corners to mark the field.';
  double? _accuracy;
  bool _saving = false;
  bool _locating = false;
  bool _isFullscreen = false;
  
  // GPS Stream
  StreamSubscription<Position>? _gpsStream;
  List<Position> _recentPositions = [];
  int _coldStartCount = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    final farm = widget.farmland;
    if (farm != null) {
      _name.text = farm.name;
      _soil.text = farm.soilType ?? '';
      _center = LatLng(farm.locationLat, farm.locationLng);
      _boundary = List.of(farm.boundaryPoints);
      _crops = List.of(farm.crops);
      
      _irrigationType = farm.irrigationType;
      _waterSource = farm.waterSource;
      _terrainType = farm.terrainType;
      _elevation = farm.elevation;
      _farmingPractice = farm.farmingPractice;
      _previousCrop = farm.previousCrop;
      if (farm.soilPH != null) _soilPH.text = farm.soilPH.toString();
      _landOwnership = farm.landOwnership;
      if (farm.nearestMarket != null) _nearestMarket.text = farm.nearestMarket!;
      if (farm.farmAge != null) _farmAge.text = farm.farmAge.toString();
    }
  }

  @override
  void dispose() {
    _gpsStream?.cancel();
    _name.dispose();
    _soil.dispose();
    _cropName.dispose();
    _cropCoverage.dispose();
    _soilPH.dispose();
    _nearestMarket.dispose();
    _farmAge.dispose();
    super.dispose();
  }

  double get _area => estimateAreaHectares(_boundary);
  double get _heat => (_boundary.length * 4 + _crops.length * 2).clamp(18, 100).toDouble();

  Future<void> _startWalkBoundary() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _message = 'Location permission is off.');
      return;
    }
    
    setState(() {
      _isRecording = true;
      _boundary.clear();
      _recentPositions.clear();
      _coldStartCount = 0;
      _isFullscreen = true;
      _message = 'Recording boundary. Start walking...';
    });

    _gpsStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((position) {
      _coldStartCount++;
      if (_coldStartCount <= 3) return; // skip cold start jitter
      
      _recentPositions.add(position);
      if (_recentPositions.length > 5) _recentPositions.removeAt(0);
      
      final avgLat = _recentPositions.map((p) => p.latitude).reduce((a,b) => a+b) / _recentPositions.length;
      final avgLng = _recentPositions.map((p) => p.longitude).reduce((a,b) => a+b) / _recentPositions.length;
      
      if (mounted) {
        setState(() {
          _center = LatLng(avgLat, avgLng);
          _accuracy = position.accuracy;
          _elevation = position.altitude;
          
          if (_isRecording && position.accuracy < 15) {
            _boundary.add(BoundaryPoint(lat: avgLat, lng: avgLng));
            _updateMapPolygon();
            _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
          }
        });
      }
    });
  }

  void _stopWalkBoundary() {
    _gpsStream?.cancel();
    _gpsStream = null;
    setState(() {
      _isRecording = false;
      _message = 'Finished recording. ${_boundary.length} corners added.';
      _isFullscreen = false;
    });
  }

  Future<Position?> _currentPosition() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _message =
            'Location permission is off. You can still tap the map.');
        return null;
      }
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _useLocation() async {
    final position = await _currentPosition();
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _center = point;
      _accuracy = position.accuracy;
      _elevation = position.altitude;
      _message =
          'Centered on your location. Accuracy about ${position.accuracy.toInt()} m.';
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 17.5));
  }

  Future<void> _scanPlot() async {
    final position = await _currentPosition();
    if (position == null) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _center = point;
      _accuracy = position.accuracy;
      _elevation = position.altitude;
      _boundary = _starterBoundary(point, position.accuracy);
      _message = 'Starter geofence scanned. Tap map corners to refine it.';
      _updateMapPolygon();
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 18.0));
  }

  void _onMapClick(Point<double> point, LatLng coordinates) {
    if (_isRecording) return;
    setState(() {
      _boundary = [
        ..._boundary,
        BoundaryPoint(lat: coordinates.latitude, lng: coordinates.longitude)
      ];
      _center = _centroid(_boundary) ?? coordinates;
      _message = _boundary.length < 3
          ? 'Corner ${_boundary.length} saved. Add ${3 - _boundary.length} more.'
          : 'Geofence ready with ${_boundary.length} corners.';
      _updateMapPolygon();
    });
  }

  void _updateMapPolygon() {
    if (_mapController == null) return;
    _mapController!.clearSymbols();
    _mapController!.clearFills();
    _mapController!.clearLines();
    
    if (_boundary.isEmpty) return;
    
    for (var p in _boundary) {
      _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(p.lat, p.lng),
        iconImage: "marker",
        iconSize: 0.5,
      ));
    }
    
    if (_boundary.length >= 3) {
      final points = _boundary.map((e) => LatLng(e.lat, e.lng)).toList();
      _mapController!.addFill(FillOptions(
        geometry: [points],
        fillColor: "#108A62",
        fillOpacity: 0.3,
        fillOutlineColor: "#108A62",
      ));
    }
  }

  Future<void> _save() async {
    if (_boundary.isEmpty && widget.farmland == null) {
      setState(() =>
          _message = 'Set the farm location first using GPS or map taps.');
      return;
    }
    setState(() => _saving = true);
    await widget.repository.save(
      userId: widget.userId,
      id: widget.farmland?.id,
      name: _name.text,
      soilType: _soil.text,
      crops: _crops,
      lat: _center.latitude,
      lng: _center.longitude,
      boundary: _boundary,
      heatIndex: _heat,
      irrigationType: _irrigationType,
      waterSource: _waterSource,
      terrainType: _terrainType,
      elevation: _elevation,
      farmingPractice: _farmingPractice,
      previousCrop: _previousCrop,
      soilPH: double.tryParse(_soilPH.text),
      landOwnership: _landOwnership,
      nearestMarket: _nearestMarket.text.trim().isEmpty ? null : _nearestMarket.text.trim(),
      farmAge: int.tryParse(_farmAge.text),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteFarm() async {
    final farm = widget.farmland;
    if (farm == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete farmland?'),
        content: Text('Delete "${farm.name}" and its saved crop/boundary details?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    await widget.repository.delete(widget.userId, farm.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _buildMap() {
    return MaplibreMap(
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: widget.farmland == null ? 4 : 16,
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
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMapPolygon();
      },
      onMapClick: _onMapClick,
      myLocationEnabled: true,
      myLocationRenderMode: MyLocationRenderMode.NORMAL,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    if (_isFullscreen) {
      return Scaffold(
        body: Stack(
          children: [
            _buildMap(),
            Positioned(
              top: 50, left: 16, right: 16,
              child: GlassCard(
                child: Column(
                  children: [
                    Text('Walking Boundary...', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Corners: ${_boundary.length} | Accuracy: ${_accuracy?.toStringAsFixed(1) ?? "--"}m'),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40, left: 16, right: 16,
              child: FilledButton.icon(
                onPressed: _stopWalkBoundary,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish Walking'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              ),
            ),
          ],
        ),
      );
    }

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.farmland == null ? 'Add Farmland' : 'Edit Farmland'),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            GlassCard(
              child: Column(
                children: [
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Farm name')),
                  const SizedBox(height: 12),
                  TextField(controller: _soil, decoration: const InputDecoration(labelText: 'Soil type')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _boundary.length >= 3 ? 'Plot boundary ready' : 'Plot setup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_rounded),
                        tooltip: 'Fullscreen Map',
                        onPressed: () => setState(() => _isFullscreen = true),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_message, style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      Chip(label: Text('Corners ${_boundary.length}')),
                      Chip(label: Text(_area == 0 ? 'Area scan needed' : 'Area ${_area.toStringAsFixed(2)} ha')),
                      Chip(label: Text(_accuracy == null ? 'GPS manual' : 'GPS ~${_accuracy!.toInt()} m')),
                    ],
                  ),
                  if (_locating) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isRecording ? null : _startWalkBoundary,
                          icon: const Icon(Icons.directions_walk_rounded),
                          label: const Text('Walk Boundary'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _locating ? null : _useLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Use Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildMap(),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _boundary.isEmpty ? null : () {
                          setState(() {
                            _boundary.removeLast();
                            _updateMapPolygon();
                          });
                        },
                        child: const Text('Undo point'),
                      ),
                      TextButton(
                        onPressed: _boundary.isEmpty ? null : () {
                          setState(() {
                            _boundary.clear();
                            _updateMapPolygon();
                          });
                        },
                        child: const Text('Clear boundary'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('▶ Advanced farm details (optional)'),
                  subtitle: const Text('Improves AI agronomy insights'),
                  children: [
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _irrigationType,
                      decoration: const InputDecoration(labelText: 'Irrigation Type'),
                      items: irrigationTypes.map((e) => DropdownMenuItem(value: e, child: Text(enumLabel(e)))).toList(),
                      onChanged: (v) => setState(() => _irrigationType = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _waterSource,
                      decoration: const InputDecoration(labelText: 'Water Source'),
                      items: waterSources.map((e) => DropdownMenuItem(value: e, child: Text(enumLabel(e)))).toList(),
                      onChanged: (v) => setState(() => _waterSource = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _terrainType,
                      decoration: const InputDecoration(labelText: 'Terrain Type'),
                      items: terrainTypes.map((e) => DropdownMenuItem(value: e, child: Text(enumLabel(e)))).toList(),
                      onChanged: (v) => setState(() => _terrainType = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _farmingPractice,
                      decoration: const InputDecoration(labelText: 'Farming Practice'),
                      items: farmingPractices.map((e) => DropdownMenuItem(value: e, child: Text(enumLabel(e)))).toList(),
                      onChanged: (v) => setState(() => _farmingPractice = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _landOwnership,
                      decoration: const InputDecoration(labelText: 'Land Ownership'),
                      items: landOwnershipTypes.map((e) => DropdownMenuItem(value: e, child: Text(enumLabel(e)))).toList(),
                      onChanged: (v) => setState(() => _landOwnership = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: _soilPH, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Soil pH (1.0 - 14.0)')),
                    const SizedBox(height: 8),
                    TextField(controller: _farmAge, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Years Farmed')),
                    const SizedBox(height: 8),
                    TextField(controller: _nearestMarket, decoration: const InputDecoration(labelText: 'Nearest Market/Town')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crops on this land', style: Theme.of(context).textTheme.titleMedium),
                  if (_crops.isNotEmpty) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildDonutChart(colors),
                  ),
                  ..._crops.map(
                    (crop) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(crop.name),
                      subtitle: Text(crop.coverageSummary(_area)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => setState(() => _crops.remove(crop)),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _cropName, decoration: const InputDecoration(labelText: 'Crop'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _cropCoverage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Coverage %'))),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        if (_cropName.text.trim().isEmpty) return;
                        final percent = double.tryParse(_cropCoverage.text) ?? 0;
                        setState(() {
                          _crops.add(CropItem(name: _cropName.text.trim(), coveragePercent: percent));
                          _cropName.clear();
                          _cropCoverage.clear();
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add crop'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.farmland == null ? 'Save Farmland' : 'Update Farmland'),
            ),
            if (widget.farmland != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : _deleteFarm,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete farmland'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(ColorScheme colors) {
    if (_crops.isEmpty) return const SizedBox();
    final remaining = 100.0 - _crops.fold<double>(0, (sum, c) => sum + c.coveragePercent);
    return Row(
      children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                color: colors.surfaceContainerHighest,
                strokeWidth: 12,
              ),
              ..._crops.asMap().entries.map((entry) {
                final idx = entry.key;
                final crop = entry.value;
                final previous = _crops.take(idx).fold<double>(0, (sum, c) => sum + c.coveragePercent);
                return Transform.rotate(
                  angle: previous / 100 * 2 * pi,
                  child: CircularProgressIndicator(
                    value: crop.coveragePercent / 100,
                    color: Colors.primaries[idx % Colors.primaries.length],
                    strokeWidth: 12,
                  ),
                );
              }),
              const Text('🍩', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._crops.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.primaries[entry.key % Colors.primaries.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${entry.value.coveragePercent.toStringAsFixed(0)}% ${entry.value.name}')),
                  ],
                ),
              )),
              if (remaining > 0)
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors.surfaceContainerHighest, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${remaining.toStringAsFixed(0)}% Remaining')),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
"""
    content = content[:class_start] + new_class + content[class_end:]

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Updated successfully")
else:
    print("Could not find class boundaries")
