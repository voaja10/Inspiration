import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';
import '../utils/strings.dart';

class AuditHistoryScreen extends ConsumerWidget {
  const AuditHistoryScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.auditHistory)),
      body: FutureBuilder<List<AuditLog>>(
        future: ref.read(repositoryProvider).auditLogsForSession(sessionId),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(child: Text(AppStrings.noAuditRecords));
          }
          final grouped = <String, List<AuditLog>>{};
          for (final log in logs) {
            final key = '${log.tableName} :: ${log.elementId}';
            grouped.putIfAbsent(key, () => <AuditLog>[]).add(log);
          }
          final keys = grouped.keys.toList();
          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final key = keys[i];
              final groupLogs = grouped[key]!;
              final latest = groupLogs.first;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text('${_entityLabel(latest.tableName)} (${groupLogs.length})'),
                  subtitle: Text('ID: ${latest.elementId}'),
                  children: groupLogs.map((log) {
                    final changes = _extractChanges(log);
                    return ListTile(
                      dense: true,
                      title: Row(
                        children: [
                          Icon(_actionIcon(log.actionType), size: 16, color: _actionColor(log.actionType)),
                          const SizedBox(width: 6),
                          Text('${_actionLabel(log.actionType)} • ${fmtDate(log.createdAt)}'),
                        ],
                      ),
                      subtitle: _buildChangesSummary(log, changes),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChangesSummary(AuditLog log, List<String> changes) {
    if (log.actionType == AuditActionType.create) {
      return Text(AppStrings.auditActionCreate);
    }
    if (log.actionType == AuditActionType.delete) {
      return Text(AppStrings.auditActionDelete);
    }
    if (log.actionType == AuditActionType.restore) {
      return Text(AppStrings.auditActionRestore);
    }
    if (log.actionType == AuditActionType.protectedEdit) {
      return Text(AppStrings.auditActionProtectedEdit);
    }
    if (changes.isEmpty) {
      return Text(AppStrings.auditNoChanges);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(changes.take(3).join('\n'), maxLines: 3, overflow: TextOverflow.ellipsis),
    );
  }

  List<String> _extractChanges(AuditLog log) {
    Map<String, dynamic> parseJsonMap(String? raw) {
      if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return <String, dynamic>{};
      }
      return <String, dynamic>{};
    }

    final oldMap = parseJsonMap(log.oldValueJson);
    final newMap = parseJsonMap(log.newValueJson);
    final keys = <String>{...oldMap.keys, ...newMap.keys}.toList()..sort();
    final lines = <String>[];
    for (final key in keys) {
      final oldValue = oldMap[key];
      final newValue = newMap[key];
      if (oldValue?.toString() == newValue?.toString()) continue;
      // Skip internal fields
      if (key == 'id' || key == 'sessionId' || key == 'invoiceId' || key == 'elementId' || key == 'tableName' || key == 'type') continue;
      final label = _formatFieldName(key);
      final oldFormatted = _formatValue(key, oldValue);
      final newFormatted = _formatValue(key, newValue);
      lines.add('$label: $oldFormatted → $newFormatted');
    }
    return lines;
  }

  String _formatFieldName(String key) {
    const labels = <String, String>{
      'amountInitialRmb': 'Initial RMB',
      'amountRmb': 'Correction RMB',
      'amountRmbComputed': 'Computed RMB',
      'amountMga': 'Payment MGA',
      'exchangeRate': 'Exchange Rate',
      'createdAt': 'Created At',
      'updatedAt': 'Updated At',
      'sessionId': 'Session ID',
      'invoiceId': 'Invoice ID',
      'elementId': 'Element ID',
      'tableName': 'Table',
      'actionType': 'Action',
      'filePath': 'File Path',
      'fileSize': 'File Size',
      'reference': 'Reference',
      'supplier': 'Supplier',
      'reason': 'Reason',
      'note': 'Note',
      'status': 'Status',
      'date': 'Date',
      'type': 'Type',
      'name': 'Name',
      'id': 'ID',
    };
    return labels[key] ?? key;
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      if (key.toLowerCase().contains('mga')) return fmtMga(value.toDouble());
      if (key.toLowerCase().contains('rmb')) return fmtRmb(value.toDouble());
      if (key == 'exchangeRate') return value.toStringAsFixed(2);
      if (key == 'fileSize') return '${(value / 1024).toStringAsFixed(1)} KB';
      return value.toString();
    }
    final str = value.toString();
    if (_looksLikeIsoDate(str)) {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return fmtDate(parsed);
    }
    if (str.isEmpty) return '-';
    return str;
  }

  bool _looksLikeIsoDate(String value) {
    return value.length >= 10 && value.contains('-') && value.contains(':');
  }

  String _entityLabel(String tableName) {
    switch (tableName) {
      case 'sessions':
        return 'Session';
      case 'invoices':
        return 'Invoice';
      case 'corrections':
        return 'Correction';
      case 'payments':
        return 'Payment';
      case 'attachments':
        return 'Attachment';
      default:
        return tableName;
    }
  }

  String _actionLabel(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
        return 'Created';
      case AuditActionType.update:
        return 'Updated';
      case AuditActionType.delete:
        return 'Deleted';
      case AuditActionType.restore:
        return 'Restored';
      case AuditActionType.protectedEdit:
        return 'Protected Edit';
    }
  }

  IconData _actionIcon(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
        return Icons.add_circle_outline;
      case AuditActionType.update:
        return Icons.edit_outlined;
      case AuditActionType.delete:
        return Icons.delete_outline;
      case AuditActionType.restore:
        return Icons.restore;
      case AuditActionType.protectedEdit:
        return Icons.verified_user_outlined;
    }
  }

  Color _actionColor(AuditActionType action) {
    switch (action) {
      case AuditActionType.create:
        return Colors.green;
      case AuditActionType.update:
        return Colors.blue;
      case AuditActionType.delete:
        return Colors.red;
      case AuditActionType.restore:
        return Colors.orange;
      case AuditActionType.protectedEdit:
        return Colors.indigo;
    }
  }
}
