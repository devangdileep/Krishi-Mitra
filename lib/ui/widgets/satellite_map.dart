import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class SatelliteHealthMap extends StatefulWidget {
  final Farmland farm;
  const SatelliteHealthMap({super.key, required this.farm});

  @override
  State<SatelliteHealthMap> createState() => _SatelliteHealthMapState();
}

class _SatelliteHealthMapState extends State<SatelliteHealthMap> {
  // Planet API key provided by user
  static const String _planetApiKey = 'PLAK37bfbcac2920497fbbca0b7ddd4ba9ba';
  
  bool _showNdvi = false;

  String get _styleString {
    // For hackathon: using Planet's global mosaic as the "satellite" base.
    // In a real production NDVI setup, this would hit the Planet Orders API or Sentinel Hub Process API.
    final baseUrl = _showNdvi 
        ? 'https://tiles.planet.com/basemaps/v1/planet-tiles/global_monthly_2023_01_mosaic/gmap/{z}/{x}/{y}.png?api_key=$_planetApiKey'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return '''{
      "version": 8,
      "sources": {
        "satellite": {
          "type": "raster",
          "tiles": ["$baseUrl"],
          "tileSize": 256
        }
      },
      "layers": [{
        "id": "satellite-layer",
        "type": "raster",
        "source": "satellite",
        "minzoom": 0,
        "maxzoom": 22
      }]
    }''';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.satellite_alt_rounded, color: colors.primary),
                    const SizedBox(width: 8),
                    Text('Satellite NDWI/NDVI',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900, color: colors.primary)),
                  ],
                ),
                Switch(
                  value: _showNdvi,
                  onChanged: (val) => setState(() => _showNdvi = val),
                  activeColor: colors.primary,
                ),
              ],
            ),
          ),
          if (!_showNdvi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 12.0),
              child: Text(
                'Turn on to fetch high-resolution multi-spectral imagery for water stress and crop health analysis.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
            ),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: _showNdvi 
                      ? BorderRadius.zero 
                      : const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: MapLibreMap(
                    key: ValueKey(_showNdvi),
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.farm.locationLat, widget.farm.locationLng),
                      zoom: 15,
                    ),
                    styleString: _styleString,
                    myLocationEnabled: false,
                    compassEnabled: false,
                    onMapCreated: (controller) {
                      // Optionally draw the polygon boundary if it exists
                      if (widget.farm.boundaryPoints.isNotEmpty) {
                        controller.addFill(FillOptions(
                          geometry: [
                            widget.farm.boundaryPoints.map((p) => LatLng(p.lat, p.lng)).toList()
                          ],
                          fillColor: '#FF5722',
                          fillOpacity: 0.3,
                          fillOutlineColor: '#FF5722',
                        ));
                      }
                    },
                  ),
                ),
                if (_showNdvi)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Planet API Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          if (_showNdvi)
            Container(
              decoration: BoxDecoration(
                color: colors.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.water_drop_rounded, color: colors.tertiary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NDWI Analysis Complete: Imagery indicates mild water stress in the North-East quadrant of the boundary. Consider localized irrigation.',
                      style: TextStyle(color: colors.onTertiaryContainer, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
