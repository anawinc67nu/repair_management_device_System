import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int selectedTab = 0;

  String? selectedEquipment;
  final deviceIdController = TextEditingController();
  final detailController = TextEditingController();
  final locationController = TextEditingController();

  // กำหนด userId ของผู้ใช้งาน (สามารถปรับเปลี่ยนตามระบบ Auth/Session จริงได้)
  final int currentUserId = 1;

  List<Map<String, dynamic>> repairHistory = [];
  bool isLoading = false;
  bool isSubmitting = false;

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
  void initState() {
    super.initState();
    fetchRepairHistory();
  }

  @override
  void dispose() {
    deviceIdController.dispose();
    detailController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ดึงประวัติการแจ้งซ่อมของผู้ใช้จาก ApiService.getUserTickets
  Future<void> fetchRepairHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final tickets = await ApiService.getUserTickets(currentUserId);
      if (tickets != null) {
        setState(() {
          repairHistory = List<Map<String, dynamic>>.from(tickets);
        });
      }
    } catch (e) {
      showMessage('ไม่สามารถดึงข้อมูลได้: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
    final tickets = await ApiService.getUserTickets(currentUserId);
    print('Response from API: $tickets');
  }

  // ส่งฟอร์มแจ้งซ่อมด้วย ApiService.createTicket
  // ส่งฟอร์มแจ้งซ่อมด้วย ApiService.createTicket
  Future<void> submitRepair() async {
    final inputDeviceId = deviceIdController.text.trim();

    if (inputDeviceId.isEmpty ||
        selectedEquipment == null ||
        detailController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }

    final int parsedDeviceId = int.tryParse(inputDeviceId) ?? 1;

    setState(() {
      isSubmitting = true;
    });

    final fullDescription =
        '[รหัสเครื่อง: $inputDeviceId] [ประเภท: $selectedEquipment] [สถานที่: ${locationController.text.trim()}] ${detailController.text.trim()}';

    try {
      final success = await ApiService.createTicket(
        deviceId: parsedDeviceId,
        description: fullDescription,
        reporterId: currentUserId,
      );

      if (success) {
        // 1. เคลียร์ค่าฟอร์มก่อน
        deviceIdController.clear();
        detailController.clear();
        locationController.clear();

        setState(() {
          selectedEquipment = null;
          selectedTab = 2; // 2. สลับไปหน้าประวัติทันที
        });

        showMessage('ส่งคำขอแจ้งซ่อมสำเร็จ');

        // 3. ดึงข้อมูลใหม่เพื่ออัปเดตประวัติและจำนวนทั้งหมด
        await fetchRepairHistory();
      } else {
        showMessage('เกิดข้อผิดพลาด ไม่สามารถบันทึกข้อมูลได้');
      }
    } catch (e) {
      showMessage('เกิดข้อผิดพลาดในการส่งข้อมูล: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // แปลงค่า Status จาก API (เช่น 'pending', 'in_progress', 'completed') เป็นภาษาไทย
  String translateStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'รอดำเนินการ':
        return 'รอดำเนินการ';
      case 'in_progress':
      case 'กำลังซ่อม':
        return 'กำลังซ่อม';
      case 'completed':
      case 'ซ่อมเสร็จแล้ว':
        return 'ซ่อมเสร็จแล้ว';
      default:
        return status ?? 'รอดำเนินการ';
    }
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
            onPressed: fetchRepairHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
          ),
          IconButton(
            onPressed: () {
              showMessage('ส่วนโปรไฟล์จะพัฒนาต่อภายหลัง');
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchRepairHistory,
                child: pages[selectedTab],
              ),
      ),
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

  // -------------------------------------------------------------
  // Tab 1: หน้าหลัก (Home)
  // -------------------------------------------------------------
  Widget buildHome() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'พบปัญหาอุปกรณ์ แจ้งซ่อมได้ที่นี่',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // การ์ดสแกน QR Code
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

          // ทางลัดไปยังฟอร์มแจ้งซ่อม
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
                      .where(
                        (r) => translateStatus(r['status']) == 'รอดำเนินการ',
                      )
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

  // -------------------------------------------------------------
  // Tab 2: ฟอร์มแจ้งซ่อม (Repair Form)
  // -------------------------------------------------------------
  Widget buildRepairForm() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
            'ประเภทอุปกรณ์ *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: selectedEquipment,
            isExpanded: true,
            decoration: const InputDecoration(
              hintText: 'เลือกประเภทอุปกรณ์',
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
            'รหัสเครื่อง / Device ID *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: deviceIdController,
            decoration: const InputDecoration(
              hintText: 'เช่น 101 หรือ PC-SC2-307-01',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
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
              onPressed: isSubmitting ? null : submitRepair,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                isSubmitting ? 'กำลังส่งข้อมูล...' : 'ส่งคำขอแจ้งซ่อม',
              ),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Tab 3: ประวัติการแจ้งซ่อม (History)
  // -------------------------------------------------------------
  Widget buildHistory() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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

  Widget buildRepairCard(Map<String, dynamic> repair) {
    final rawStatus = repair['status']?.toString();
    final displayStatus = translateStatus(rawStatus);

    final statusColor = displayStatus == 'ซ่อมเสร็จแล้ว'
        ? Colors.green
        : displayStatus == 'กำลังซ่อม'
        ? Colors.blue
        : Colors.orange;

    final equipmentName =
        repair['device_name'] ?? repair['equipment'] ?? 'อุปกรณ์ทั่วไป';
    final locationName = repair['location_name'] ?? repair['location'] ?? '-';
    final description = repair['description'] ?? repair['detail'] ?? '-';

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
                    equipmentName.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('สถานที่: $locationName'),
            const SizedBox(height: 6),
            Text('รายละเอียด: $description'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(displayStatus),
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
