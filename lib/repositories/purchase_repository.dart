import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';
import '../models/app_models.dart';

class PurchaseRepository {
  PurchaseRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<List<Session>> getSessions() async {
    final db = await _database.database;
    final rows = await db.query('sessions', orderBy: 'createdAt DESC');
    return rows.map(Session.fromMap).toList();
  }

  Future<Session> createSession(String name) async {
    final now = DateTime.now();
    final session = Session(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      status: SessionStatus.open,
    );
    final db = await _database.database;
    await db.insert('sessions', session.toMap());
    await _insertAudit(db, 'sessions', session.id, null, session.toMap(), AuditActionType.create);
    return session;
  }

  Future<void> closeSession(String sessionId) async {
    final db = await _database.database;
    final existing = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId], limit: 1);
    if (existing.isEmpty) return;
    final old = existing.first;
    final next = {...old, 'status': SessionStatus.closed.name};
    await db.update('sessions', {'status': SessionStatus.closed.name}, where: 'id = ?', whereArgs: [sessionId]);
    await _insertAudit(db, 'sessions', sessionId, old, next, AuditActionType.update);
  }

  Future<List<Invoice>> invoicesBySession(String sessionId) async {
    final db = await _database.database;
    final rows = await db.query('invoices', where: 'sessionId = ?', whereArgs: [sessionId], orderBy: 'createdAt DESC');
    return rows.map(Invoice.fromMap).toList();
  }

  Future<Session?> getSessionById(String sessionId) async {
    final db = await _database.database;
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId], limit: 1);
    if (rows.isEmpty) return null;
    return Session.fromMap(rows.first);
  }

  Future<Invoice?> getInvoiceById(String invoiceId) async {
    final db = await _database.database;
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId], limit: 1);
    if (rows.isEmpty) return null;
    return Invoice.fromMap(rows.first);
  }

  Future<List<Correction>> correctionsByInvoice(String invoiceId) async {
    final db = await _database.database;
    final rows = await db.query('corrections', where: 'invoiceId = ?', whereArgs: [invoiceId], orderBy: 'date DESC');
    return rows.map(Correction.fromMap).toList();
  }

  Future<List<Payment>> paymentsBySession(String sessionId) async {
    final db = await _database.database;
    final rows = await db.query('payments', where: 'sessionId = ?', whereArgs: [sessionId], orderBy: 'date DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<Payment?> getPaymentById(String paymentId) async {
    final db = await _database.database;
    final rows = await db.query('payments', where: 'id = ?', whereArgs: [paymentId], limit: 1);
    if (rows.isEmpty) return null;
    return Payment.fromMap(rows.first);
  }

  Future<List<Attachment>> attachmentsFor(String elementId, AttachmentType type) async {
    final db = await _database.database;
    final rows = await db.query(
      'attachments',
      where: 'elementId = ? AND type = ?',
      whereArgs: [elementId, type.name],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Attachment.fromMap).toList();
  }

  Future<List<AuditLog>> auditLogs({String? tableName, String? elementId}) async {
    final db = await _database.database;
    final filters = <String>[];
    final args = <Object?>[];
    if (tableName != null) {
      filters.add('tableName = ?');
      args.add(tableName);
    }
    if (elementId != null) {
      filters.add('elementId = ?');
      args.add(elementId);
    }
    final rows = await db.query(
      'audit_logs',
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createdAt DESC',
      limit: 250,
    );
    return rows.map(AuditLog.fromMap).toList();
  }

  Future<List<AuditLog>> auditLogsForSession(String sessionId) async {
    final db = await _database.database;
    final invoiceRows = await db.query('invoices', columns: ['id'], where: 'sessionId = ?', whereArgs: [sessionId]);
    final paymentRows = await db.query('payments', columns: ['id'], where: 'sessionId = ?', whereArgs: [sessionId]);
    final invoiceIds = invoiceRows.map((e) => e['id'] as String).toSet();
    final paymentIds = paymentRows.map((e) => e['id'] as String).toSet();

    final allLogs = await auditLogs();
    return allLogs.where((log) {
      if (log.tableName == 'sessions' && log.elementId == sessionId) return true;
      if (log.tableName == 'invoices' && invoiceIds.contains(log.elementId)) return true;
      if (log.tableName == 'payments' && paymentIds.contains(log.elementId)) return true;
      if (log.tableName == 'corrections') {
        final newValue = log.newValueJson ?? '';
        final oldValue = log.oldValueJson ?? '';
        return invoiceIds.any((id) => newValue.contains(id) || oldValue.contains(id));
      }
      if (log.tableName == 'attachments') {
        final newValue = log.newValueJson ?? '';
        final oldValue = log.oldValueJson ?? '';
        return invoiceIds.any((id) => newValue.contains(id) || oldValue.contains(id)) ||
            paymentIds.any((id) => newValue.contains(id) || oldValue.contains(id));
      }
      return false;
    }).toList();
  }

  Future<Invoice> createInvoice({
    required String sessionId,
    required String reference,
    String? supplier,
    required double amountInitialRmb,
  }) async {
    await _assertSessionOpen(sessionId);
    final now = DateTime.now();
    final invoice = Invoice(
      id: _uuid.v4(),
      sessionId: sessionId,
      reference: reference,
      supplier: supplier,
      amountInitialRmb: amountInitialRmb,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _database.database;
    await db.insert('invoices', invoice.toMap());
    await _insertAudit(db, 'invoices', invoice.id, null, invoice.toMap(), AuditActionType.create);
    return invoice;
  }

  Future<Correction> addCorrection({
    required String invoiceId,
    required DateTime date,
    required double amountRmb,
    required String reason,
  }) async {
    final db = await _database.database;
    final invoiceRows = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId], limit: 1);
    if (invoiceRows.isEmpty) throw StateError('Invoice not found');
    await _assertSessionOpen(invoiceRows.first['sessionId'] as String);
    final correction = Correction(id: _uuid.v4(), invoiceId: invoiceId, date: date, amountRmb: amountRmb, reason: reason);
    await db.insert('corrections', correction.toMap());
    await _insertAudit(db, 'corrections', correction.id, null, correction.toMap(), AuditActionType.create);
    return correction;
  }

  Future<Payment> createPayment({
    required String sessionId,
    required DateTime date,
    required double amountMga,
    required double exchangeRate,
    String? note,
  }) async {
    await _assertSessionOpen(sessionId);
    final computed = Payment.computeRmb(amountMga, exchangeRate);
    final payment = Payment(
      id: _uuid.v4(),
      sessionId: sessionId,
      date: date,
      amountMga: amountMga,
      exchangeRate: exchangeRate,
      amountRmbComputed: computed,
      note: note,
    );
    final db = await _database.database;
    await db.insert('payments', payment.toMap());
    await _insertAudit(db, 'payments', payment.id, null, payment.toMap(), AuditActionType.create);
    return payment;
  }

  Future<void> updateSessionName({
    required String sessionId,
    required String newName,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final db = await _database.database;
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId], limit: 1);
    if (rows.isEmpty) throw StateError('Session not found');
    final old = rows.first;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw ArgumentError('Session name is required');
    final next = {...old, 'name': trimmed};
    await db.update('sessions', {'name': trimmed}, where: 'id = ?', whereArgs: [sessionId]);
    await _insertAudit(db, 'sessions', sessionId, old, next, AuditActionType.protectedEdit);
  }

  Future<void> reopenSession({
    required String sessionId,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final db = await _database.database;
    final existing = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId], limit: 1);
    if (existing.isEmpty) return;
    final old = existing.first;
    final next = {...old, 'status': SessionStatus.open.name};
    await db.update('sessions', {'status': SessionStatus.open.name}, where: 'id = ?', whereArgs: [sessionId]);
    await _insertAudit(db, 'sessions', sessionId, old, next, AuditActionType.protectedEdit);
  }

  Future<void> updateInvoice({
    required String invoiceId,
    required String reference,
    String? supplier,
    required double amountInitialRmb,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final refTrimmed = reference.trim();
    if (refTrimmed.isEmpty) throw ArgumentError('Reference is required');
    if (amountInitialRmb <= 0) throw ArgumentError('Initial RMB must be > 0');
    final db = await _database.database;
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId], limit: 1);
    if (rows.isEmpty) throw StateError('Invoice not found');
    final old = rows.first;
    await _assertSessionOpen(old['sessionId'] as String);
    final next = {
      ...old,
      'reference': refTrimmed,
      'supplier': supplier,
      'amountInitialRmb': amountInitialRmb,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await db.update(
      'invoices',
      {
        'reference': refTrimmed,
        'supplier': supplier,
        'amountInitialRmb': amountInitialRmb,
        'updatedAt': next['updatedAt'],
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    await _insertAudit(db, 'invoices', invoiceId, old, next, AuditActionType.update);
  }

  Future<void> updateCorrection({
    required String correctionId,
    required double amountRmb,
    required String reason,
    required DateTime date,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    if (amountRmb == 0) throw ArgumentError('Correction amount cannot be 0');
    final reasonTrimmed = reason.trim();
    if (reasonTrimmed.isEmpty) throw ArgumentError('Reason is required');
    final db = await _database.database;
    final rows = await db.query('corrections', where: 'id = ?', whereArgs: [correctionId], limit: 1);
    if (rows.isEmpty) throw StateError('Correction not found');
    final old = rows.first;
    final invoiceRows = await db.query('invoices', where: 'id = ?', whereArgs: [old['invoiceId']], limit: 1);
    if (invoiceRows.isNotEmpty) {
      await _assertSessionOpen(invoiceRows.first['sessionId'] as String);
    }
    final next = {...old, 'amountRmb': amountRmb, 'reason': reasonTrimmed, 'date': date.toIso8601String()};
    await db.update(
      'corrections',
      {'amountRmb': amountRmb, 'reason': reasonTrimmed, 'date': date.toIso8601String()},
      where: 'id = ?',
      whereArgs: [correctionId],
    );
    await _insertAudit(db, 'corrections', correctionId, old, next, AuditActionType.update);
  }

  Future<void> updatePayment({
    required String paymentId,
    required DateTime date,
    required double amountMga,
    required double exchangeRate,
    String? note,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    if (amountMga <= 0) throw ArgumentError('Payment MGA must be > 0');
    if (exchangeRate <= 0) throw ArgumentError('Exchange rate must be > 0');
    final db = await _database.database;
    final rows = await db.query('payments', where: 'id = ?', whereArgs: [paymentId], limit: 1);
    if (rows.isEmpty) throw StateError('Payment not found');
    final old = rows.first;
    await _assertSessionOpen(old['sessionId'] as String);
    final computed = Payment.computeRmb(amountMga, exchangeRate);
    final next = {
      ...old,
      'date': date.toIso8601String(),
      'amountMga': amountMga,
      'exchangeRate': exchangeRate,
      'amountRmbComputed': computed,
      'note': note,
    };
    await db.update(
      'payments',
      {
        'date': date.toIso8601String(),
        'amountMga': amountMga,
        'exchangeRate': exchangeRate,
        'amountRmbComputed': computed,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
    await _insertAudit(db, 'payments', paymentId, old, next, AuditActionType.update);
  }

  Future<void> deleteInvoice({
    required String invoiceId,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final db = await _database.database;
    final rows = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId], limit: 1);
    if (rows.isEmpty) return;
    final old = rows.first;
    await _assertSessionOpen(old['sessionId'] as String);
    await db.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    await _insertAudit(db, 'invoices', invoiceId, old, null, AuditActionType.delete);
  }

  Future<void> deleteCorrection({
    required String correctionId,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final db = await _database.database;
    final rows = await db.query('corrections', where: 'id = ?', whereArgs: [correctionId], limit: 1);
    if (rows.isEmpty) return;
    final old = rows.first;
    final invoiceRows = await db.query('invoices', where: 'id = ?', whereArgs: [old['invoiceId']], limit: 1);
    if (invoiceRows.isNotEmpty) {
      await _assertSessionOpen(invoiceRows.first['sessionId'] as String);
    }
    await db.delete('corrections', where: 'id = ?', whereArgs: [correctionId]);
    await _insertAudit(db, 'corrections', correctionId, old, null, AuditActionType.delete);
  }

  Future<void> deletePayment({
    required String paymentId,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final db = await _database.database;
    final rows = await db.query('payments', where: 'id = ?', whereArgs: [paymentId], limit: 1);
    if (rows.isEmpty) return;
    final old = rows.first;
    await _assertSessionOpen(old['sessionId'] as String);
    await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
    await _insertAudit(db, 'payments', paymentId, old, null, AuditActionType.delete);
  }

  Future<void> deleteAttachment({
    required String attachmentId,
    required bool confirmed,
  }) async {
    if (!confirmed) return;
    final db = await _database.database;
    final rows = await db.query('attachments', where: 'id = ?', whereArgs: [attachmentId], limit: 1);
    if (rows.isEmpty) return;
    final old = rows.first;
    await db.delete('attachments', where: 'id = ?', whereArgs: [attachmentId]);
    await _insertAudit(db, 'attachments', attachmentId, old, null, AuditActionType.delete);
  }

  Future<List<InvoiceListItem>> invoiceListItemsBySession(String sessionId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        i.id,
        i.sessionId,
        i.reference,
        i.supplier,
        i.amountInitialRmb,
        i.createdAt,
        i.updatedAt,
        COALESCE(SUM(c.amountRmb), 0) AS correctionsTotal,
        (
          SELECT COUNT(*) FROM attachments a
          WHERE a.elementId = i.id AND a.type = 'invoice'
        ) AS attachmentCount
      FROM invoices i
      LEFT JOIN corrections c ON c.invoiceId = i.id
      WHERE i.sessionId = ?
      GROUP BY i.id
      ORDER BY i.createdAt DESC
    ''', [sessionId]);
    return rows.map((row) {
      final invoice = Invoice.fromMap(row);
      final corr = (row['correctionsTotal'] as num?)?.toDouble() ?? 0;
      final attachCount = (row['attachmentCount'] as num?)?.toInt() ?? 0;
      return InvoiceListItem(
        invoice: invoice,
        correctionsTotal: corr,
        finalRmb: invoice.amountInitialRmb + corr,
        attachmentCount: attachCount,
      );
    }).toList();
  }

  Future<List<PaymentListItem>> paymentListItemsBySession(String sessionId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id,
        p.sessionId,
        p.date,
        p.amountMga,
        p.exchangeRate,
        p.amountRmbComputed,
        p.note,
        (
          SELECT COUNT(*) FROM attachments a
          WHERE a.elementId = p.id AND a.type = 'payment'
        ) AS attachmentCount
      FROM payments p
      WHERE p.sessionId = ?
      ORDER BY p.date DESC
    ''', [sessionId]);
    return rows.map((row) {
      final payment = Payment.fromMap(row);
      final attachCount = (row['attachmentCount'] as num?)?.toInt() ?? 0;
      return PaymentListItem(payment: payment, attachmentCount: attachCount);
    }).toList();
  }

  Future<void> saveAttachment(Attachment attachment) async {
    final db = await _database.database;
    await db.insert('attachments', attachment.toMap());
    await _insertAudit(db, 'attachments', attachment.id, null, attachment.toMap(), AuditActionType.create);
  }

  Future<SessionSummary> computeSummary(String sessionId) async {
    final db = await _database.database;
    final invoiceRows = await db.rawQuery('''
      SELECT i.amountInitialRmb + COALESCE(SUM(c.amountRmb), 0) AS finalAmount
      FROM invoices i
      LEFT JOIN corrections c ON c.invoiceId = i.id
      WHERE i.sessionId = ?
      GROUP BY i.id;
    ''', [sessionId]);
    final paymentRows = await db.rawQuery('SELECT amountRmbComputed FROM payments WHERE sessionId = ?;', [sessionId]);
    final totalInvoices = invoiceRows.fold<double>(
      0,
      (sum, row) => sum + ((row['finalAmount'] as num?)?.toDouble() ?? 0),
    );
    final totalPayments = paymentRows.fold<double>(
      0,
      (sum, row) => sum + ((row['amountRmbComputed'] as num?)?.toDouble() ?? 0),
    );
    return SessionSummary(
      totalInvoices: totalInvoices,
      totalPayments: totalPayments,
      remainingBalance: totalInvoices - totalPayments,
    );
  }

  Future<void> seedData() async {
    final current = await getSessions();
    if (current.isNotEmpty) return;
    final session = await createSession('FTS TRIP 2026');
    final invoice = await createInvoice(
      sessionId: session.id,
      reference: 'INV-FTS-001',
      supplier: 'Shenzhen Supplier',
      amountInitialRmb: 1230,
    );
    await addCorrection(
      invoiceId: invoice.id,
      date: DateTime.now(),
      amountRmb: -30,
      reason: 'Post-delivery missing items',
    );
    await createPayment(
      sessionId: session.id,
      date: DateTime.now(),
      amountMga: 3300000,
      exchangeRate: 650.0,
      note: 'First wire payment',
    );
  }

  Future<void> _assertSessionOpen(String sessionId) async {
    final db = await _database.database;
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId], limit: 1);
    if (rows.isEmpty) throw StateError('Session does not exist');
    if (rows.first['status'] == SessionStatus.closed.name) {
      throw StateError('Session is closed. Reopen with protected procedure first.');
    }
  }

  Future<void> _insertAudit(
    Database db,
    String tableName,
    String elementId,
    Map<String, Object?>? oldValue,
    Map<String, Object?>? newValue,
    AuditActionType action,
  ) async {
    final log = AuditLog(
      id: _uuid.v4(),
      tableName: tableName,
      elementId: elementId,
      oldValueJson: oldValue == null ? null : encodeJson(oldValue),
      newValueJson: newValue == null ? null : encodeJson(newValue),
      actionType: action,
      createdAt: DateTime.now(),
    );
    await db.insert('audit_logs', log.toMap());
  }
}
