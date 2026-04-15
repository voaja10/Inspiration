import 'dart:convert';

enum SessionStatus { open, closed }

enum AttachmentType { invoice, payment }

enum AuditActionType { create, update, delete, restore, protectedEdit }

class Session {
  const Session({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final SessionStatus status;

  Session copyWith({String? name, SessionStatus? status}) {
    return Session(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };

  factory Session.fromMap(Map<String, Object?> map) => Session(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        status: SessionStatus.values.byName(map['status'] as String),
      );
}

class Invoice {
  const Invoice({
    required this.id,
    required this.sessionId,
    required this.reference,
    required this.supplier,
    required this.amountInitialRmb,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String reference;
  final String? supplier;
  final double amountInitialRmb;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'reference': reference,
        'supplier': supplier,
        'amountInitialRmb': amountInitialRmb,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Invoice.fromMap(Map<String, Object?> map) => Invoice(
        id: map['id'] as String,
        sessionId: map['sessionId'] as String,
        reference: map['reference'] as String,
        supplier: map['supplier'] as String?,
        amountInitialRmb: (map['amountInitialRmb'] as num).toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

class Correction {
  const Correction({
    required this.id,
    required this.invoiceId,
    required this.date,
    required this.amountRmb,
    required this.reason,
  });

  final String id;
  final String invoiceId;
  final DateTime date;
  final double amountRmb;
  final String reason;

  Map<String, Object?> toMap() => {
        'id': id,
        'invoiceId': invoiceId,
        'date': date.toIso8601String(),
        'amountRmb': amountRmb,
        'reason': reason,
      };

  factory Correction.fromMap(Map<String, Object?> map) => Correction(
        id: map['id'] as String,
        invoiceId: map['invoiceId'] as String,
        date: DateTime.parse(map['date'] as String),
        amountRmb: (map['amountRmb'] as num).toDouble(),
        reason: map['reason'] as String,
      );
}

class Payment {
  const Payment({
    required this.id,
    required this.sessionId,
    required this.date,
    required this.amountMga,
    required this.exchangeRate,
    required this.amountRmbComputed,
    required this.note,
  });

  final String id;
  final String sessionId;
  final DateTime date;
  final double amountMga;
  final double exchangeRate;
  final double amountRmbComputed;
  final String? note;

  static double computeRmb(double amountMga, double exchangeRate) {
    if (exchangeRate <= 0) {
      throw ArgumentError.value(exchangeRate, 'exchangeRate', 'Must be > 0');
    }
    return amountMga / exchangeRate;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'sessionId': sessionId,
        'date': date.toIso8601String(),
        'amountMga': amountMga,
        'exchangeRate': exchangeRate,
        'amountRmbComputed': amountRmbComputed,
        'note': note,
      };

  factory Payment.fromMap(Map<String, Object?> map) => Payment(
        id: map['id'] as String,
        sessionId: map['sessionId'] as String,
        date: DateTime.parse(map['date'] as String),
        amountMga: (map['amountMga'] as num).toDouble(),
        exchangeRate: (map['exchangeRate'] as num).toDouble(),
        amountRmbComputed: (map['amountRmbComputed'] as num).toDouble(),
        note: map['note'] as String?,
      );
}

class Attachment {
  const Attachment({
    required this.id,
    required this.type,
    required this.elementId,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
  });

  final String id;
  final AttachmentType type;
  final String elementId;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'elementId': elementId,
        'filePath': filePath,
        'fileSize': fileSize,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Attachment.fromMap(Map<String, Object?> map) => Attachment(
        id: map['id'] as String,
        type: AttachmentType.values.byName(map['type'] as String),
        elementId: map['elementId'] as String,
        filePath: map['filePath'] as String,
        fileSize: map['fileSize'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.tableName,
    required this.elementId,
    required this.oldValueJson,
    required this.newValueJson,
    required this.actionType,
    required this.createdAt,
  });

  final String id;
  final String tableName;
  final String elementId;
  final String? oldValueJson;
  final String? newValueJson;
  final AuditActionType actionType;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'tableName': tableName,
        'elementId': elementId,
        'oldValueJson': oldValueJson,
        'newValueJson': newValueJson,
        'actionType': actionType.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AuditLog.fromMap(Map<String, Object?> map) => AuditLog(
        id: map['id'] as String,
        tableName: map['tableName'] as String,
        elementId: map['elementId'] as String,
        oldValueJson: map['oldValueJson'] as String?,
        newValueJson: map['newValueJson'] as String?,
        actionType: AuditActionType.values.byName(map['actionType'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

class SessionSummary {
  const SessionSummary({
    required this.totalInvoices,
    required this.totalPayments,
    required this.remainingBalance,
  });

  final double totalInvoices;
  final double totalPayments;
  final double remainingBalance;
}

class InvoiceListItem {
  const InvoiceListItem({
    required this.invoice,
    required this.correctionsTotal,
    required this.finalRmb,
    required this.attachmentCount,
  });

  final Invoice invoice;
  final double correctionsTotal;
  final double finalRmb;
  final int attachmentCount;
}

class PaymentListItem {
  const PaymentListItem({
    required this.payment,
    required this.attachmentCount,
  });

  final Payment payment;
  final int attachmentCount;
}

String encodeJson(Map<String, Object?> value) => jsonEncode(value);
