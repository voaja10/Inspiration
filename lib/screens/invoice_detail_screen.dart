import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({required this.invoice, required this.sessionId, super.key});
  final Invoice invoice;
  final String sessionId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Future<void> _refresh() async {
    ref.invalidate(invoiceProvider(widget.invoice.id));
    ref.invalidate(sessionProvider(widget.sessionId));
    ref.invalidate(invoiceListItemsProvider(widget.sessionId));
    ref.invalidate(sessionSummaryProvider(widget.sessionId));
    ref.invalidate(correctionsProvider(widget.invoice.id));
    ref.invalidate(attachmentsProvider((elementId: widget.invoice.id, type: AttachmentType.invoice)));
  }

  Future<void> _editInvoice(Invoice currentInvoice) async {
    final formKey = GlobalKey<FormState>();
    final refCtrl = TextEditingController(text: currentInvoice.reference);
    final supplierCtrl = TextEditingController(text: currentInvoice.supplier ?? '');
    final amountCtrl = TextEditingController(text: currentInvoice.amountInitialRmb.toStringAsFixed(2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Invoice'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference'),
                validator: FormValidators.validateInvoiceReference,
              ),
              TextFormField(
                controller: supplierCtrl,
                decoration: const InputDecoration(labelText: 'Supplier (optional)'),
                validator: FormValidators.validateOptional,
              ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Initial RMB'),
                validator: (value) => FormValidators.validateAmount(value, fieldName: 'Initial RMB'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm update'),
        content: const Text('Apply invoice changes and log audit history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(repositoryProvider).updateInvoice(
            invoiceId: currentInvoice.id,
            reference: refCtrl.text.trim(),
            supplier: supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
            amountInitialRmb: double.parse(amountCtrl.text.trim()),
            confirmed: true,
          );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating invoice: $e')),
      );
    }
  }

  Future<void> _addCorrection(Invoice currentInvoice) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Correction'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Amount RMB (+/-)'),
                validator: (value) => FormValidators.validatePositiveAmount(value, fieldName: 'Correction amount'),
              ),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: FormValidators.validateReason,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).addCorrection(
            invoiceId: currentInvoice.id,
            date: DateTime.now(),
            amountRmb: double.parse(amountCtrl.text.trim()),
            reason: reasonCtrl.text.trim(),
          );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding correction: $e')),
      );
    }
  }

  Future<void> _editCorrection(Correction correction) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: correction.amountRmb.toStringAsFixed(2));
    final reasonCtrl = TextEditingController(text: correction.reason);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Correction'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Amount RMB (+/-)'),
                validator: (value) => FormValidators.validatePositiveAmount(value, fieldName: 'Correction amount'),
              ),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: FormValidators.validateReason,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm update'),
        content: const Text('Apply correction changes and keep audit trail?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(repositoryProvider).updateCorrection(
            correctionId: correction.id,
            amountRmb: double.parse(amountCtrl.text.trim()),
            reason: reasonCtrl.text.trim(),
            date: correction.date,
            confirmed: true,
          );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating correction: $e')),
      );
    }
  }

  Future<void> _deleteCorrection(Correction correction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete correction'),
        content: const Text('This action is permanent and will be logged. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(repositoryProvider).deleteCorrection(correctionId: correction.id, confirmed: true);
    await _refresh();
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo'),
        content: const Text('Delete this attachment metadata and file reference?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(repositoryProvider).deleteAttachment(attachmentId: attachment.id, confirmed: true);
    if (File(attachment.filePath).existsSync()) {
      File(attachment.filePath).deleteSync();
    }
    await _refresh();
  }

  Future<void> _deleteInvoice(Invoice currentInvoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invoice'),
        content: const Text('Invoice, corrections and related links will be removed. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(repositoryProvider).deleteInvoice(invoiceId: currentInvoice.id, confirmed: true);
    await _refresh();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider(widget.sessionId));
    final invoiceState = ref.watch(invoiceProvider(widget.invoice.id));
    final isClosed = sessionState.maybeWhen(
      data: (session) => session?.status == SessionStatus.closed,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceState.maybeWhen(data: (invoice) => invoice?.reference ?? widget.invoice.reference, orElse: () => widget.invoice.reference)),
        actions: [
          IconButton(
            onPressed: isClosed
                ? null
                : () async {
                    final invoice = await ref.read(invoiceProvider(widget.invoice.id).future);
                    if (invoice == null) return;
                    await _editInvoice(invoice);
                  },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: isClosed
                ? null
                : () async {
                    final invoice = await ref.read(invoiceProvider(widget.invoice.id).future);
                    if (invoice == null) return;
                    await _deleteInvoice(invoice);
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final attachmentsState =
              ref.watch(attachmentsProvider((elementId: widget.invoice.id, type: AttachmentType.invoice)));
          final correctionsState = ref.watch(correctionsProvider(widget.invoice.id));
          final attachments = attachmentsState.valueOrNull ?? const <Attachment>[];
          final corrections = correctionsState.valueOrNull ?? const <Correction>[];
              final corrTotal = corrections.fold<double>(0, (sum, c) => sum + c.amountRmb);
              final currentInvoice = invoiceState.maybeWhen(data: (invoice) => invoice ?? widget.invoice, orElse: () => widget.invoice);
              return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Initial Amount: ${fmtRmb(currentInvoice.amountInitialRmb)}'),
              Text('Corrections Total: ${fmtRmb(corrTotal)}'),
              Text('Final Amount: ${fmtRmb(currentInvoice.amountInitialRmb + corrTotal)}'),
              const SizedBox(height: 12),
              Text('Corrections (${corrections.length})', style: Theme.of(context).textTheme.titleMedium),
              ...corrections.map(
                (c) => ListTile(
                  title: Text(fmtRmb(c.amountRmb)),
                  subtitle: Text(c.reason),
                  trailing: PopupMenuButton<String>(
                    enabled: !isClosed,
                    onSelected: (value) async {
                      if (value == 'edit') await _editCorrection(c);
                      if (value == 'delete') await _deleteCorrection(c);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Attachments (${attachments.length})', style: Theme.of(context).textTheme.titleMedium),
                  if (attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('📷', style: TextStyle(fontSize: 18, color: Colors.blue[700])),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (attachments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No attachments yet', style: TextStyle(color: Colors.grey)),
                )
              else
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final a = attachments[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Photo'),
                                actions: [
                                  if (!isClosed)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _deleteAttachment(a);
                                      },
                                      tooltip: 'Delete photo',
                                    ),
                                ],
                              ),
                              body: InteractiveViewer(
                                child: Center(child: Image.file(File(a.filePath))),
                              ),
                            ),
                          ),
                        );
                      },
                      onLongPress: isClosed ? null : () => _deleteAttachment(a),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(a.filePath), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: isClosed
          ? null
          : FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('Add correction'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final invoice = await ref.read(invoiceProvider(widget.invoice.id).future);
                      if (invoice == null) return;
                      await _addCorrection(invoice);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Add photo from camera'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final attachment = await ref.read(attachmentServiceProvider).pickAndCompress(
                            type: AttachmentType.invoice,
                            elementId: widget.invoice.id,
                            source: ImageSource.camera,
                          );
                      if (attachment != null) {
                        await ref.read(repositoryProvider).saveAttachment(attachment);
                        await _refresh();
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Add photo from gallery'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final attachment = await ref.read(attachmentServiceProvider).pickAndCompress(
                            type: AttachmentType.invoice,
                            elementId: widget.invoice.id,
                            source: ImageSource.gallery,
                          );
                      if (attachment != null) {
                        await ref.read(repositoryProvider).saveAttachment(attachment);
                        await _refresh();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
