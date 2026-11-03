import 'package:flutter/material.dart';

import '../../features/wardrobe/domain/wardrobe_item.dart';

/// Display strings and swatches live in presentation so the domain stays
/// free of UI and copy concerns.
String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

extension SeasonLabel on Season {
  String get label => _capitalize(name);
}

extension ResidenceLabel on Residence {
  String get label => switch (this) {
    Residence.city => 'City flat',
    Residence.country => 'Country house',
    Residence.coast => 'Coast villa',
  };
}

extension CategoryLabel on ItemCategory {
  String get label => _capitalize(name);
}

extension FormalityLabel on Formality {
  String get label => _capitalize(name);
}

extension ColorFamilyStyle on ColorFamily {
  String get label => _capitalize(name);

  Color get swatch => switch (this) {
    ColorFamily.black => const Color(0xFF2B2B2B),
    ColorFamily.white => const Color(0xFFF4F1EA),
    ColorFamily.beige => const Color(0xFFD8C3A5),
    ColorFamily.grey => const Color(0xFF9A9A9A),
    ColorFamily.navy => const Color(0xFF2E3A59),
    ColorFamily.brown => const Color(0xFF8B5E3C),
    ColorFamily.red => const Color(0xFFB23A3A),
    ColorFamily.green => const Color(0xFF4F6B4A),
    ColorFamily.blue => const Color(0xFF6C93C4),
    ColorFamily.pink => const Color(0xFFE3A9B8),
  };
}
