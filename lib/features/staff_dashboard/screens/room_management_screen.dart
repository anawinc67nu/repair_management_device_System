import 'package:flutter/material.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final List<Map<String, String>> _rooms = [
    {
      'id': 'RM001',
      'name': 'ห้องปฏิบัติการคอมพิวเตอร์ 1',
      'building': 'อาคาร 1',
      'type': 'ห้องปฏิบัติการ',
      'status': 'เปิดใช้งาน',
    },
    {
      'id': 'RM002',
      'name': 'ห้องเรียน 203',
      'building': 'อาคาร 2',
      'type': 'ห้องเรียน',
      'status': 'เปิดใช้งาน',
    },
    {
      'id': 'RM003',
      'name': 'ห้องประชุมใหญ่',
      'building': 'อาคาร 1',
      'type': 'ห้องประชุม',
      'status': 'ปิดใช้งาน',
    },
  ];

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

  void _showRoomForm({Map<String, String>? room}) {
    final isEditing = room != null;
    final formKey = GlobalKey<FormState>();

    final idController = TextEditingController(text: room?['id'] ?? '');
    final nameController = TextEditingController(text: room?['name'] ?? '');
    final buildingController = TextEditingController(
      text: room?['building'] ?? '',
    );

    String type = room?['type'] ?? 'ห้องเรียน';
    String status = room?['status'] ?? 'เปิดใช้งาน';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'แก้ไขข้อมูลห้อง' : 'เพิ่มห้องใหม่'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: idController,
                          enabled: !isEditing,
                          decoration: const InputDecoration(
                            labelText: 'รหัสห้อง',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณากรอกรหัสห้อง';
                            }

                            final duplicate = _rooms.any(
                              (item) =>
                                  item['id']!.toLowerCase() ==
                                      value.trim().toLowerCase() &&
                                  item['id'] != room?['id'],
                            );

                            if (duplicate) return 'รหัสห้องนี้มีแล้ว';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อห้อง',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'กรุณากรอกชื่อห้อง'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: buildingController,
                          decoration: const InputDecoration(
                            labelText: 'อาคาร',
                            hintText: 'เช่น อาคาร 1',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'กรุณากรอกอาคาร'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทห้อง',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ห้องเรียน',
                              child: Text('ห้องเรียน'),
                            ),
                            DropdownMenuItem(
                              value: 'ห้องปฏิบัติการ',
                              child: Text('ห้องปฏิบัติการ'),
                            ),
                            DropdownMenuItem(
                              value: 'ห้องประชุม',
                              child: Text('ห้องประชุม'),
                            ),
                            DropdownMenuItem(
                              value: 'ห้องสำนักงาน',
                              child: Text('ห้องสำนักงาน'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => type = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'สถานะ',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'เปิดใช้งาน',
                              child: Text('เปิดใช้งาน'),
                            ),
                            DropdownMenuItem(
                              value: 'ปิดใช้งาน',
                              child: Text('ปิดใช้งาน'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => status = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final data = <String, String>{
                      'id': idController.text.trim(),
                      'name': nameController.text.trim(),
                      'building': buildingController.text.trim(),
                      'type': type,
                      'status': status,
                    };

                    setState(() {
                      if (isEditing) {
                        final index = _rooms.indexWhere(
                          (item) => item['id'] == room['id'],
                        );
                        if (index != -1) _rooms[index] = data;
                      } else {
                        _rooms.add(data);
                      }
                    });

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing ? 'แก้ไขข้อมูลห้องแล้ว' : 'เพิ่มห้องแล้ว',
                        ),
                      ),
                    );
                  },
                  child: Text(isEditing ? 'บันทึก' : 'เพิ่มห้อง'),
                ),
              ],
            );
          },
        );
      },
    );
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
      setState(() => _rooms.removeWhere((item) => item['id'] == room['id']));
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
                        'เพิ่ม แก้ไข ค้นหา และตรวจสอบสถานะห้องภายในระบบ',
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
                              SizedBox(
                                width: cardWidth,
                                child: _infoCard(
                                  'เปิดใช้งาน',
                                  '${_rooms.where((r) => r['status'] == 'เปิดใช้งาน').length}',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _infoCard(
                                  'ปิดใช้งาน',
                                  '${_rooms.where((r) => r['status'] == 'ปิดใช้งาน').length}',
                                  Icons.pause_circle,
                                  Colors.orange,
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
                                FilledButton.icon(
                                  onPressed: () => _showRoomForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('เพิ่มห้อง'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: navy,
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
                                  final active = room['status'] == 'เปิดใช้งาน';

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
                                                if (value == 'edit') {
                                                  _showRoomForm(room: room);
                                                } else if (value == 'delete') {
                                                  _deleteRoom(room);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('แก้ไข'),
                                                ),
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
                                        const SizedBox(height: 12),
                                        _statusChip(
                                          room['status']!,
                                          active ? Colors.green : Colors.orange,
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
                                    final active =
                                        room['status'] == 'เปิดใช้งาน';

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
                                          _statusChip(
                                            room['status']!,
                                            active
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'แก้ไข',
                                                onPressed: () =>
                                                    _showRoomForm(room: room),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.blue,
                                                ),
                                              ),
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

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
