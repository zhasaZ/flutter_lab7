// Автоматически вносит Android-изменения для Firebase (см. ANDROID_SETUP.md).
// Запуск из корня Flutter-проекта:  dart run tool/setup_android.dart
// Скрипт можно запускать повторно: уже внесённые правки он пропускает.
import 'dart:io';

const settingsPath = 'android/settings.gradle.kts';
const buildPath = 'android/app/build.gradle.kts';
const manifestPath = 'android/app/src/main/AndroidManifest.xml';

void main() {
  patchSettings();
  patchAppBuild();
  patchManifest();
  stdout.writeln('\nГотово. Дальше: flutterfire configure, затем flutter run');
}

String readFile(String path) {
  final f = File(path);
  if (!f.existsSync()) {
    stderr.writeln('Не найден файл $path.');
    stderr.writeln('Запускай скрипт из корня Flutter-проекта (после flutter create).');
    exit(1);
  }
  return f.readAsStringSync();
}

void writeFile(String path, String text) => File(path).writeAsStringSync(text);

/// Вставляет [insert] новой строкой после первой строки с [marker]
/// (с тем же отступом). Если marker не найден — возвращает null.
String? insertAfterLine(String src, String marker, String insert) {
  final lines = src.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains(marker)) {
      final line = lines[i];
      final indent = line.substring(0, line.length - line.trimLeft().length);
      lines.insert(i + 1, '$indent$insert');
      return lines.join('\n');
    }
  }
  return null;
}

void patchSettings() {
  var s = readFile(settingsPath);
  if (s.contains('com.google.gms.google-services')) {
    stdout.writeln('settings.gradle.kts: уже настроен, пропускаю');
    return;
  }
  final r = insertAfterLine(
    s,
    'id("com.android.application")',
    'id("com.google.gms.google-services") version "4.4.2" apply false',
  );
  if (r == null) {
    stderr.writeln('settings.gradle.kts: не нашёл блок plugins, добавь вручную (ANDROID_SETUP.md)');
    return;
  }
  writeFile(settingsPath, r);
  stdout.writeln('settings.gradle.kts: плагин google-services добавлен');
}

void patchAppBuild() {
  var s = readFile(buildPath);
  var changed = false;

  if (!s.contains('com.google.gms.google-services')) {
    final r = insertAfterLine(
      s,
      'id("com.android.application")',
      'id("com.google.gms.google-services")',
    );
    if (r != null) {
      s = r;
      changed = true;
    } else {
      stderr.writeln('build.gradle.kts: не удалось добавить плагин google-services');
    }
  }

  final minSdk = RegExp(r'minSdk\s*=\s*[^\r\n]+');
  if (minSdk.hasMatch(s) && !RegExp(r'minSdk\s*=\s*23\s*(\r|\n|$)').hasMatch(s)) {
    s = s.replaceFirst(minSdk, 'minSdk = 23');
    changed = true;
  }

  if (!s.contains('isCoreLibraryDesugaringEnabled')) {
    final r = insertAfterLine(
      s,
      'compileOptions {',
      'isCoreLibraryDesugaringEnabled = true',
    );
    if (r != null) {
      s = r;
      changed = true;
    } else {
      stderr.writeln('build.gradle.kts: не нашёл compileOptions, добавь вручную');
    }
  }

  if (!s.contains('coreLibraryDesugaring(')) {
    s = '$s\ndependencies {\n'
        '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
        '}\n';
    changed = true;
  }

  if (changed) {
    writeFile(buildPath, s);
    stdout.writeln('app/build.gradle.kts: обновлён');
  } else {
    stdout.writeln('app/build.gradle.kts: уже настроен, пропускаю');
  }
}

void patchManifest() {
  var s = readFile(manifestPath);
  var changed = false;
  const perms = {
    'android.permission.POST_NOTIFICATIONS': true,
    'android.permission.INTERNET': true,
  };
  for (final p in perms.keys) {
    if (!s.contains(p)) {
      s = s.replaceFirst(
        '<application',
        '<uses-permission android:name="$p"/>\n    <application',
      );
      changed = true;
    }
  }
  if (changed) {
    writeFile(manifestPath, s);
    stdout.writeln('AndroidManifest.xml: разрешения добавлены');
  } else {
    stdout.writeln('AndroidManifest.xml: уже настроен, пропускаю');
  }
}
