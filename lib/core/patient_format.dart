import 'package:intl/intl.dart';

String patientMoney(dynamic value) => NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
    .format(value is num ? value : num.tryParse('$value') ?? 0);

String patientDate(dynamic value) {
  final text = value?.toString() ?? '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return DateFormat(text.length > 10 ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy').format(parsed);
}
