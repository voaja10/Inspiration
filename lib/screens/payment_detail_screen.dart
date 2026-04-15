import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  const PaymentDetailScreen({
    required this.payment,
    required this.sessionId,
    super.key,
  });

  final Payment payment;
  final String sessionId;

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  Future<void> _refresh() async {
    ref.invalidate(paymentProvider(widget.payment.id));
    ref.invalidate(sessionProvider(widget.sessionId));
    ref.invalidate(paymentListItemsProvider(widget.sessionId));
    ref.invalidate(sessionSummaryProvider(widget.sessionId));
    ref.invalidate(
      attachmentsProvider(
        (elementId: widget.payment.id, type: AttachmentType.payment),
      ),
    );
  }

  Future<void> _editPayment(Payment currentPayment) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(
      text: currentPayment.amountMga.toStringAsFixed(2),
    );
    final rateCtrl = TextEditingController(
      text: currentPayment.exchangeRate.toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController(text: currentPayment.note ?? '');
    var selectedDate = currentPayment.date;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Edit Payment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Amount MGA'),
                    validator: (value) => FormValidators.validateAmount(
                      value,
                      fieldName: 'Amount MGA',
                    ),
                  ),
                  TextFormField(
                    controller: rateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Exchange rate'),
                    validator: FormValidators.validateExchangeRate,
                  ),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    title: Text('Date: ${fmtDate(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm update'),
        content: const Text('Apply payment changes and log old/new values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(repositoryProvider).updatePayment(
            paymentId: currentPayment.id,
            date: selectedDate,
            amountMga: double.parse(amountCtrl.text.trim()),
            exchangeRate: double.parse(rateCtrl.text.trim()),
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            confirmed: true,
          );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating payment: $e')));
    }
  }

  Future<void> _deletePayment(Payment currentPayment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment'),
        content: const Text(
          'Delete this payment? This action is audited and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref
        .read(repositoryProvider)
        .deletePayment(paymentId: currentPayment.id, confirmed: true);
    await _refresh();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo'),
        content: const Text(
          'Delete this attachment metadata and file reference?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref
        .read(repositoryProvider)
        .deleteAttachment(attachmentId: attachment.id, confirmed: true);

    if (File(attachment.filePath).existsSync()) {
      File(attachment.filePath).deleteSync();
    }

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider(widget.payment.id));
    final sessionState = ref.watch(sessionProvider(widget.sessionId));

    final isClosed = sessionState.maybeWhen(
      data: (session) => session?.status == SessionStatus.closed,
      orElse: () => false,
    );

    final currentPayment = paymentState.maybeWhen(
      data: (payment) => payment ?? widget.payment,
      orElse: () => widget.payment,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Detail'),
        actions: [
          IconButton(
            onPressed: isClosed
                ? null
                : () async {
                    final payment = await ref.read(
                      paymentProvider(widget.payment.id).future,
                    );
                    if (payment == null) return;
                    await _editPayment(payment);
                  },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: isClosed
                ? null
                : () async {
                    final payment = await ref.read(
                      paymentProvider(widget.payment.id).future,
                    );
                    if (payment == null) return;
                    await _deletePayment(payment);
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final attachmentsState = ref.watch(
            attachmentsProvider(
              (elementId: currentPayment.id, type: AttachmentType.payment),
            ),
          );
          final attachments = attachmentsState.valueOrNull ?? const <Attachment>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Date: ${fmtDate(currentPayment.date)}'),
              Text('Amount MGA: ${fmtMga(currentPayment.amountMga)}'),
              Text('Rate: ${currentPayment.exchangeRate.toStringAsFixed(2)}'),
              Text('Computed RMB: ${fmtRmb(currentPayment.amountRmbComputed)}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Attachments (${attachments.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '📄',
                        style: TextStyle(fontSize: 18, color: Colors.green[700]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (attachments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No receipts attached yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
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
                                title: const Text('Receipt'),
                                actions: [
                                  if (!isClosed)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _deleteAttachment(a);
                                      },
                                      tooltip: 'Delete receipt',
                                    ),
                                ],
                              ),
                              body: InteractiveViewer(
                                child: Center(
                                  child: Image.file(File(a.filePath)),
                                ),
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
                          child: Image.file(
                            File(a.filePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
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
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Add photo from camera'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final attachment = await ref
                                .read(attachmentServiceProvider)
                                .pickAndCompress(
                                  type: AttachmentType.payment,
                                  elementId: currentPayment.id,
                                  source: ImageSource.camera,
                                );
                            if (attachment != null) {
                              await ref
                                  .read(repositoryProvider)
                                  .saveAttachment(attachment);
                              await _refresh();
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Add photo from gallery'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final attachment = await ref
                                .read(attachmentServiceProvider)
                                .pickAndCompress(
                                  type: AttachmentType.payment,
                                  elementId: currentPayment.id,
                                  source: ImageSource.gallery,
                                );
                            if (attachment != null) {
                              await ref
                                  .read(repositoryProvider)
                                  .saveAttachment(attachment);
                              await _refresh();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add_photo_alternate),
            ),
    );
  }
}
