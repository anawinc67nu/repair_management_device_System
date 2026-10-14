import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final List<Map<String, String>> _rooms = [];
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    final result = await ApiService.getRooms();
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'โหลดข้อมูลห้องไม่สำเร็จ';
      });
      return;
    }
    final rows = result.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return <String, String>{
        'id': (item['id'] ?? item['room_code'] ?? item['code'] ?? '')
            .toString(),
        'name': (item['name'] ?? item['room_name'] ?? '').toString(),
        'building': (item['building'] ?? item['building_name'] ?? '')
            .toString(),
        'type': (item['type'] ?? item['room_type'] ?? 'ห้องเรียน').toString(),
      };
    }).toList();
    setState(() {
      _rooms
        ..clear()
        ..addAll(rows);
      _isLoading = false;
    });
  }

  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  static const Color navy = Color(0xFF192957);
  static const Color pageBackground = Color(0xFFF4F6FB);

  List<Map<String, String>> get _filteredRooms {
    final query = _searchText.toLowerCase().trim();

    return _rooms.where((room) {
      return room.values.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteRoom(Map<String, String> room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบห้อง ${room['name']} ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบห้อง'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ApiService.deleteRoom(room['id']!);
      if (!mounted) return;
      if (ok) {
        await _loadRooms();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบห้องไม่สำเร็จ กรุณาตรวจสอบ API')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _filteredRooms;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'โหลดใหม่',
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
        title: const Text(
          'จัดการห้อง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          tooltip: 'กลับ Dashboard',
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
                      const Text(
                        'จัดการข้อมูลห้อง',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ค้นหา และตรวจสอบห้องภายในระบบ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // การ์ดสรุปจำนวนห้อง
                      LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final availableWidth = cardConstraints.maxWidth;
                          final columns = availableWidth >= 900
                              ? 3
                              : availableWidth >= 480
                              ? 2
                              : 1;

                          const spacing = 12.0;
                          final cardWidth =
                              (availableWidth - spacing * (columns - 1)) /
                              columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _infoCard(
                                  'ห้องทั้งหมด',
                                  '${_rooms.length}',
                                  Icons.meeting_room,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
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
                                  'รายการห้อง',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _searchText = value);
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'ค้นหารหัสห้อง ชื่อห้อง อาคาร หรือประเภท',
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
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (rooms.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('ไม่พบข้อมูลห้อง')),
                              )
                            else if (isMobile)
                              // มือถือแสดงเป็นการ์ด ไม่ต้องเลื่อนตารางแนวนอน
                              Column(
                                children: rooms.map((room) {
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
                                              Icons.meeting_room_outlined,
                                              color: navy,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    room['name']!,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    room['id']!,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              tooltip: 'จัดการห้อง',
                                              onSelected: (value) {
                                                if (value == 'delete') {
                                                  _deleteRoom(room);
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
                                        _mobileRoomDetail(
                                          'อาคาร',
                                          room['building']!,
                                        ),
                                        const SizedBox(height: 8),
                                        _mobileRoomDetail(
                                          'ประเภทห้อง',
                                          room['type']!,
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
                                    DataColumn(label: Text('รหัสห้อง')),
                                    DataColumn(label: Text('ชื่อห้อง')),
                                    DataColumn(label: Text('อาคาร')),
                                    DataColumn(label: Text('ประเภท')),
                                    DataColumn(label: Text('สถานะ')),
                                    DataColumn(label: Text('จัดการ')),
                                  ],
                                  rows: rooms.map((room) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(room['id']!)),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 260,
                                            ),
                                            child: Text(
                                              room['name']!,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(room['building']!)),
                                        DataCell(Text(room['type']!)),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'ลบ',
                                                onPressed: () =>
                                                    _deleteRoom(room),
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
                              'แสดง ${rooms.length} จาก ${_rooms.length} ห้อง',
                              style: const TextStyle(color: Colors.grey),
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

  Widget _mobileRoomDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _infoCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
