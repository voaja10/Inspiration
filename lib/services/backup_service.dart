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
        throw StateError('Fichier de base de données non trouvé à $dbPath');
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
      if (output == null) throw StateError('Échec de la création de l\'archive de sauvegarde');

      final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final target = File(p.join(appDir.path, 'sauvegarde_$date.zip'));
      await target.writeAsBytes(output, flush: true);

      final sizeInMb = target.lengthSync() / (1024 * 1024);
      if (sizeInMb > maxBackupSizeMb) {
        throw StateError('Sauvegarde trop grande: ${sizeInMb.toStringAsFixed(2)}MB (max: ${maxBackupSizeMb}MB)');
      }

      return target.path;
    } catch (e) {
      throw StateError('Exportation de la sauvegarde échouée: $e');
    }
  }

  Future<void> importBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Sélectionner le fichier de sauvegarde',
    );
    if (picked == null || picked.files.single.path == null) return;
    await importBackupFromZipPath(picked.files.single.path!);
  }

  Future<void> importBackupFromZipPath(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      if (!zipFile.existsSync()) {
        throw StateError('Fichier de sauvegarde non trouvé: $zipPath');
      }

      final bytes = await zipFile.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('Fichier de sauvegarde vide');
      }

      final archive = ZipDecoder().decodeBytes(bytes);
      _validateBackup(archive);

      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await _database.databasePath;
      
      // CRITICAL: Close database BEFORE any file operations
      await _database.close();

      try {
        // Step 1: Delete old database and SQLite journal files to clean slate
        final dbFile = File(dbPath);
        if (dbFile.existsSync()) {
          await dbFile.delete();
        }
        // SQLite creates WAL and SHM files - remove them too
        final walFile = File('$dbPath-wal');
        if (walFile.existsSync()) {
          await walFile.delete();
        }
        final shmFile = File('$dbPath-shm');
        if (shmFile.existsSync()) {
          await shmFile.delete();
        }

        // Step 2: Extract and replace database file from backup
        final backupDbEntry = archive.files.firstWhere(
          (f) => p.normalize(f.name) == AppDatabase.dbName,
          orElse: () => throw StateError('Fichier de base de données introuvable dans la sauvegarde'),
        );
        final newDbFile = File(dbPath);
        await newDbFile.parent.create(recursive: true);
        await newDbFile.writeAsBytes(backupDbEntry.content as List<int>, flush: true);

        // Step 3: Clear old attachments completely
        final attachmentsRoot = Directory(p.join(appDir.path, 'attachments'));
        if (attachmentsRoot.existsSync()) {
          await attachmentsRoot.delete(recursive: true);
        }

        // Step 4: Restore attachments from backup
        for (final item in archive.files) {
          if (!item.isFile) continue;
          final normalized = p.normalize(item.name);
          if (normalized == AppDatabase.dbName) continue; // Skip DB file (already restored)
          
          final outPath = resolveRestoreOutputPath(
            normalizedEntryPath: normalized,
            appDirPath: appDir.path,
            databasePath: dbPath,
          );
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(item.content as List<int>, flush: true);
        }

        // Step 5: Re-open database cleanly (will NOT recreate tables since file exists)
        await _database.resetConnection();

        // Step 6: Verify database integrity
        await _verifyDatabaseIntegrity();
      } catch (e) {
        // Attempt to recover if restoration failed
        try {
          await _database.resetConnection();
        } catch (_) {
          // Ignore errors during recovery
        }
        rethrow;
      }
    } catch (e) {
      throw StateError('Restauration de la sauvegarde échouée: $e');
    }
  }

  Future<void> _verifyDatabaseIntegrity() async {
    try {
      final db = await _database.database;
      await db.rawQuery('SELECT COUNT(*) FROM sqlite_master WHERE type="table"');
    } catch (e) {
      throw StateError('Vérification de l\'intégrité de la base de données échouée: $e');
    }
  }

  void _validateBackup(Archive archive) {
    if (archive.files.isEmpty) {
      throw const FormatException('Sauvegarde invalide: archive vide');
    }

    final hasDb = archive.files.any((f) => p.normalize(f.name) == AppDatabase.dbName);
    if (!hasDb) {
      throw const FormatException('Sauvegarde invalide: fichier de base de données non trouvé');
    }

    for (final file in archive.files) {
      if (file.name.contains('..')) {
        throw FormatException('Sauvegarde invalide: chemin de fichier suspect: ${file.name}');
      }
    }

    final totalSize = archive.files.fold<int>(0, (sum, f) => sum + (f.size ?? 0));
    if (totalSize > maxBackupSizeMb * 1024 * 1024) {
      throw StateError('Sauvegarde trop grande: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
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
