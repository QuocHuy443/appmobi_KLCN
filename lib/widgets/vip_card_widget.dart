import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/app_colors.dart';
import 'qr_modal_widget.dart';

class VipCardWidget extends StatelessWidget {
  const VipCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.slate900, AppColors.slate800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MEDCARE+ VIP CARD', style: TextStyle(color: AppColors.medical500, fontWeight: FontWeight.bold, fontSize: 12)),
              FaIcon(FontAwesomeIcons.nfcSymbol, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Họ và tên', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
          const Text('NGUYỄN VĂN AN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã số BN', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                  Text('BN-00291-2026', style: TextStyle(color: AppColors.medical100, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (context) => const QrModalWidget(patientCode: 'BN-00291-2026'),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.slate900, size: 28),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}