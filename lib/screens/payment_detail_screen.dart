import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../utils/strings.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final Payment payment;
  final String sessionId;

  const PaymentDetailScreen({
    super.key,
    required this.payment,
    required this.sessionId,
  });

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState
    extends ConsumerState<PaymentDetailScreen> {
  Future<void> _refresh() async {
    ref.invalidate(paymentProvider(widget.payment.id));
    ref.invalidate(sessionProvider(widget.sessionId));
  }

  Future<void> _editPayment(Payment currentPayment) async {
    final formKey = GlobalKey<FormState>();

    final amountCtrl = TextEditingController(
      text: currentPayment.amountMga.toString(),
    );

    final rateCtrl = TextEditingController(
      text: currentPayment.exchangeRate.toString(),
    );

    final noteCtrl = TextEditingController(
      text: currentPayment.note ?? '',
    );

    var selectedDate = currentPayment.date;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.editPayment),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                      labelText: AppStrings.amountMga),
                  validator: (v) =>
                      FormValidators.validateAmount(v),
                ),
                TextFormField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                      labelText: AppStrings.exchangeRate),
                  validator:
                      FormValidators.validateExchangeRate,
                ),
                TextFormField(
                  controller: noteCtrl,
                  decoration:
                      InputDecoration(labelText: AppStrings.note),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: Text(
                      '${AppStrings.date}: ${fmtDate(selectedDate)}'),
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(AppStrings.save),
          )
        ],
      ),
    );

    if (ok != true) return;

   await ref.read(repositoryProvider).updatePayment(
  paymentId: currentPayment.id,
  date: selectedDate,
  amountMga: double.parse(amountCtrl.text),
  exchangeRate: double.parse(rateCtrl.text),
  note: noteCtrl.text,
  confirmed: true,
);

    await _refresh();
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.delete),
        content: Text(AppStrings.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(repositoryProvider).deletePayment(
  paymentId: payment.id,
  confirmed: true,
);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync =
        ref.watch(paymentProvider(widget.payment.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.paymentDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final payment = await ref.read(
                  paymentProvider(widget.payment.id).future);
              if (payment != null) {
                await _editPayment(payment);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final payment = await ref.read(
                  paymentProvider(widget.payment.id).future);
              if (payment != null) {
                await _deletePayment(payment);
              }
            },
          )
        ],
      ),
      body: paymentAsync.when(
        data: (payment) {
          if (payment == null) {
            return const Center(child: Text('No data'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppStrings.date}: ${fmtDate(payment.date)}'),
                Text('${AppStrings.amountMga}: ${payment.amountMga}'),
                Text('${AppStrings.exchangeRate}: ${payment.exchangeRate}'),
                Text('${AppStrings.rmb}: ${payment.amountRmbComputed}'),
                Text('${AppStrings.note}: ${payment.note ?? ''}'),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}
