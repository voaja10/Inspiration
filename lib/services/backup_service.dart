import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;
  static const int maxBackupSizeMb = 500;

  Future<String> exportBackup() async {
    try {
      final db = await _database.database;
      final dbPath = db.path;
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));

      final archive = Archive();
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        throw StateError('Database file not found at $dbPath');
      }
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile(AppDatabase.dbName, dbBytes.length, dbBytes));

      if (attachmentsDir.existsSync()) {
        for (final entity in attachmentsDir.listSync(recursive: true)) {
          if (entity is File) {
            final rel = p.relative(entity.path, from: appDir.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(rel, bytes.length, bytes));
          }
        }
      }

      final output = ZipEncoder().encode(archive);
      if (output == null) throw StateError('Failed to create backup archive');

      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final target = File(p.join(appDir.path, 'backup_$date.zip'));
      await target.writeAsBytes(output, flush: true);

      final sizeInMb = target.lengthSync() / (1024 * 1024);
      if (sizeInMb > maxBackupSizeMb) {
        throw StateError('Backup too large: ${sizeInMb.toStringAsFixed(2)}MB (max: ${maxBackupSizeMb}MB)');
      }

      return target.path;
    } catch (e) {
      throw StateError('Backup export failed: $e');
    }
  }

  Future<void> importBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Select Backup File',
    );
    if (picked == null || picked.files.single.path == null) return;
    await importBackupFromZipPath(picked.files.single.path!);
  }

  Future<void> importBackupFromZipPath(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) {
        throw StateError('Backup file not found: $zipPath');
      }

      final bytes = await zipFile.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('Backup file is empty');
      }

      final archive = ZipDecoder().decodeBytes(bytes);
      _validateBackup(archive);

      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await _database.databasePath;
      await _database.close();

      try {
        final attachmentsRoot = Directory(p.join(appDir.path, 'attachments'));
        if (attachmentsRoot.existsSync()) {
          attachmentsRoot.deleteSync(recursive: true);
        }

        for (final item in archive.files) {
          if (!item.isFile) continue;
          final normalized = p.normalize(item.name);
          final outPath = resolveRestoreOutputPath(
            normalizedEntryPath: normalized,
            appDirPath: appDir.path,
            databasePath: dbPath,
          );
          final outFile = File(outPath);
          outFile.parent.createSync(recursive: true);
          await outFile.writeAsBytes(item.content as List<int>, flush: true);
        }

        await _database.resetConnection();
        await _verifyDatabaseIntegrity();
      } catch (e) {
        await _database.resetConnection();
        rethrow;
      }
    } catch (e) {
      throw StateError('Backup import failed: $e');
    }
  }

  Future<void> _verifyDatabaseIntegrity() async {
    try {
      final db = await _database.database;
      await db.rawQuery('SELECT COUNT(*) FROM sqlite_master WHERE type="table"');
    } catch (e) {
      throw StateError('Database integrity check failed: $e');
    }
  }

  void _validateBackup(Archive archive) {
    if (archive.files.isEmpty) {
      throw const FormatException('Invalid backup: archive is empty');
    }

    final hasDb = archive.files.any((f) => p.normalize(f.name) == AppDatabase.dbName);
    if (!hasDb) {
      throw const FormatException('Invalid backup: database file not found');
    }

    for (final file in archive.files) {
      if (file.name.contains('..')) {
        throw FormatException('Invalid backup: suspicious file path: ${file.name}');
      }
    }

    final totalSize = archive.files.fold<int>(0, (sum, f) => sum + (f.size ?? 0));
    if (totalSize > maxBackupSizeMb * 1024 * 1024) {
      throw StateError('Backup too large: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
    }
  }

  static String resolveRestoreOutputPath({
    required String normalizedEntryPath,
    required String appDirPath,
    required String databasePath,
  }) {
    if (normalizedEntryPath.contains('..')) {
      throw const FormatException('Invalid backup: unsafe file path');
    }
    if (p.isAbsolute(normalizedEntryPath)) {
      throw const FormatException('Invalid backup: absolute file path');
    }
    return normalizedEntryPath == AppDatabase.dbName
        ? databasePath
        : p.join(appDirPath, normalizedEntryPath);
  }
}
