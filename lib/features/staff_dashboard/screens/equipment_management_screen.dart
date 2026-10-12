import 'package:flutter/material.dart';

class EquipmentManagementScreen extends StatefulWidget {
  const EquipmentManagementScreen({super.key});

  @override
  State<EquipmentManagementScreen> createState() =>
      _EquipmentManagementScreenState();
}

class _EquipmentManagementScreenState extends State<EquipmentManagementScreen> {
  static const Color navy = Color(0xFF192957);
  static const Color pageBackground = Color(0xFFF4F6FB);

  // ข้อมูลห้องตัวอย่าง ให้ตรงกับหน้าจัดการห้อง
  final List<String> _rooms = [
    'ห้องปฏิบัติการคอมพิวเตอร์ 1',
    'ห้องเรียน 203',
    'ห้องประชุมใหญ่',
  ];

  // ข้อมูลอุปกรณ์ตัวอย่าง
  final List<Map<String, String>> _equipment = [
    {
      'id': 'EQ001',
      'name': 'คอมพิวเตอร์ตั้งโต๊ะ',
      'room': 'ห้องปฏิบัติการคอมพิวเตอร์ 1',
      'category': 'คอมพิวเตอร์',
      'status': 'พร้อมใช้งาน',
    },
    {
      'id': 'EQ002',
      'name': 'โปรเจกเตอร์',
      'room': 'ห้องเรียน 203',
      'category': 'อุปกรณ์นำเสนอ',
      'status': 'ชำรุด',
    },
    {
      'id': 'EQ003',
      'name': 'เครื่องปรับอากาศ',
      'room': 'ห้องประชุมใหญ่',
      'category': 'เครื่องใช้ไฟฟ้า',
      'status': 'พร้อมใช้งาน',
    },
  ];

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

  void _showEquipmentForm({Map<String, String>? equipment}) {
    final isEditing = equipment != null;
    final formKey = GlobalKey<FormState>();

    final idController = TextEditingController(text: equipment?['id'] ?? '');
    final nameController = TextEditingController(
      text: equipment?['name'] ?? '',
    );

    String room = equipment?['room'] ?? _rooms.first;
    String category = equipment?['category'] ?? 'คอมพิวเตอร์';
    String status = equipment?['status'] ?? 'พร้อมใช้งาน';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'แก้ไขข้อมูลอุปกรณ์' : 'เพิ่มอุปกรณ์'),
              content: SizedBox(
                width: 430,
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
                            labelText: 'รหัสอุปกรณ์',
                            hintText: 'เช่น EQ004',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรุณากรอกรหัสอุปกรณ์';
                            }

                            final duplicate = _equipment.any(
                              (item) =>
                                  item['id']!.toLowerCase() ==
                                      value.trim().toLowerCase() &&
                                  item['id'] != equipment?['id'],
                            );

                            if (duplicate) {
                              return 'รหัสอุปกรณ์นี้มีแล้ว';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'ชื่ออุปกรณ์',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'กรุณากรอกชื่ออุปกรณ์'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(
                            labelText: 'ประเภทอุปกรณ์',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'คอมพิวเตอร์',
                              child: Text('คอมพิวเตอร์'),
                            ),
                            DropdownMenuItem(
                              value: 'อุปกรณ์นำเสนอ',
                              child: Text('อุปกรณ์นำเสนอ'),
                            ),
                            DropdownMenuItem(
                              value: 'เครื่องใช้ไฟฟ้า',
                              child: Text('เครื่องใช้ไฟฟ้า'),
                            ),
                            DropdownMenuItem(
                              value: 'อุปกรณ์เครือข่าย',
                              child: Text('อุปกรณ์เครือข่าย'),
                            ),
                            DropdownMenuItem(
                              value: 'อื่น ๆ',
                              child: Text('อื่น ๆ'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => category = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: room,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'ห้องที่ติดตั้ง',
                            border: OutlineInputBorder(),
                          ),
                          items: _rooms.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => room = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'สถานะอุปกรณ์',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'พร้อมใช้งาน',
                              child: Text('พร้อมใช้งาน'),
                            ),
                            DropdownMenuItem(
                              value: 'ชำรุด',
                              child: Text('ชำรุด'),
                            ),
                            DropdownMenuItem(
                              value: 'กำลังซ่อม',
                              child: Text('กำลังซ่อม'),
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
                  style: FilledButton.styleFrom(backgroundColor: navy),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final data = <String, String>{
                      'id': idController.text.trim(),
                      'name': nameController.text.trim(),
                      'room': room,
                      'category': category,
                      'status': status,
                    };

                    setState(() {
                      if (isEditing) {
                        final index = _equipment.indexWhere(
                          (item) => item['id'] == equipment['id'],
                        );

                        if (index != -1) {
                          _equipment[index] = data;
                        }
                      } else {
                        _equipment.add(data);
                      }
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'แก้ไขข้อมูลอุปกรณ์แล้ว'
                              : 'เพิ่มอุปกรณ์แล้ว',
                        ),
                      ),
                    );
                  },
                  child: Text(isEditing ? 'บันทึก' : 'เพิ่มอุปกรณ์'),
                ),
              ],
            );
          },
        );
      },
    );
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
      setState(() {
        _equipment.removeWhere((item) => item['id'] == equipment['id']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredEquipment;

    final readyCount = _equipment
        .where((item) => item['status'] == 'พร้อมใช้งาน')
        .length;
    final brokenCount = _equipment
        .where((item) => item['status'] == 'ชำรุด')
        .length;
    final repairCount = _equipment
        .where((item) => item['status'] == 'กำลังซ่อม')
        .length;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
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
                      const Text(
                        'จัดการข้อมูลอุปกรณ์',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'เพิ่ม แก้ไข ค้นหา และตรวจสอบสถานะอุปกรณ์',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // การ์ดสรุปสถานะอุปกรณ์
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
                                child: _summaryCard(
                                  'พร้อมใช้งาน',
                                  '$readyCount',
                                  Icons.check_circle_outline,
                                  Colors.green,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _summaryCard(
                                  'ชำรุด',
                                  '$brokenCount',
                                  Icons.error_outline,
                                  Colors.red,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _summaryCard(
                                  'กำลังซ่อม',
                                  '$repairCount',
                                  Icons.build_outlined,
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
                                FilledButton.icon(
                                  onPressed: () => _showEquipmentForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('เพิ่มอุปกรณ์'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: navy,
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
                                                if (value == 'edit') {
                                                  _showEquipmentForm(
                                                    equipment: item,
                                                  );
                                                } else if (value == 'delete') {
                                                  _deleteEquipment(item);
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
                                                tooltip: 'แก้ไข',
                                                onPressed: () =>
                                                    _showEquipmentForm(
                                                      equipment: item,
                                                    ),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.blue,
                                                ),
                                              ),
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

  Widget _summaryCard(String title, String count, IconData icon, Color color) {
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
