---
name: image-performance
description: Use for lists, grids, and anything rendering photos.
---
- Lazy builders only (`GridView.builder`); `const` constructors; stable keys.
- Decode at display size (`cacheWidth` / `cacheHeight`); use a cached image layer.
- Add `RepaintBoundary` only where DevTools shows a need.
- Record before/after measurements in the slice's ADR in `docs/adr/`.
