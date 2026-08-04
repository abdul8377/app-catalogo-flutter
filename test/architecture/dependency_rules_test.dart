import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late List<_Dependency> dependencies;

  setUpAll(() {
    dependencies = _scanDependencies(Directory.current);
  });

  test('domain no depende de data, presentation, Flutter ni sqflite', () {
    final violations = dependencies.where((dependency) {
      if (!_isInside(dependency.source, 'domain')) return false;

      final target = dependency.target;
      final importsForbiddenLocalLayer =
          target != null &&
          (_isInside(target, 'data') || _isInside(target, 'presentation'));
      final packageName = _packageName(dependency.uri);
      final importsFlutter =
          dependency.uri == 'dart:ui' ||
          packageName == 'flutter' ||
          packageName.startsWith('flutter_');
      final importsSqflite =
          packageName == 'sqflite' || packageName.startsWith('sqflite_');

      return importsForbiddenLocalLayer || importsFlutter || importsSqflite;
    }).toList();

    expect(violations, isEmpty, reason: _report(violations));
  });

  test('data no depende de presentation', () {
    final violations = dependencies
        .where(
          (dependency) =>
              _isInside(dependency.source, 'data') &&
              dependency.target != null &&
              _isInside(dependency.target!, 'presentation'),
        )
        .toList();

    expect(violations, isEmpty, reason: _report(violations));
  });

  test('core no depende de features', () {
    final violations = dependencies
        .where(
          (dependency) =>
              dependency.source.startsWith('lib/core/') &&
              dependency.target?.startsWith('lib/features/') == true,
        )
        .toList();

    expect(violations, isEmpty, reason: _report(violations));
  });

  test('features no dependen de app', () {
    final violations = dependencies
        .where(
          (dependency) =>
              dependency.source.startsWith('lib/features/') &&
              dependency.target?.startsWith('lib/app/') == true,
        )
        .toList();

    expect(violations, isEmpty, reason: _report(violations));
  });

  test('BLoC, eventos y estados no dependen de elementos visuales', () {
    final visualDirectory = RegExp(
      r'/presentation/(?:pages|widgets|dialogs|sections|views)/',
    );
    final violations = dependencies
        .where(
          (dependency) =>
              _isBlocContract(dependency.source) &&
              dependency.target != null &&
              visualDirectory.hasMatch(dependency.target!),
        )
        .toList();

    expect(violations, isEmpty, reason: _report(violations));
  });

  test('pages no dependen directamente de datasources', () {
    final violations = dependencies
        .where(
          (dependency) =>
              dependency.source.contains('/presentation/pages/') &&
              dependency.target != null &&
              dependency.target!.contains('/data/datasources/'),
        )
        .toList();

    expect(violations, isEmpty, reason: _report(violations));
  });

  test('lib y test no contienen archivos de respaldo', () {
    final backups = <String>[];
    for (final directoryName in const ['lib', 'test']) {
      final directory = Directory(directoryName);
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File) continue;
        final name = path.basename(entity.path).toLowerCase();
        if (name.contains('.backup_') ||
            name.endsWith('.bak') ||
            name.endsWith('.orig')) {
          backups.add(_relativeToRoot(Directory.current.path, entity.path));
        }
      }
    }

    expect(
      backups,
      isEmpty,
      reason: 'Respaldos encontrados:\n${backups.join('\n')}',
    );
  });

  test('la estructura no contiene directorios vacíos ni módulos ficticios', () {
    final emptyDirectories = <String>[];
    for (final directoryName in const ['lib', 'test']) {
      final directory = Directory(directoryName);
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! Directory) continue;
        if (entity.listSync().isEmpty) {
          emptyDirectories.add(
            _relativeToRoot(Directory.current.path, entity.path),
          );
        }
      }
    }

    expect(
      emptyDirectories,
      isEmpty,
      reason: 'Directorios vacíos encontrados:\n${emptyDirectories.join('\n')}',
    );
  });

  test('no quedan fachadas de exportación ni nombres temporales', () {
    final violations = <String>[];
    final temporaryName = RegExp(
      r'(?:corregid[oa]|integrad[oa]|backup_|_final|_v\d+)',
      caseSensitive: false,
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || path.extension(entity.path) != '.dart') continue;
      final relative = _relativeToRoot(Directory.current.path, entity.path);
      if (temporaryName.hasMatch(path.basenameWithoutExtension(entity.path))) {
        violations.add('$relative: nombre temporal');
      }

      final meaningfulLines = entity
          .readAsLinesSync()
          .map((line) => line.trim())
          .where(
            (line) =>
                line.isNotEmpty &&
                !line.startsWith('//') &&
                !line.startsWith('/*') &&
                !line.startsWith('*'),
          )
          .toList();
      if (meaningfulLines.isNotEmpty &&
          meaningfulLines.length <= 3 &&
          meaningfulLines.every((line) => line.startsWith('export '))) {
        violations.add('$relative: fachada de exportación');
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('todo archivo fuente tiene consumidor o es un puerto deliberado', () {
    final importedFiles = dependencies
        .map((dependency) => dependency.target)
        .whereType<String>()
        .toSet();
    const extensionPoints = <String>{
      'lib/main.dart',
      'lib/features/auth/domain/repositories/auth_repository.dart',
      'lib/features/auth/domain/repositories/role_repository.dart',
    };
    final unreachable = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || path.extension(entity.path) != '.dart') continue;
      final relative = _relativeToRoot(Directory.current.path, entity.path);
      if (!importedFiles.contains(relative) &&
          !extensionPoints.contains(relative)) {
        unreachable.add(relative);
      }
    }

    expect(
      unreachable,
      isEmpty,
      reason: 'Archivos sin consumidor:\n${unreachable.join('\n')}',
    );
  });
}

