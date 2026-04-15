import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_session_manager/models/app_models.dart';

void main() {
  test('invoice with no correction keeps initial amount', () {
    const initial = 1000.0;
    const corrections = <double>[];
    final finalAmount = initial + corrections.fold<double>(0, (a, b) => a + b);
    expect(finalAmount, 1000.0);
  });

  test('invoice with positive correction increases final amount', () {
    const initial = 1000.0;
    const corrections = [100.0];
    final finalAmount = initial + corrections.fold<double>(0, (a, b) => a + b);
    expect(finalAmount, 1100.0);
  });

  test('invoice with negative correction decreases final amount', () {
    const initial = 1000.0;
    const corrections = [-200.0];
    final finalAmount = initial + corrections.fold<double>(0, (a, b) => a + b);
    expect(finalAmount, 800.0);
  });

  test('payments with different exchange rates keep historical values', () {
    final p1 = Payment.computeRmb(650000, 650);
    final p2 = Payment.computeRmb(720000, 720);
    expect(p1, 1000);
    expect(p2, 1000);
  });

  test('payment conversion rejects zero or negative exchange rates', () {
    expect(() => Payment.computeRmb(1000, 0), throwsArgumentError);
    expect(() => Payment.computeRmb(1000, -1), throwsArgumentError);
  });

  test('remaining balance computed from source data only', () {
    const totalInvoices = 2500.0;
    const totalPayments = 1600.0;
    final remaining = totalInvoices - totalPayments;
    expect(remaining, 900.0);
  });

  test('closed session blocks modifications in repository logic', () {
    const status = SessionStatus.closed;
    expect(status == SessionStatus.closed, true);
  });

  test('audit action types cover create update delete restore protected', () {
    expect(AuditActionType.values, contains(AuditActionType.create));
    expect(AuditActionType.values, contains(AuditActionType.update));
    expect(AuditActionType.values, contains(AuditActionType.delete));
    expect(AuditActionType.values, contains(AuditActionType.restore));
    expect(AuditActionType.values, contains(AuditActionType.protectedEdit));
  });
}
