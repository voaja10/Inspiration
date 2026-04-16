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
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Column(
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey600, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RAPPORT DE SESSION D\'ACHAT',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('${session.name} — ${session.status.name.toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Généré: ${timeFormat.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text('Créé: ${dateFormat.format(session.createdAt)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Two-column layout: Invoices (left) and Payments (right)
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Invoices
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FACTURES',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Table.fromTextArray(
                          headers: ['Référence', 'RMB Initial', 'Rectif.', 'RMB Final'],
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
                          cellAlignment: pw.Alignment.centerLeft,
                          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1.5),
                            1: const pw.FlexColumnWidth(1.2),
                            2: const pw.FlexColumnWidth(1.0),
                            3: const pw.FlexColumnWidth(1.2),
                          },
                          cellAlignments: {
                            1: pw.Alignment.centerRight,
                            2: pw.Alignment.centerRight,
                            3: pw.Alignment.centerRight,
                          },
                          data: invoices.map((invoice) {
                            final corrections = correctionsByInvoiceId[invoice.id] ?? [];
                            final corrTotal = corrections.fold<double>(0, (sum, c) => sum + c.amountRmb);
                            final finalAmount = invoice.amountInitialRmb + corrTotal;
                            return [
                              invoice.reference,
                              _formatCurrency(invoice.amountInitialRmb),
                              corrTotal != 0 ? _formatCurrency(corrTotal) : '—',
                              _formatCurrency(finalAmount),
                            ];
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  
                  // Right: Payments
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VERSEMENTS',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Table.fromTextArray(
                          headers: ['Date', 'Montant MGA', 'Montant RMB', 'Taux'],
                          headerStyle: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey600),
                          cellAlignment: pw.Alignment.centerLeft,
                          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                          columnWidths: {
                            0: const pw.FlexColumnWidth(1.0),
                            1: const pw.FlexColumnWidth(1.3),
                            2: const pw.FlexColumnWidth(1.2),
                            3: const pw.FlexColumnWidth(0.9),
                          },
                          cellAlignments: {
                            1: pw.Alignment.centerRight,
                            2: pw.Alignment.centerRight,
                            3: pw.Alignment.centerRight,
                          },
                          data: payments.map((p) {
                            return [
                              dateFormat.format(p.date),
                              _formatCurrency(p.amountMga),
                              _formatCurrency(p.amountRmbComputed),
                              p.exchangeRate.toStringAsFixed(2),
                            ];
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Bottom: Summary totals
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColors.blueGrey50,
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL FACTURES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatCurrency(summary.totalInvoices),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TOTAL VERSEMENTS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatCurrency(summary.totalPayments),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RESTE À PAYER', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_formatCurrency(summary.remainingBalance),
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
          ],
        ),
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
