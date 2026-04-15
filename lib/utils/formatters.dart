import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.00');
final _date = DateFormat('yyyy-MM-dd');

String fmtRmb(double value) => 'RMB ${_money.format(value)}';
String fmtMga(double value) => 'MGA ${_money.format(value)}';
String fmtDate(DateTime value) => _date.format(value);
