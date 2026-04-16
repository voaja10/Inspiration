import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../utils/formatters.dart';
import '../utils/strings.dart';
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
        title: Text(AppStrings.editSessionName),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(labelText: AppStrings.sessionName),
            validator: FormValidators.validateSessionName,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: Text(AppStrings.save),
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
          title: Text(AppStrings.closeSession),
          content: Text(AppStrings.closeSessionConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.closeSession)),
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
        title: Text(AppStrings.protectedReopen),
        content: Text(AppStrings.reopenSessionConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.reopen)),
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
        title: Text(AppStrings.addInvoice),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: refCtrl,
                decoration: InputDecoration(labelText: AppStrings.reference),
                validator: FormValidators.validateInvoiceReference,
              ),
              TextFormField(
                controller: supplierCtrl,
                decoration: InputDecoration(labelText: '${AppStrings.supplier} (${AppStrings.optional})'),
                validator: FormValidators.validateOptional,
              ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: AppStrings.initialRmb),
                validator: (value) => FormValidators.validateAmount(value, fieldName: AppStrings.initialRmb),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: Text(AppStrings.save),
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
        SnackBar(content: Text('${AppStrings.error}: $e')),
      );
    }
  }

  Future<void> _addPayment(Session session) async {
    final formKey = GlobalKey<FormState>();
    final amountMgaCtrl = TextEditingController();
    final amountRmbCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var calculatedRate = 0.0;
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppStrings.addPayment),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountMgaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppStrings.amountMga),
                  validator: (value) => FormValidators.validateAmount(value, fieldName: AppStrings.amountMga),
                  onChanged: (v) {
                    setState(() {
                      final mga = double.tryParse(v) ?? 0;
                      final rmb = double.tryParse(amountRmbCtrl.text) ?? 0;
                      if (mga > 0 && rmb > 0) {
                        calculatedRate = mga / rmb;
                      }
                    });
                  },
                ),
                TextFormField(
                  controller: amountRmbCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppStrings.amountRmb),
                  validator: (value) => FormValidators.validateAmount(value, fieldName: AppStrings.amountRmb),
                  onChanged: (v) {
                    setState(() {
                      final mga = double.tryParse(amountMgaCtrl.text) ?? 0;
                      final rmb = double.tryParse(v) ?? 0;
                      if (mga > 0 && rmb > 0) {
                        calculatedRate = mga / rmb;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.exchangeRate),
                      Text('${calculatedRate.toStringAsFixed(4)} (${AppStrings.exchangeRateAuto})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: '${AppStrings.note} (${AppStrings.optional})'),
                  validator: FormValidators.validateOptional,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(ctx, true);
              },
              child: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final mga = double.parse(amountMgaCtrl.text.trim());
      final rmb = double.parse(amountRmbCtrl.text.trim());
      
      await ref.read(repositoryProvider).createPayment(
            sessionId: widget.session.id,
            date: DateTime.now(),
            amountMga: mga,
            amountRmbComputed: rmb,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
      await _refreshSessionViews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.error}: $e')),
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
                  label: Text(AppStrings.closedBadge, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
              tooltip: isClosed ? AppStrings.cannotEditClosedSession : AppStrings.editSessionTooltip,
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
              tooltip: isClosed ? AppStrings.reopenSessionTooltip : AppStrings.closeSessionTooltip,
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
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.invoices),
              Tab(text: AppStrings.payments),
            ],
          )
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
                  SummaryCard(title: AppStrings.totalInvoices, value: fmtRmb(s.totalInvoices), color: Colors.blue),
                  SummaryCard(title: AppStrings.totalPayments, value: fmtRmb(s.totalPayments), color: Colors.green),
                  SummaryCard(title: AppStrings.remainingBalance, value: fmtRmb(s.remainingBalance), color: Colors.red),
                  SummaryCard(
                    title: AppStrings.status,
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
                          title: Text(AppStrings.addInvoice),
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _addInvoice(session);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.payments),
                          title: Text(AppStrings.addPayment),
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
              label: Text(AppStrings.add),
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
                      title: Text(AppStrings.deleteInvoice),
                      content: Text(AppStrings.deleteInvoiceConfirmMsg),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.delete)),
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
                PopupMenuItem(value: 'open', child: Text(AppStrings.openEdit)),
                if (!isClosed) PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
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
                      title: Text(AppStrings.deletePayment),
                      content: Text(AppStrings.deletePaymentConfirmMsg),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.delete)),
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
                PopupMenuItem(value: 'open', child: Text(AppStrings.openEdit)),
                if (!isClosed) PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
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
