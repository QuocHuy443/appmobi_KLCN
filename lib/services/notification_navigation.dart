import 'package:flutter/material.dart';
import '../screens/appointment_screen.dart';
import '../screens/billing_screen.dart';
import '../screens/medical_records_screen.dart';
import '../screens/test_results_screen.dart';
import '../screens/personal_profile_screen.dart';
import '../screens/feedback_screen.dart';

Future<void> openNotificationTarget(BuildContext context, dynamic value) async {
  if (value is! String) return;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return;
  final Widget? screen = switch (uri.path) {
    '/patient/appointments' => const AppointmentScreen(initialTab: 1),
    '/patient/booking' => const AppointmentScreen(),
    '/patient/records' || '/patient/prescriptions' => const MedicalRecordsScreen(),
    '/patient/lab-results' => const TestResultsScreen(),
    '/patient/billing' || '/patient/invoices' => const BillingScreen(),
    '/patient/profile' => const PersonalProfileScreen(),
    '/patient/feedbacks' => const FeedbackScreen(),
    _ => null,
  };
  if (screen != null && context.mounted) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
