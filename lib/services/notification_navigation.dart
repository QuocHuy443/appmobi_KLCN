import 'package:flutter/material.dart';
import '../screens/appointment_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/medical_records_screen.dart';
import '../screens/test_results_screen.dart';
import '../screens/personal_profile_screen.dart';
import '../screens/feedback_screen.dart';

Future<void> openNotificationTarget(
  BuildContext context,
  dynamic value, {
  dynamic category,
}) async {
  if (value is! String || value.trim().isEmpty) return;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.hasScheme || uri.hasAuthority) return;
  final cat = (category ?? '').toString().toLowerCase();
  final Widget? screen = switch (uri.path) {
    '/patient/appointments' => const AppointmentScreen(initialTab: 1),
    '/patient/booking' || '/booking' => const AppointmentScreen(),
    '/patient/records' || '/patient/prescriptions' => const MedicalRecordsScreen(),
    '/patient/lab-results' => const TestResultsScreen(),
    '/patient/billing' || '/patient/invoices' => const BillingScreen(),
    '/patient/profile' => const PersonalProfileScreen(),
    '/patient/feedbacks' => const FeedbackScreen(),
    '/patient/dashboard' || '/patient' || '/patient/' =>
      (cat.contains('xét nghiệm') || cat.contains('cận lâm sàng') || cat.contains('kết quả'))
          ? const TestResultsScreen()
          : null,
    _ => null,
  };
  if (screen != null && context.mounted) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  } else if ((uri.path == '/patient/dashboard' || uri.path == '/patient' || uri.path == '/patient/') &&
      context.mounted &&
      Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}
