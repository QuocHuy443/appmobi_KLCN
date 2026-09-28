import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';

class QrModalWidget extends StatelessWidget {
  final String patientCode;
  const QrModalWidget({super.key, required this.patientCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Mã QR Check-in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800)),
          const SizedBox(height: 24),
          QrImageView(data: patientCode, version: QrVersions.auto, size: 200.0),
          const SizedBox(height: 16),
          Text(patientCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.medical600)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.slate100, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Đóng', style: TextStyle(color: AppColors.slate700, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}