import 'package:repair_management_device_system/features/user/screens/user_home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const RepairApp());
}

class RepairApp extends StatelessWidget {
  const RepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบแจ้งซ่อมอุปกรณ์',
      debugShowCheckedModeBanner: false,
      home: const UserHomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5AA8),
        ),
      ),
      
    );
  }
}