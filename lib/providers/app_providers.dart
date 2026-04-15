import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../models/app_models.dart';
import '../repositories/purchase_repository.dart';
import '../services/attachment_service.dart';
import '../services/backup_service.dart';
import '../services/pdf_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final repositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepository(ref.read(databaseProvider)),
);

final attachmentServiceProvider = Provider<AttachmentService>((ref) => AttachmentService());

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.read(databaseProvider)),
);

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  final repo = ref.read(repositoryProvider);
  return repo.getSessions();
});

final sessionSummaryProvider = FutureProvider.family<SessionSummary, String>((ref, sessionId) async {
  return ref.read(repositoryProvider).computeSummary(sessionId);
});

final sessionProvider = FutureProvider.family<Session?, String>((ref, sessionId) async {
  return ref.read(repositoryProvider).getSessionById(sessionId);
});

final invoiceListItemsProvider = FutureProvider.family<List<InvoiceListItem>, String>((ref, sessionId) async {
  return ref.read(repositoryProvider).invoiceListItemsBySession(sessionId);
});

final paymentListItemsProvider = FutureProvider.family<List<PaymentListItem>, String>((ref, sessionId) async {
  return ref.read(repositoryProvider).paymentListItemsBySession(sessionId);
});

final invoiceProvider = FutureProvider.family<Invoice?, String>((ref, invoiceId) async {
  return ref.read(repositoryProvider).getInvoiceById(invoiceId);
});

final paymentProvider = FutureProvider.family<Payment?, String>((ref, paymentId) async {
  return ref.read(repositoryProvider).getPaymentById(paymentId);
});

final correctionsProvider = FutureProvider.family<List<Correction>, String>((ref, invoiceId) async {
  return ref.read(repositoryProvider).correctionsByInvoice(invoiceId);
});

final attachmentsProvider = FutureProvider.family<List<Attachment>, ({String elementId, AttachmentType type})>((ref, params) async {
  return ref.read(repositoryProvider).attachmentsFor(params.elementId, params.type);
});
