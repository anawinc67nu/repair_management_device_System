import 'package:flutter/material.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int selectedTab = 0;

  String? selectedEquipment;
  final detailController = TextEditingController();
  final locationController = TextEditingController();

  final List<Map<String, String>> repairHistory = [];

  final List<String> equipmentList = [
    'คอมพิวเตอร์',
    'เมาส์',
    'คีย์บอร์ด',
    'จอภาพ',
    'เครื่องพิมพ์',
    'อุปกรณ์เครือข่าย',
    'อื่น ๆ',
  ];

  final Color primaryColor = const Color(0xFF1E5AA8);

  @override
  void dispose() {
    detailController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void submitRepair() {
    if (selectedEquipment == null ||
        detailController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }

    setState(() {
      repairHistory.insert(0, {
        'equipment': selectedEquipment!,
        'detail': detailController.text.trim(),
        'location': locationController.text.trim(),
        'status': 'รอดำเนินการ',
      });

      selectedTab = 2;
      selectedEquipment = null;
      detailController.clear();
      locationController.clear();
    });

    showMessage('บันทึกคำขอแจ้งซ่อมตัวอย่างแล้ว');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [buildHome(), buildRepairForm(), buildHistory()];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'ระบบแจ้งซ่อมอุปกรณ์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showMessage('ส่วนโปรไฟล์จะพัฒนาต่อภายหลัง');
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(child: pages[selectedTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'แจ้งซ่อม',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'ประวัติ'),
        ],
      ),
    );
  }

  Widget buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'พบปัญหาอุปกรณ์ แจ้งซ่อมได้ที่นี่',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // QR Code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 64, color: primaryColor),
                  const SizedBox(height: 12),
                  const Text(
                    'สแกน QR Code อุปกรณ์',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สแกนเพื่อระบุอุปกรณ์ที่ต้องการแจ้งซ่อม',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        showMessage(
                          'ส่วนสแกน QR Code จะเชื่อมกล้องในขั้นตอนถัดไป',
                        );
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('เริ่มสแกน QR Code'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Repair form shortcut
          Card(
            child: ListTile(
              leading: Icon(
                Icons.add_circle_outline,
                color: primaryColor,
                size: 36,
              ),
              title: const Text(
                'แจ้งซ่อมอุปกรณ์',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('เลือกอุปกรณ์และอธิบายปัญหา'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  selectedTab = 1;
                });
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'สรุปการแจ้งซ่อมของฉัน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: buildSummaryCard(
                  'ทั้งหมด',
                  repairHistory.length.toString(),
                  Icons.assignment_outlined,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildSummaryCard(
                  'รอดำเนินการ',
                  repairHistory
                      .where((r) => r['status'] == 'รอดำเนินการ')
                      .length
                      .toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'รายการล่าสุด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (repairHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('ยังไม่มีประวัติการแจ้งซ่อม')),
              ),
            )
          else
            ...repairHistory.take(3).map(buildRepairCard),
        ],
      ),
    );
  }

  Widget buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget buildRepairForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แจ้งซ่อมอุปกรณ์',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('กรอกข้อมูลอุปกรณ์และอาการเสีย'),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () {
              showMessage('ส่วนสแกน QR Code จะเชื่อมกล้องในขั้นตอนถัดไป');
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('สแกน QR Code อุปกรณ์'),
          ),

          const SizedBox(height: 20),
          const Text(
            'อุปกรณ์ที่ต้องการแจ้งซ่อม *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: selectedEquipment,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'เลือกอุปกรณ์',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: equipmentList.map((equipment) {
              return DropdownMenuItem(value: equipment, child: Text(equipment));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedEquipment = value;
              });
            },
          ),

          const SizedBox(height: 20),
          const Text(
            'สถานที่ตั้งอุปกรณ์ *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              hintText: 'เช่น อาคาร 1 ห้องปฏิบัติการ 301',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'รายละเอียดอาการเสีย *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: detailController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'อธิบายปัญหาที่พบ...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: submitRepair,
              icon: const Icon(Icons.send),
              label: const Text('ส่งคำขอแจ้งซ่อม'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'ประวัติการแจ้งซ่อมของฉัน',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (repairHistory.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('ยังไม่มีประวัติการแจ้งซ่อม')),
            ),
          )
        else
          ...repairHistory.map(buildRepairCard),
      ],
    );
  }

  Widget buildRepairCard(Map<String, String> repair) {
    final status = repair['status'] ?? 'รอดำเนินการ';

    final statusColor = status == 'ซ่อมเสร็จแล้ว'
        ? Colors.green
        : status == 'กำลังซ่อม'
        ? Colors.blue
        : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_outlined, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    repair['equipment'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('สถานที่: ${repair['location']}'),
            const SizedBox(height: 6),
            Text('รายละเอียด: ${repair['detail']}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(status),
                backgroundColor: statusColor.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
