import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RepairRequest {
  final int ticketId;
  final String id;
  final String equipment;
  final String room;
  final String reporter;
  final String problem;
  final DateTime createdAt;
  String status;

  RepairRequest({
    required this.ticketId,
    required this.id,
    required this.equipment,
    required this.room,
    required this.reporter,
    required this.problem,
    required this.createdAt,
    required this.status,
  });
}

class RepairManagementScreen extends StatefulWidget {
  const RepairManagementScreen({super.key});

  @override
  State<RepairManagementScreen> createState() => _RepairManagementScreenState();
}

class _RepairManagementScreenState extends State<RepairManagementScreen> {
  String _statusToApi(String status) {
    switch (status) {
      case 'รอดำเนินการ':
        return 'pending';
      case 'กำลังซ่อม':
        return 'in_progress';
      case 'ซ่อมเสร็จแล้ว':
        return 'completed';
      case 'ยกเลิก':
        return 'cancelled';
      default:
        return status;
    }
  }

  static const Color navy = Color(0xFF173B72);
  static const Color blue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF4F7FC);

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'ทั้งหมด';

  final List<RepairRequest> _requests = [];

  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await ApiService.getTickets();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _loadError = 'โหลดรายการไม่สำเร็จ กรุณาตรวจสอบ Backend';
          _isLoading = false;
        });
        return;
      }

      final tickets = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_mapTicket)
          .toList();

      setState(() {
        _requests
          ..clear()
          ..addAll(tickets);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
        _isLoading = false;
      });
    }
  }

  RepairRequest _mapTicket(Map<String, dynamic> item) {
    final rawId = item['id'];
    final ticketId = int.tryParse(rawId.toString()) ?? 0;

    final rawStatus = (item['status'] ?? 'pending').toString();

    final statusMap = {
      'pending': 'รอดำเนินการ',
      'in_progress': 'กำลังซ่อม',
      'completed': 'ซ่อมเสร็จแล้ว',
      'cancelled': 'ยกเลิก',
      'รอดำเนินการ': 'รอดำเนินการ',
      'กำลังซ่อม': 'กำลังซ่อม',
      'ซ่อมเสร็จแล้ว': 'ซ่อมเสร็จแล้ว',
      'ยกเลิก': 'ยกเลิก',
    };

    final createdAt = DateTime.tryParse(
      (item['created_at'] ?? item['createdAt'] ?? '').toString(),
    );

    return RepairRequest(
      ticketId: ticketId,
      id: 'REP-${ticketId.toString().padLeft(3, '0')}',
      equipment:
          (item['equipment_name'] ??
                  item['device_name'] ??
                  item['equipment'] ??
                  item['device_code'] ??
                  'ไม่ระบุอุปกรณ์')
              .toString(),
      room:
          (item['room_number'] ??
                  item['room'] ??
                  item['room_name'] ??
                  'ไม่ระบุห้อง')
              .toString(),
      reporter:
          (item['reporter_name'] ??
                  item['reporter'] ??
                  item['user_name'] ??
                  'ไม่ระบุผู้แจ้ง')
              .toString(),
      problem: (item['description'] ?? item['problem'] ?? 'ไม่ระบุรายละเอียด')
          .toString(),
      createdAt: createdAt ?? DateTime.now(),
      status: statusMap[rawStatus] ?? rawStatus,
    );
  }

  final List<String> _statuses = [
    'รอดำเนินการ',
    'กำลังซ่อม',
    'ซ่อมเสร็จแล้ว',
    'ยกเลิก',
  ];

  List<RepairRequest> get _filteredRequests {
    final keyword = _searchController.text.toLowerCase().trim();

    return _requests.where((request) {
      final matchesSearch =
          request.id.toLowerCase().contains(keyword) ||
          request.equipment.toLowerCase().contains(keyword) ||
          request.room.toLowerCase().contains(keyword) ||
          request.reporter.toLowerCase().contains(keyword) ||
          request.problem.toLowerCase().contains(keyword);

      final matchesStatus =
          _selectedFilter == 'ทั้งหมด' || request.status == _selectedFilter;

      return matchesSearch && matchesStatus;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int _countByStatus(String status) {
    final apiStatus = _statusToApi(status);

    return _requests.where((request) {
      return _statusToApi(request.status) == apiStatus;
    }).length;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'รอดำเนินการ':
        return const Color(0xFFD97706);
      case 'กำลังซ่อม':
        return const Color(0xFF2563EB);
      case 'ซ่อมเสร็จแล้ว':
        return const Color(0xFF16A34A);
      case 'ยกเลิก':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  void _showDetails(RepairRequest request) {
    String newStatus = request.status;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('รายละเอียด ${request.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('อุปกรณ์', request.equipment),
                    _detailRow('ห้อง', request.room),
                    _detailRow('ผู้แจ้ง', request.reporter),
                    _detailRow('วันที่แจ้ง', _formatDate(request.createdAt)),
                    const SizedBox(height: 12),
                    const Text(
                      'รายละเอียดปัญหา',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(request.problem),
                    const SizedBox(height: 16),
                    const Text(
                      'สถานะงาน',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: newStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            newStatus = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (request.ticketId <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่พบ ID ใบแจ้งซ่อมจากฐานข้อมูล'),
                        ),
                      );
                      return;
                    }

                    final success = await ApiService.updateTicketStatus(
                      request.ticketId,
                      _statusToApi(newStatus),
                    );

                    if (!context.mounted) return;

                    if (success) {
                      Navigator.pop(context);
                      await _loadTickets();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกสถานะไม่สำเร็จ')),
                      );
                    }
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // การ์ดสรุป: ใช้ความสูงตามเนื้อหา ไม่บังคับ Column
  // ให้อยู่ในพื้นที่ที่เตี้ยเกินไปบนมือถือ
  Widget _summaryCard(String title, int count, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _repairCard(RepairRequest request) {
    final color = _statusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _showDetails(request),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request.status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.equipment,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF252B36),
                ),
              ),
              const SizedBox(height: 7),
              _infoLine('ห้อง', request.room),
              _infoLine('ผู้แจ้ง', request.reporter),
              _infoLine('ปัญหา', request.problem),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(request.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const Text(
                    'ดูรายละเอียด',
                    style: TextStyle(
                      color: blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, color: blue, size: 19),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFF667085),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        title: const Text(
          'จัดการแจ้งซ่อม',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 600;
            final isWide = width >= 900;

            final horizontalPadding = width < 400
                ? 12.0
                : isMobile
                ? 16.0
                : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ภาพรวมงานแจ้งซ่อม',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // การ์ดสรุปจำนวนงาน
                      LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final availableWidth = cardConstraints.maxWidth;

                          final columns = availableWidth >= 1000
                              ? 4
                              : availableWidth >= 520
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
                                  'งานทั้งหมด',
                                  _requests.length,
                                  Icons.assignment_outlined,
                                  navy,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _summaryCard(
                                  'รอดำเนินการ',
                                  _countByStatus('รอดำเนินการ'),
                                  Icons.pending_actions,
                                  const Color(0xFFD97706),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _summaryCard(
                                  'กำลังซ่อม',
                                  _countByStatus('กำลังซ่อม'),
                                  Icons.build_outlined,
                                  blue,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _summaryCard(
                                  'ซ่อมเสร็จแล้ว',
                                  _countByStatus('ซ่อมเสร็จแล้ว'),
                                  Icons.check_circle_outline,
                                  const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'รายการแจ้งซ่อม',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // จอใหญ่แสดงช่องค้นหาและตัวกรองแถวเดียวกัน
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildSearchField()),
                            const SizedBox(width: 14),
                            Expanded(flex: 2, child: _buildStatusFilter()),
                          ],
                        )
                      else ...[
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildStatusFilter(),
                      ],

                      const SizedBox(height: 18),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_loadError != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.cloud_off,
                                  size: 42,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(_loadError!),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _loadTickets,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('ลองโหลดอีกครั้ง'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (requests.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8EDF5)),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 42,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text('ยังไม่มีรายการแจ้งซ่อม'),
                            ],
                          ),
                        )
                      else
                        ...requests.map(_repairCard),
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'ค้นหารหัสงาน อุปกรณ์ ห้อง หรือผู้แจ้ง',
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'ล้างคำค้นหา',
          icon: const Icon(Icons.close),
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
      ),
    );
  }

  // ตัวกรองสถานะ
  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'กรองตามสถานะ',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: ['ทั้งหมด', ..._statuses].map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedFilter = value);
        }
      },
    );
  }
}
