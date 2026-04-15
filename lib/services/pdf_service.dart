import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_models.dart';

class PdfService {
  Future<Uint8List> buildSessionReport({
    required Session session,
    required List<Invoice> invoices,
    required Map<String, List<Correction>> correctionsByInvoiceId,
    required List<Payment> payments,
    required SessionSummary summary,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey600, width: 2)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PURCHASE SESSION REPORT',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Session Name:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(session.name, style: const pw.TextStyle(fontSize: 14)),
                        pw.SizedBox(height: 4),
                        pw.Text('Status:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(session.status.name.toUpperCase(), style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Generated:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(timeFormat.format(DateTime.now()), style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 4),
                        pw.Text('Created:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(dateFormat.format(session.createdAt), style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Invoices Section
          pw.Text(
            'INVOICES',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Reference', 'Supplier', 'Initial RMB', 'Corrections', 'Final RMB'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 11,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
            cellAlignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            data: invoices.map((invoice) {
              final corrections = correctionsByInvoiceId[invoice.id] ?? [];
              final corrTotal = corrections.fold<double>(0, (sum, c) => sum + c.amountRmb);
              final finalAmount = invoice.amountInitialRmb + corrTotal;
              return [
                invoice.reference,
                invoice.supplier ?? '—',
                _formatCurrency(invoice.amountInitialRmb),
                corrTotal != 0 ? _formatCurrency(corrTotal) : '—',
                _formatCurrency(finalAmount),
              ];
            }).toList(),
          ),
          if (invoices.any((i) => (correctionsByInvoiceId[i.id] ?? []).isNotEmpty)) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'CORRECTIONS DETAIL',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
            ),
            pw.SizedBox(height: 6),
            ...invoices.expand((invoice) {
              final corrections = correctionsByInvoiceId[invoice.id] ?? [];
              if (corrections.isEmpty) return [];
              return [
                pw.Text(
                  '${invoice.reference}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Amount RMB', 'Reason'],
                  headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey500),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {0: const pw.FlexColumnWidth(1.2), 1: const pw.FlexColumnWidth(1.2), 2: const pw.FlexColumnWidth(2)},
                  cellAlignments: {1: pw.Alignment.centerRight},
                  data: corrections.map((c) => [
                    dateFormat.format(c.date),
                    _formatCurrency(c.amountRmb),
                    c.reason,
                  ]).toList(),
                ),
                pw.SizedBox(height: 8),
              ];
            }).toList(),
          ],
          pw.SizedBox(height: 16),
          // Payments Section
          pw.Text(
            'PAYMENTS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Date', 'MGA Amount', 'Exchange Rate', 'RMB Computed', 'Note'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 11,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(1.6),
            },
            cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
            data: payments.map((p) {
              return [
                dateFormat.format(p.date),
                _formatCurrency(p.amountMga, prefix: 'MGA '),
                p.exchangeRate.toStringAsFixed(4),
                _formatCurrency(p.amountRmbComputed),
                p.note ?? '—',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          // Summary Section
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 320,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.blueGrey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SUMMARY',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                  ),
                  pw.Divider(color: PdfColors.blueGrey700, height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Invoices:', style: pw.TextStyle(fontSize: 11)),
                      pw.Text(_formatCurrency(summary.totalInvoices), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Payments:', style: pw.TextStyle(fontSize: 11)),
                      pw.Text(_formatCurrency(summary.totalPayments), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.blueGrey700, height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Remaining Balance:',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        _formatCurrency(summary.remainingBalance),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: summary.remainingBalance >= 0 ? PdfColors.green700 : PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  String _formatCurrency(double value, {String prefix = ''}) {
    return '$prefix${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Future<void> printBytes(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
