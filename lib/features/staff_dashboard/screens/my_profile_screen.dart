import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  static const Color navy = Color(0xFF172554);
  static const Color background = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('ข้อมูลส่วนตัว'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 600;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 38 : 48,
                        backgroundColor: const Color(0xFFE0E7FF),
                        child: Icon(
                          Icons.person,
                          size: isMobile ? 44 : 54,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Staff User',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 21 : 24,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'เจ้าหน้าที่',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      _profileItem(Icons.badge_outlined, 'รหัสผู้ใช้', 'ST001'),
                      _profileItem(
                        Icons.person_outline,
                        'ชื่อ-นามสกุล',
                        'Staff User',
                      ),
                      _profileItem(
                        Icons.email_outlined,
                        'อีเมล',
                        'staff@example.com',
                      ),
                      _profileItem(Icons.work_outline, 'บทบาท', 'เจ้าหน้าที่'),
                      _profileItem(
                        Icons.check_circle_outline,
                        'สถานะบัญชี',
                        'ใช้งาน',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ข้อมูลนี้เป็นข้อมูลตัวอย่าง',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: navy, size: 24),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
