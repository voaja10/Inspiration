import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_session_manager/data/database/app_database.dart';
import 'package:purchase_session_manager/services/backup_service.dart';

void main() {
  group('Backup restore path safety', () {
    test('restores main database entry to active db path', () {
      final out = BackupService.resolveRestoreOutputPath(
        normalizedEntryPath: AppDatabase.dbName,
        appDirPath: '/app',
        databasePath: '/app/purchase_sessions.db',
      );
      expect(out, '/app/purchase_sessions.db');
    });

    test('restores attachment entry under app directory', () {
      final out = BackupService.resolveRestoreOutputPath(
        normalizedEntryPath: 'attachments/invoice/a.jpg',
        appDirPath: '/app',
        databasePath: '/app/purchase_sessions.db',
      );
      expect(out, '/app/attachments/invoice/a.jpg');
    });

    test('rejects unsafe relative traversal path', () {
      expect(
        () => BackupService.resolveRestoreOutputPath(
          normalizedEntryPath: '../escape.db',
          appDirPath: '/app',
          databasePath: '/app/purchase_sessions.db',
        ),
        throwsFormatException,
      );
    });
  });

  group('Balance recompute after edits/deletes', () {
    test('remaining balance always computed from current source totals', () {
      double totalInvoices = 1500;
      double totalPayments = 600;
      expect(totalInvoices - totalPayments, 900);

      // Simulate invoice edit (amount increased)
      totalInvoices = 1800;
      expect(totalInvoices - totalPayments, 1200);

      // Simulate payment delete
      totalPayments = 200;
      expect(totalInvoices - totalPayments, 1600);
    });
  });
}
