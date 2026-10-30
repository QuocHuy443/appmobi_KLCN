import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';

class VipCardWidget extends StatelessWidget {
  final String? bhyt;
  final String? nhomMau;

  const VipCardWidget({
    super.key,
    this.bhyt,
    this.nhomMau,
  });

  void _showQrModal(BuildContext context, String patientCode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mã QR Check-in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate800,
              ),
            ),
            const SizedBox(height: 24),
            QrImageView(data: patientCode, version: QrVersions.auto, size: 200.0),
            const SizedBox(height: 16),
            Text(
              patientCode,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.medical600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate100,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final fullName = (user != null && user.name.isNotEmpty)
        ? user.name.toUpperCase()
        : 'CHƯA ĐĂNG NHẬP';
    final patientCode = (user != null && user.patientCode.isNotEmpty)
        ? user.patientCode
        : 'CHƯA CÓ MÃ BN';
    final hasBhyt = bhyt != null && bhyt!.trim().isNotEmpty;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'H2T HEALTHCARE VIP CARD',
                style: TextStyle(
                  color: AppColors.medical500,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  if (hasBhyt)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.medical600.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BHYT 80%',
                        style: TextStyle(
                          color: AppColors.medical100,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const FaIcon(FontAwesomeIcons.nfcSymbol, color: Colors.white54, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Họ và tên bệnh nhân', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mã số BN', style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                  Text(
                    patientCode,
                    style: const TextStyle(color: AppColors.medical100, fontWeight: FontWeight.bold),
                  ),
                  if (nhomMau != null && nhomMau!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Nhóm máu: $nhomMau',
                      style: const TextStyle(color: AppColors.slate300, fontSize: 11),
                    ),
                  ],
                ],
              ),
              if (user != null)
                GestureDetector(
                  onTap: () => _showQrModal(context, patientCode),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
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
