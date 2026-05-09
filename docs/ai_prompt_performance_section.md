# AI Prompt Performance Section

Add this section to future AI generation prompts for Krishi Mitra.

---

# Performance and Low-End Device Optimization

The UI must look premium while remaining extremely optimized for low-end Android devices.

Target:

- Stable 60 FPS minimum on low-end phones
- 90 to 120 FPS on flagship devices
- Fast cold startup
- Low memory usage
- Minimal battery drain
- Smooth scrolling everywhere

The app must feel:

- Instant
- Lightweight
- Native
- Fluid even on cheap devices

---

# Flutter Performance Requirements

Optimize the UI rendering aggressively.

Use:

- const widgets everywhere possible
- RepaintBoundary strategically
- Lazy loading lists
- ListView.builder
- Efficient widget trees
- Minimal rebuilds
- ValueNotifier or Riverpod optimized state management
- Cached network images
- Lightweight animations
- GPU-friendly effects

Avoid:

- Heavy nested widgets
- Excessive opacity layers
- Massive blur radius
- Expensive rebuilds
- Unoptimized shaders
- Overdraw
- Large shadow spreads
- Unnecessary animations

---

# Glassmorphism Optimization

Glass UI must be optimized carefully.

Rules:

- Use blur only where necessary
- Keep blur radius low and efficient
- Avoid full-screen backdrop blur
- Use fake glass effects where possible
- Reuse glass components
- Use static gradients instead of dynamic heavy shaders
- Reduce transparency stacking
- Limit layered shadows

For low-end devices:

- Automatically reduce blur intensity
- Disable expensive particle effects
- Reduce animation complexity
- Use adaptive graphics quality

Create:

- Performance-aware UI system
- Adaptive animation scaling
- Dynamic graphics quality manager

---

# Animation Optimization

Animations must feel flagship-quality without frame drops.

Use:

- Hardware accelerated animations
- Transform animations instead of layout rebuilds
- AnimatedScale
- AnimatedOpacity
- TweenAnimationBuilder
- Implicit animations
- Rive optimized assets

Avoid:

- Continuous heavy animations
- CPU-intensive painters
- Frequent setState rebuilds
- Janky physics simulations

Animation timing:

- Fast and responsive
- 120Hz feeling
- No lag
- No frame skipping

---

# Low-End Device Strategy

The app should automatically detect weaker devices and:

- Lower blur strength
- Reduce particle count
- Simplify shadows
- Disable unnecessary animations
- Use lightweight assets
- Reduce map rendering complexity

Maintain:

- Same premium look
- Same usability
- Same smoothness

Even on:

- 3GB RAM phones
- Budget MediaTek devices
- Older Snapdragon devices

---

# Map Performance

Map screen must remain smooth while drawing polygons.

Optimize:

- Polygon rendering
- Marker rendering
- Tile caching
- Gesture handling
- GPS updates

Avoid:

- Rebuilding entire map
- Heavy overlays
- Unoptimized redraws

Use:

- Efficient polygon painters
- Tile caching
- Smart redraw logic

---

# Startup Performance

Requirements:

- Fast splash transition
- Minimal startup jank
- Lazy initialize services
- Defer non-critical API calls
- Cache theme and settings locally
- Offline-first loading

Target:

- Instant perceived startup
- Smooth first render

---

# Image and Asset Optimization

Use:

- SVG icons where possible
- Compressed assets
- Cached images
- Lazy image loading
- Optimized Lottie files

Avoid:

- Large PNGs
- Uncompressed assets
- Heavy GIFs

---

# Memory Optimization

The app must:

- Avoid memory leaks
- Dispose controllers properly
- Avoid retaining heavy widgets
- Use lightweight state management
- Optimize map memory usage

Target:

- Stable long sessions
- No overheating
- Low RAM usage

---

# Final Performance Goal

The app should:

- Feel like a native Apple app
- Stay ultra smooth
- Never feel heavy
- Maintain premium visuals
- Work beautifully on low-end Android phones

Even with:

- Glassmorphism
- Maps
- AI UI
- Voice assistant
- Weather animations
- Dark mode
- Offline syncing

The UI must achieve:

- Industry-standard optimization
- Production-grade rendering
- Smooth scrolling
- Zero noticeable lag
- High refresh-rate fluidity
- Excellent battery efficiency