List<_Dependency> _scanDependencies(Directory projectRoot) {
  final rootPath = path.normalize(projectRoot.absolute.path);
  final libDirectory = Directory(path.join(rootPath, 'lib'));
  final directivePattern = RegExp(
    r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  final dependencies = <_Dependency>[];

  for (final entity in libDirectory.listSync(recursive: true)) {
    if (entity is! File || path.extension(entity.path) != '.dart') continue;

    final sourceAbsolute = path.normalize(entity.absolute.path);
    final source = _relativeToRoot(rootPath, sourceAbsolute);
    final contents = entity.readAsStringSync();
    for (final match in directivePattern.allMatches(contents)) {
      final uri = match.group(1)!;
      final targetAbsolute = _resolveLocalUri(
        rootPath: rootPath,
        sourceAbsolute: sourceAbsolute,
        uri: uri,
      );
      final target = targetAbsolute == null
          ? null
          : _relativeToRoot(rootPath, targetAbsolute);
      final line =
          '\n'.allMatches(contents.substring(0, match.start)).length + 1;
      dependencies.add(
        _Dependency(source: source, target: target, uri: uri, line: line),
      );
    }
  }

  return dependencies;
}

String? _resolveLocalUri({
  required String rootPath,
  required String sourceAbsolute,
  required String uri,
}) {
  String? candidate;
  const packagePrefix = 'package:app_catalogo/';

  if (uri.startsWith(packagePrefix)) {
    candidate = path.join(
      rootPath,
      'lib',
      _asPlatformPath(uri.substring(packagePrefix.length)),
    );
  } else if (!uri.startsWith('dart:') && !uri.startsWith('package:')) {
    candidate = path.join(path.dirname(sourceAbsolute), _asPlatformPath(uri));
  }

  if (candidate == null) return null;
  final normalized = path.normalize(candidate);
  return File(normalized).existsSync() ? normalized : null;
}

String _asPlatformPath(String uriPath) =>
    uriPath.replaceAll('/', path.separator);

String _relativeToRoot(String rootPath, String absolutePath) =>
    path.relative(absolutePath, from: rootPath).replaceAll('\\', '/');

bool _isInside(String filePath, String directory) =>
    filePath.split('/').contains(directory);

bool _isBlocContract(String source) =>
    source.contains('/presentation/bloc/') &&
    RegExp(r'_(?:bloc|event|state)\.dart$').hasMatch(source);

String _packageName(String uri) {
  if (!uri.startsWith('package:')) return '';
  return uri.substring('package:'.length).split('/').first;
}

String _report(List<_Dependency> violations) {
  if (violations.isEmpty) return '';
  final lines = violations
      .map(
        (dependency) =>
            '${dependency.source}:${dependency.line} -> '
            '${dependency.target ?? dependency.uri}',
      )
      .join('\n');
  return 'Dependencias no permitidas:\n$lines';
}

class _Dependency {
  const _Dependency({
    required this.source,
    required this.target,
    required this.uri,
    required this.line,
  });

  final String source;
  final String? target;
  final String uri;
  final int line;
}
