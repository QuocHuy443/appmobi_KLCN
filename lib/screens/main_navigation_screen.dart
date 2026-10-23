import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import 'home/home_screen.dart';
import 'appointment/appointment_screen.dart';
import 'medical_records/medical_records_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final pages = [
      const HomeScreen(),
      const AppointmentScreen(),
      const MedicalRecordsScreen(),
      ProfileScreen(user: authViewModel.currentUser),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.medical600,
        unselectedItemColor: AppColors.slate400,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house, size: 20),
              label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.calendarPlus, size: 20),
              label: 'Đặt lịch'),
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.fileMedical, size: 20),
              label: 'Hồ sơ'),
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.userGear, size: 20),
              label: 'Tài khoản'),
        ],
      ),
    );
  }
}
