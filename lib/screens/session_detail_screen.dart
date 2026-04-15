import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/summary_card.dart';
import 'audit_history_screen.dart';
import 'invoice_detail_screen.dart';
import 'payment_detail_screen.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({required this.session, super.key});

  final Session session;

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  Future<void> _refreshSessionViews() async {
    ref.invalidate(sessionProvider(widget.session.id));
    ref.invalidate(sessionSummaryProvider(widget.session.id));
    ref.invalidate(invoiceListItemsProvider(widget.session.id));
    ref.invalidate(paymentListItemsProvider(widget.session.id));
    ref.invalidate(sessionsProvider);
  }

  Future<void> _editSessionName(Session session) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: session.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Session Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Session name'),
            validator: FormValidators.validateSessionName,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).updateSessionName(
          sessionId: session.id,
          newName: ctrl.text.trim(),
          confirmed: true,
        );
    await _refreshSessionViews();
  }

  Future<void> _changeSessionState(Session session) async {
    if (session.status == SessionStatus.open) {
      final close = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Close Session'),
          content: const Text('Close this session? Add/edit/delete will be locked until protected reopen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close')),
          ],
        ),
      );
      if (close == true) {
        await ref.read(repositoryProvider).closeSession(session.id);
        await _refreshSessionViews();
      }
      return;
    }
    final reopen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Protected Reopen'),
        content: const Text('Reopen closed session? This action is logged as protected edit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reopen')),
        ],
      ),
    );
    if (reopen == true) {
      await ref.read(repositoryProvider).reopenSession(sessionId: session.id, confirmed: true);
      await _refreshSessionViews();
    }
  }

  Future<void> _addInvoice(Session session) async {
    final formKey = GlobalKey<FormState>();
    final refCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Invoice'),
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
    try {
      await ref.read(repositoryProvider).createInvoice(
            sessionId: widget.session.id,
            reference: refCtrl.text.trim(),
            supplier: supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
            amountInitialRmb: double.parse(amountCtrl.text.trim()),
          );
      await _refreshSessionViews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding invoice: $e')),
      );
    }
  }

  Future<void> _addPayment(Session session) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount MGA'),
                validator: (value) => FormValidators.validateAmount(value, fieldName: 'Amount MGA'),
              ),
              TextFormField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Exchange rate (MGA per RMB)'),
                validator: FormValidators.validateExchangeRate,
              ),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                validator: FormValidators.validateOptional,
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
      await ref.read(repositoryProvider).createPayment(
            sessionId: widget.session.id,
            date: DateTime.now(),
            amountMga: double.parse(amountCtrl.text.trim()),
            exchangeRate: double.parse(rateCtrl.text.trim()),
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
      await _refreshSessionViews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider(widget.session.id));
    final summary = ref.watch(sessionSummaryProvider(widget.session.id));
    final isClosed = sessionState.maybeWhen(
      data: (s) => s?.status == SessionStatus.closed,
      orElse: () => false,
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: sessionState.when(
                  data: (s) => Text(s?.name ?? widget.session.name),
                  loading: () => Text(widget.session.name),
                  error: (_, __) => Text(widget.session.name),
                ),
              ),
              if (isClosed)
                Chip(
                  label: const Text('CLOSED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: Colors.red.withOpacity(0.2),
                  side: const BorderSide(color: Colors.red),
                ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: !isClosed
                  ? () async {
                      final currentSession = await ref.read(sessionProvider(widget.session.id).future);
                      if (currentSession == null) return;
                      await _editSessionName(currentSession);
                    }
                  : null,
              icon: const Icon(Icons.edit),
              tooltip: isClosed ? 'Cannot edit closed session' : 'Edit session name',
            ),
            IconButton(
              onPressed: () async {
                final currentSession = await ref.read(sessionProvider(widget.session.id).future);
                if (currentSession == null) return;
                await _changeSessionState(currentSession);
              },
              icon: sessionState.maybeWhen(
                data: (s) => Icon(s?.status == SessionStatus.closed ? Icons.lock_open : Icons.lock),
                orElse: () => const Icon(Icons.lock),
              ),
              tooltip: isClosed ? 'Reopen session' : 'Close session',
            ),
            IconButton(
              onPressed: () async {
                final repo = ref.read(repositoryProvider);
                final invoices = await repo.invoicesBySession(widget.session.id);
                final payments = await repo.paymentsBySession(widget.session.id);
                final summaryData = await repo.computeSummary(widget.session.id);
                final corrMap = <String, List<Correction>>{};
                for (final i in invoices) {
                  corrMap[i.id] = await repo.correctionsByInvoice(i.id);
                }
                final bytes = await ref.read(pdfServiceProvider).buildSessionReport(
                      session: widget.session,
                      invoices: invoices,
                      correctionsByInvoiceId: corrMap,
                      payments: payments,
                      summary: summaryData,
                    );
                await ref.read(pdfServiceProvider).printBytes(bytes);
              },
              icon: const Icon(Icons.picture_as_pdf),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AuditHistoryScreen(sessionId: widget.session.id)));
              },
              icon: const Icon(Icons.history),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Invoices'), Tab(text: 'Payments')]),
        ),
        body: Column(
          children: [
            summary.when(
              data: (s) => GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SummaryCard(title: 'Total Invoices', value: fmtRmb(s.totalInvoices), color: Colors.blue),
                  SummaryCard(title: 'Total Payments', value: fmtRmb(s.totalPayments), color: Colors.green),
                  SummaryCard(title: 'Remaining', value: fmtRmb(s.remainingBalance), color: Colors.red),
                  SummaryCard(
                    title: 'Status',
                    value: sessionState.maybeWhen(
                      data: (session) => (session?.status.name ?? widget.session.status.name).toUpperCase(),
                      orElse: () => widget.session.status.name.toUpperCase(),
                    ),
                    color: Colors.indigo,
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => Text(e.toString()),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _InvoicesTab(
                    sessionId: widget.session.id,
                    isClosed: sessionState.maybeWhen(
                      data: (session) => session?.status == SessionStatus.closed,
                      orElse: () => false,
                    ),
                  ),
                  _PaymentsTab(
                    sessionId: widget.session.id,
                    isClosed: sessionState.maybeWhen(
                      data: (session) => session?.status == SessionStatus.closed,
                      orElse: () => false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: sessionState.maybeWhen(
          data: (session) {
            if (session == null || session.status == SessionStatus.closed) return null;
            return FloatingActionButton.extended(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Add Invoice'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _addInvoice(session);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.payments),
                          title: const Text('Add Payment'),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _addPayment(session);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            );
          },
          orElse: () => null,
        ),
      ),
    );
  }
}

class _InvoicesTab extends ConsumerWidget {
  const _InvoicesTab({required this.sessionId, required this.isClosed});
  final String sessionId;
  final bool isClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceListItemsProvider(sessionId));
    return state.when(
      data: (invoices) => ListView.builder(
        itemCount: invoices.length,
        itemBuilder: (context, i) {
          final row = invoices[i];
          return ListTile(
            title: Text(row.invoice.reference),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('Initial ${fmtRmb(row.invoice.amountInitialRmb)} | Corr ${fmtRmb(row.correctionsTotal)}'),
                Text('Final ${fmtRmb(row.finalRmb)} | Photos ${row.attachmentCount}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'open') {
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: row.invoice, sessionId: sessionId)),
                  );
                  return;
                }
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete invoice'),
                      content: const Text('Delete this invoice from session list?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  await ref.read(repositoryProvider).deleteInvoice(invoiceId: row.invoice.id, confirmed: true);
                  ref.invalidate(invoiceListItemsProvider(sessionId));
                  ref.invalidate(sessionSummaryProvider(sessionId));
                  ref.invalidate(sessionProvider(sessionId));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: Text('Open / Edit')),
                if (!isClosed) const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: row.invoice, sessionId: sessionId)),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(e.toString())),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.sessionId, required this.isClosed});
  final String sessionId;
  final bool isClosed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentListItemsProvider(sessionId));
    return state.when(
      data: (payments) => ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, i) {
          final row = payments[i];
          final p = row.payment;
          return ListTile(
            title: Text('${fmtDate(p.date)} | ${fmtMga(p.amountMga)} @ ${p.exchangeRate.toStringAsFixed(2)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text('RMB ${p.amountRmbComputed.toStringAsFixed(2)}'),
                Text('Photos ${row.attachmentCount}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'open') {
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentDetailScreen(payment: p, sessionId: sessionId)),
                  );
                  return;
                }
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete payment'),
                      content: const Text('Delete this payment from session list?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  await ref.read(repositoryProvider).deletePayment(paymentId: p.id, confirmed: true);
                  ref.invalidate(paymentListItemsProvider(sessionId));
                  ref.invalidate(sessionSummaryProvider(sessionId));
                  ref.invalidate(sessionProvider(sessionId));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: Text('Open / Edit')),
                if (!isClosed) const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentDetailScreen(payment: p, sessionId: sessionId)),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text(e.toString())),
    );
  }
}
