import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  final lines = pubspecFile.readAsLinesSync();
  final versionIndex = lines.indexWhere((line) => line.startsWith('version:'));
  if (versionIndex == -1) {
    print('خطای نسخه: خط version در pubspec.yaml یافت نشد');
    exit(1);
  }

  final versionLine = lines[versionIndex];
  final versionParts = versionLine.split('+');
  final version = versionParts[0].replaceAll('version: ', '');
  final buildNumber = int.parse(versionParts[1]) + 1;

  lines[versionIndex] = 'version: $version+$buildNumber';
  pubspecFile.writeAsStringSync(lines.join('\n'));
  print('نسخه به‌روزرسانی شد: $version+$buildNumber');
} 