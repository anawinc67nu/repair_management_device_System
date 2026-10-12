import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  List<dynamic> deviceList = [];
  String? selectedRoomDeviceId;

  // กำหนด userId ของผู้ใช้งาน
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

  // ดึงข้อมูลอุปกรณ์จริงในห้องผ่าน API
  Future<void> fetchDevicesInRoom(String scannedRoomCode) async {
    setState(() {
      isLoading = true;
      deviceList = [];
      selectedRoomDeviceId = null;
    });

    try {
      final result = await ApiService.getRoomEquipments(scannedRoomCode);

      if (result != null && result['equipments'] != null) {
        setState(() {
          deviceList = List<dynamic>.from(result['equipments']);
        });
      } else {
        showMessage('ไม่พบข้อมูลอุปกรณ์ในห้องนี้');
      }
    } catch (e) {
      showMessage('เกิดข้อผิดพลาดในการดึงข้อมูลอุปกรณ์: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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

  // ฟังก์ชันเปิดหน้าสแกน QR Code
  Future<void> openQrScanner() async {
    final scannedResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedResult != null && scannedResult.isNotEmpty) {
      setState(() {
        locationController.text = scannedResult;
        selectedTab = 1; // สลับไปหน้าแจ้งซ่อมทันที
      });

      // ดึงรายการอุปกรณ์ในห้องนั้นจาก API
      fetchDevicesInRoom(scannedResult);

      showMessage('สแกนสำเร็จ: ดึงข้อมูลห้อง $scannedResult เรียบร้อย');
    }
  }

  // ดึงประวัติการแจ้งซ่อมของผู้ใช้
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
  }

  // ส่งฟอร์มแจ้งซ่อม
  // ส่งฟอร์มแจ้งซ่อม
  Future<void> submitRepair() async {
    final inputDeviceId = deviceIdController.text.trim();

    // 1. ถ้าประเภทอุปกรณ์ยังไม่มีค่า ให้ใช้ค่าเริ่มต้นทันที (ไม่ต้องมี Dropdown ให้เลือกแล้ว)
    selectedEquipment ??= 'อุปกรณ์ทั่วไป';

    // 2. เช็กเฉพาะ 3 ช่องที่มีอยู่จริงบนหน้าจอ (รหัสเครื่อง, สถานที่, อาการเสีย)
    if (inputDeviceId.isEmpty ||
        detailController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }

    // 3. ตรวจสอบการแจ้งซ่อมซ้ำ
    final hasPendingTicket = repairHistory.any((ticket) {
      final ticketDeviceId = ticket['device_id']?.toString().trim() ?? '';
      final description = ticket['description']?.toString() ?? '';
      final status = translateStatus(ticket['status']?.toString());

      final isSameDevice =
          inputDeviceId.isNotEmpty &&
          ((ticketDeviceId.isNotEmpty && ticketDeviceId == inputDeviceId) ||
              description.contains('[รหัสเครื่อง: $inputDeviceId]'));

      final isStillActive = status == 'รอดำเนินการ' || status == 'กำลังซ่อม';

      return isSameDevice && isStillActive;
    });

    if (hasPendingTicket) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('อุปกรณ์นี้ถูกแจ้งซ่อมแล้ว'),
            ],
          ),
          content: Text(
            'อุปกรณ์รหัส "$inputDeviceId" มีรายการแจ้งซ่อมที่กำลังดำเนินการอยู่แล้ว คุณสามารถติดตามสถานะได้ในหน้าประวัติ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
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
        deviceIdController.clear();
        detailController.clear();
        locationController.clear();

        setState(() {
          selectedEquipment = null;
          selectedRoomDeviceId = null;
          deviceList = [];
          selectedTab = 2; // สลับไปหน้าประวัติ
        });

        showMessage('ส่งคำขอแจ้งซ่อมสำเร็จ');
        await fetchRepairHistory();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text('ไม่สามารถบันทึกได้'),
              ],
            ),
            content: Text(
              'ไม่สามารถบันทึกได้ เนื่องจากอุปกรณ์รหัส "$inputDeviceId" มีรายการแจ้งซ่อมซ้ำหรืออยู่ระหว่างดำเนินการอยู่แล้ว',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
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
                      onPressed: openQrScanner,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('เริ่มสแกน QR Code'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แจ้งซ่อมอุปกรณ์',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 1. ปุ่มสแกน QR Code
          OutlinedButton.icon(
            onPressed: openQrScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('สแกน QR Code ประจำห้อง / อุปกรณ์'),
          ),
          const SizedBox(height: 20),

          // 2. ช่องสถานที่ตั้งอุปกรณ์
          const Text(
            'สถานที่ตั้งอุปกรณ์ *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              hintText: 'เช่น SC2-307',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // 3. รายการเลือกอุปกรณ์ในห้อง (ถ้ามีข้อมูลดึงจาก API)
          if (deviceList.isNotEmpty) ...[
            const Text(
              'เลือกอุปกรณ์ในห้องนี้ *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedRoomDeviceId,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: '-- เลือกอุปกรณ์ที่เสียในห้องนี้ --',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: deviceList.map((device) {
                final devId = (device['id'] ?? device['device_id'] ?? '')
                    .toString();
                final devName =
                    (device['name'] ?? device['device_name'] ?? 'อุปกรณ์')
                        .toString();

                return DropdownMenuItem<String>(
                  value: devId,
                  child: Text('$devName (ID: $devId)'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedRoomDeviceId = val;
                  final matched = deviceList.firstWhere(
                    (d) => (d['id'] ?? d['device_id'] ?? '').toString() == val,
                    orElse: () => null,
                  );

                  if (matched != null) {
                    deviceIdController.text = val ?? '';

                    // ดึงประเภทอุปกรณ์จาก API มาแมปอัตโนมัติ
                    final apiType =
                        (matched['type'] ??
                                matched['equipment_type'] ??
                                matched['device_type'])
                            ?.toString();
                    selectedEquipment = (apiType != null && apiType.isNotEmpty)
                        ? apiType
                        : 'อุปกรณ์ทั่วไป';
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ],

          // 4. ช่องรหัสเครื่อง
          const Text(
            'รหัสเครื่อง / Device ID *',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: deviceIdController,
            decoration: const InputDecoration(
              hintText: 'เช่น 80',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // 5. ช่องรายละเอียดอาการเสีย
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

          // 6. ปุ่มกดส่งคำขอ
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

    String fullDesc = (repair['description'] ?? repair['detail'] ?? '-')
        .toString();
    String locationName = (repair['location_name'] ?? repair['location'] ?? '')
        .toString();
    String cleanDetail = fullDesc;

    if ((locationName.isEmpty || locationName == '-') &&
        fullDesc.contains('[สถานที่:')) {
      final regExpLocation = RegExp(r'\[สถานที่:\s*(.*?)\]');
      final matchLoc = regExpLocation.firstMatch(fullDesc);
      if (matchLoc != null) {
        locationName = matchLoc.group(1) ?? '-';
      }
    }

    String formattedLocation = locationName.trim();
    if (formattedLocation.isNotEmpty && formattedLocation != '-') {
      if (!formattedLocation.contains('อาคาร') &&
          !formattedLocation.contains('ห้อง')) {
        formattedLocation = 'ห้อง $formattedLocation';
      }
    } else {
      formattedLocation = '-';
    }

    cleanDetail = cleanDetail.replaceAll(RegExp(r'\[รหัสเครื่อง:.*?\]\s*'), '');
    cleanDetail = cleanDetail.replaceAll(RegExp(r'\[ประเภท:.*?\]\s*'), '');
    cleanDetail = cleanDetail.replaceAll(RegExp(r'\[สถานที่:.*?\]\s*'), '');

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
            Text('สถานที่: $formattedLocation'),
            const SizedBox(height: 6),
            Text('รายละเอียด: $cleanDetail'),
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

// -------------------------------------------------------------
// หน้าจอสำหรับสแกน QR Code (Mobile Scanner Screen)
// -------------------------------------------------------------
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR Code อุปกรณ์'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                final isTorchOn = state.torchState == TorchState.on;
                return Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.yellow : Colors.grey,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                return const Icon(Icons.cameraswitch);
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (barcodeCapture) {
              if (isScanned) return;

              final List<Barcode> barcodes = barcodeCapture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  setState(() {
                    isScanned = true;
                  });
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
