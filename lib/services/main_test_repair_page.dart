import 'package:flutter/material.dart';
import 'api_service.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TestRepairScreen(),
  ));
}

class TestRepairScreen extends StatefulWidget {
  const TestRepairScreen({super.key});

  @override
  State<TestRepairScreen> createState() => _TestRepairScreenState();
}

class _TestRepairScreenState extends State<TestRepairScreen> {
  String statusMessage = 'กดปุ่มเพื่อทดสอบระบบ';
  Map<String, dynamic>? scannedDevice;
  bool isLoading = false;

  // 1. ทดสอบสแกนคอมพิวเตอร์เครื่องที่ 1 ในห้อง SC2-307
  Future<void> testScan() async {
    setState(() {
      isLoading = true;
      statusMessage = 'กำลังดึงข้อมูลอุปกรณ์จากเซิร์ฟเวอร์...';
    });

    final data = await ApiService.scanEquipment('PC-SC2-307-01');
    setState(() {
      isLoading = false;
      if (data != null) {
        scannedDevice = data;
        statusMessage = '✅ พบข้อมูล: ${data['device_name']}\nห้อง: ${data['building_name']} ชั้น ${data['floor']} ห้อง ${data['room_number']}';
      } else {
        statusMessage = '❌ ไม่พบข้อมูลอุปกรณ์ หรือเชื่อมต่อ Server ไม่ได้';
      }
    });
  }

  // 2. ทดสอบแจ้งซ่อมอุปกรณ์ + เด้ง LINE หาช่าง (R1)
  Future<void> testCreateTicket() async {
    if (scannedDevice == null) {
      setState(() => statusMessage = 'กรุณากดค้นหา/สแกนอุปกรณ์ก่อน');
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = 'กำลังส่งรายการแจ้งซ่อมและยิงแจ้งเตือน LINE...';
    });

    final success = await ApiService.createTicket(
      scannedDevice!['device_id'],
      'จอภาพดับ เปิดเครื่องไม่ติด (ทดสอบส่งจากแอป Flutter)',
    );

    setState(() {
      isLoading = false;
      if (success) {
        statusMessage = '🎉 ส่งแจ้งซ่อมสำเร็จ! ตรวจสอบข้อความแจ้งเตือนในแอป LINE ได้เลย';
      } else {
        statusMessage = '❌ ส่งข้อมูลไม่สำเร็จ';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบระบบแจ้งซ่อม (SC2-307)'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: isLoading ? null : testScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('1. ทดสอบสแกน PC-SC2-307-01'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: isLoading ? null : testCreateTicket,
              icon: const Icon(Icons.send),
              label: const Text('2. ทดสอบส่งแจ้งซ่อม (ยิงเข้า LINE)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 30),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Text(
                statusMessage,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}