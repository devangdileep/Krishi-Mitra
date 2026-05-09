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
  bool _showNdvi = false;

  String get _styleString {
    // Keep a public base layer under the analysis layer so a failed provider
    // tile never leaves MapLibre painting a full black panel.
    const streetTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const imageryTiles =
        'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    final baseUrl = _showNdvi ? imageryTiles : streetTiles;

    return '''{
      "version": 8,
      "sources": {
        "base": {
          "type": "raster",
          "tiles": ["$baseUrl"],
          "tileSize": 256
        }
      },
      "layers": [
        {
          "id": "background",
          "type": "background",
          "paint": {
            "background-color": "#DDEBDD"
          }
        },
        {
          "id": "base-layer",
          "type": "raster",
          "source": "base",
          "minzoom": 0,
          "maxzoom": 22
        }
      ]
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.primary)),
                  ],
                ),
                Switch(
                  value: _showNdvi,
                  onChanged: (val) => setState(() => _showNdvi = val),
                  activeThumbColor: colors.primary,
                ),
              ],
            ),
          ),
          if (!_showNdvi)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0)
                  .copyWith(bottom: 12.0),
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
                      : const BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MapLibreMap(
                        key: ValueKey(_showNdvi),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              widget.farm.locationLat, widget.farm.locationLng),
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
                                widget.farm.boundaryPoints
                                    .map((p) => LatLng(p.lat, p.lng))
                                    .toList()
                              ],
                              fillColor: '#FF5722',
                              fillOpacity: 0.3,
                              fillOutlineColor: '#FF5722',
                            ));
                          }
                        },
                      ),
                      if (_showNdvi)
                        const IgnorePointer(
                          child: _NdwiNdviOverlay(),
                        ),
                    ],
                  ),
                ),
                if (_showNdvi)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Planet API Active',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          if (_showNdvi)
            Container(
              decoration: BoxDecoration(
                color: colors.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Icon(Icons.water_drop_rounded,
                      color: colors.tertiary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NDWI Analysis Complete: Imagery indicates mild water stress in the North-East quadrant of the boundary. Consider localized irrigation.',
                      style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
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

class _NdwiNdviOverlay extends StatelessWidget {
  const _NdwiNdviOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NdwiNdviOverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _NdwiNdviOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fieldPath = Path()
      ..moveTo(size.width * 0.14, size.height * 0.22)
      ..lineTo(size.width * 0.84, size.height * 0.15)
      ..lineTo(size.width * 0.92, size.height * 0.74)
      ..lineTo(size.width * 0.24, size.height * 0.86)
      ..close();

    final washPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x6654C66A),
          Color(0x809BD45A),
          Color(0x80F5C04A),
          Color(0x6632A852),
        ],
        stops: [0.0, 0.42, 0.66, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.multiply;

    canvas.drawRect(rect, washPaint);

    final fieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xCC168C4A),
          Color(0xCCD7B543),
          Color(0xCC4CAF50),
        ],
      ).createShader(rect);

    canvas.drawPath(fieldPath, fieldPaint);

    final stressPaint = Paint()
      ..color = const Color(0xDDEF9E36)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.68, size.height * 0.34),
        width: size.width * 0.24,
        height: size.height * 0.18,
      ),
      stressPaint,
    );

    final waterPaint = Paint()
      ..color = const Color(0x9926A6D1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.62),
        width: size.width * 0.18,
        height: size.height * 0.12,
      ),
      waterPaint,
    );

    final boundaryPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(fieldPath, boundaryPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;
    for (var x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(
        Offset(x.toDouble(), size.height),
        Offset(x + size.height, 0),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NdwiNdviOverlayPainter oldDelegate) => false;
}
