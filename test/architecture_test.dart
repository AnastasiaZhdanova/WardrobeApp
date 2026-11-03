import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layering in docs/adr/0002-feature-first-layering.md by
/// reading the import directives of every hand-written file under lib/.
void main() {
  final files = _sources();

  test('lib/ has sources to check', () {
    expect(files, isNotEmpty);
  });

  test(
    'domain is pure Dart: no Flutter, IO packages, data or presentation',
    () {
      final violations = [
        for (final file in files.where((f) => f.layer == 'domain'))
          for (final import in file.imports)
            if (_isFlutter(import.uri) ||
                _ioPackages.any(import.uri.startsWith) ||
                import.layer == 'data' ||
                import.layer == 'presentation' ||
                import.isShared)
              '${file.path} -> ${import.uri}',
      ];
      expect(violations, isEmpty);
    },
  );

  test('presentation never imports data', () {
    final violations = [
      for (final file in files.where((f) => f.layer == 'presentation'))
        for (final import in file.imports)
          if (import.layer == 'data') '${file.path} -> ${import.uri}',
    ];
    expect(violations, isEmpty);
  });

  test("a feature never imports another feature's presentation or data", () {
    final violations = [
      for (final file in files.where((f) => f.feature != null))
        for (final import in file.imports)
          if (import.feature != null &&
              import.feature != file.feature &&
              (import.layer == 'presentation' || import.layer == 'data'))
            '${file.path} -> ${import.uri}',
    ];
    expect(violations, isEmpty);
  });

  test('core imports no feature or shared code', () {
    final violations = [
      for (final file in files.where((f) => f.path.startsWith('lib/core/')))
        for (final import in file.imports)
          if (import.feature != null || import.isShared)
            '${file.path} -> ${import.uri}',
    ];
    expect(violations, isEmpty);
  });

  test("shared code imports only features' domain", () {
    final violations = [
      for (final file in files.where((f) => f.path.startsWith('lib/shared/')))
        for (final import in file.imports)
          if (import.layer == 'data' || import.layer == 'presentation')
            '${file.path} -> ${import.uri}',
    ];
    expect(violations, isEmpty);
  });
}

const _ioPackages = ['package:drift', 'package:http', 'package:path_provider'];

bool _isFlutter(String uri) =>
    uri.startsWith('package:flutter/') ||
    uri.startsWith('package:flutter_riverpod/') ||
    uri == 'dart:ui';

final _directive = RegExp(
  r'''^(?:import|export)\s+'([^']+)'.*;''',
  multiLine: true,
);

List<_Source> _sources() => [
  for (final entity in Directory('lib').listSync(recursive: true))
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('.g.dart') &&
        !entity.path.endsWith('.freezed.dart'))
      _Source(entity),
];

/// A location under lib/, e.g. `lib/features/review/domain/x.dart` has
/// feature `review` and layer `domain`.
class _Location {
  _Location(this.path) {
    final parts = path.split('/');
    if (parts.length > 3 && parts[0] == 'lib' && parts[1] == 'features') {
      feature = parts[2];
      layer = parts[3];
    }
  }

  final String path;
  String? feature;
  String? layer;

  bool get isShared => path.startsWith('lib/shared/');
}

class _Source extends _Location {
  _Source(File file) : super(_normalize(file.path)) {
    imports = [
      for (final match in _directive.allMatches(file.readAsStringSync()))
        _Import(match.group(1)!, from: path),
    ];
  }

  late final List<_Import> imports;
}

class _Import extends _Location {
  _Import(this.uri, {required String from}) : super(_resolve(uri, from));

  final String uri;

  static String _resolve(String uri, String from) {
    const self = 'package:wardrobe_app/';
    if (uri.startsWith(self)) return 'lib/${uri.substring(self.length)}';
    if (uri.startsWith('package:') || uri.startsWith('dart:')) return uri;
    final dir = from.substring(0, from.lastIndexOf('/'));
    return _normalize('$dir/$uri');
  }
}

/// Collapses `.` and `..` segments and uses `/` on every platform.
String _normalize(String path) {
  final out = <String>[];
  for (final part in path.replaceAll(r'\', '/').split('/')) {
    if (part == '..') {
      out.removeLast();
    } else if (part != '.' && part.isNotEmpty) {
      out.add(part);
    }
  }
  return out.join('/');
}
