import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class EquipmentManagementScreen extends StatefulWidget {
  const EquipmentManagementScreen({super.key});

  @override
  State<EquipmentManagementScreen> createState() =>
      _EquipmentManagementScreenState();
}

class _EquipmentManagementScreenState extends State<EquipmentManagementScreen> {
  static const Color navy = Color(0xFF192957);
  static const Color pageBackground = Color(0xFFF4F6FB);

  final List<String> _rooms = ['ไม่ระบุห้อง'];
  final List<Map<String, String>> _equipment = [];
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    final results = await Future.wait([
      ApiService.getEquipments(),
      ApiService.getRooms(),
    ]);
    if (!mounted) return;
    final eqResult = results[0] as List<dynamic>?;
    final roomResult = results[1] as List<dynamic>?;
    if (eqResult == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'โหลดข้อมูลอุปกรณ์ไม่สำเร็จ';
      });
      return;
    }
    final rows = eqResult.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return <String, String>{
        'id': (item['id'] ?? item['device_code'] ?? item['code'] ?? '')
            .toString(),
        'name':
            (item['name'] ??
                    item['equipment_name'] ??
                    item['device_name'] ??
                    '')
                .toString(),
        'room':
            (item['room'] ?? item['room_name'] ?? item['location_name'] ?? '')
                .toString(),
        'category': (item['category'] ?? item['type'] ?? 'อื่น ๆ').toString(),
        'status': (item['status'] ?? 'พร้อมใช้งาน').toString(),
      };
    }).toList();
    final roomNames = (roomResult ?? [])
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          return (item['name'] ?? item['room_name'] ?? '').toString();
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      _equipment
        ..clear()
        ..addAll(rows);
      _rooms
        ..clear()
        ..addAll(roomNames);
      if (_rooms.isEmpty) _rooms.add('ไม่ระบุห้อง');
      _isLoading = false;
    });
  }

  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  List<Map<String, String>> get _filteredEquipment {
    final query = _searchText.toLowerCase().trim();

    return _equipment.where((item) {
      return item.values.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteEquipment(Map<String, String> equipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบอุปกรณ์ ${equipment['name']} ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบอุปกรณ์'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final ok = await ApiService.deleteEquipment(equipment['id']!);
      if (!mounted) return;
      if (ok) {
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบอุปกรณ์ไม่สำเร็จ กรุณาตรวจสอบ API')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredEquipment;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'โหลดใหม่',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        title: const Text(
          'จัดการอุปกรณ์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          tooltip: 'กลับ',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final padding = width < 400
                ? 12.0
                : isMobile
                ? 16.0
                : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading) const LinearProgressIndicator(),
                      if (_loadError != null)
                        Text(
                          '$_loadError — กดรีเฟรชเพื่อลองอีกครั้ง',
                          style: const TextStyle(color: Colors.red),
                        ),

                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                const Text(
                                  'รายการอุปกรณ์',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _searchText = value);
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'ค้นหารหัส ชื่ออุปกรณ์ ห้อง หรือสถานะ',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchText.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchText = '');
                                        },
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text('ไม่พบข้อมูลอุปกรณ์'),
                                ),
                              )
                            else if (isMobile)
                              // มือถือใช้การ์ด
                              Column(
                                children: items.map((item) {
                                  final status = item['status'] ?? '';
                                  final statusColor = status == 'พร้อมใช้งาน'
                                      ? Colors.green
                                      : status == 'ชำรุด'
                                      ? Colors.red
                                      : Colors.orange;

                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.devices_outlined,
                                              color: navy,
                                              size: 26,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['id'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'delete') {
                                                  _deleteEquipment(item);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('ลบ'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        _equipmentDetail(
                                          'ห้อง',
                                          item['room'] ?? '',
                                        ),
                                        const SizedBox(height: 8),
                                        _equipmentDetail(
                                          'ประเภท',
                                          item['category'] ?? '',
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                            else
                              // แท็บเล็ตและคอมพิวเตอร์ใช้ตาราง
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('รหัส')),
                                    DataColumn(label: Text('ชื่ออุปกรณ์')),
                                    DataColumn(label: Text('ห้อง')),
                                    DataColumn(label: Text('ประเภท')),
                                    DataColumn(label: Text('สถานะ')),
                                    DataColumn(label: Text('จัดการ')),
                                  ],
                                  rows: items.map((item) {
                                    final status = item['status'] ?? '';
                                    final statusColor = status == 'พร้อมใช้งาน'
                                        ? Colors.green
                                        : status == 'ชำรุด'
                                        ? Colors.red
                                        : Colors.orange;

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item['id'] ?? '')),
                                        DataCell(Text(item['name'] ?? '')),
                                        DataCell(Text(item['room'] ?? '')),
                                        DataCell(Text(item['category'] ?? '')),
                                        DataCell(
                                          Text(
                                            status,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'ลบ',
                                                onPressed: () =>
                                                    _deleteEquipment(item),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),

                            const SizedBox(height: 8),
                            Text(
                              'แสดง ${items.length} จาก ${_equipment.length} รายการ',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _equipmentDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
