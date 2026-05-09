import os

file_path = r"e:\Dev\krishi-mitra\make-a-ton\lib\ui\screens.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("MaplibreMapController", "MapLibreMapController")
content = content.replace("MaplibreMap(", "MapLibreMap(")
content = content.replace("MyLocationRenderMode.NORMAL", "MyLocationRenderMode.normal")
content = content.replace("void _onMapClick(Point<double> point", "void _onMapClick(math.Point<double> point")

if "import 'dart:math' as math;" not in content:
    content = content.replace("import 'dart:math';", "import 'dart:math' hide Point;\nimport 'dart:math' as math;")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Fixes applied successfully")
