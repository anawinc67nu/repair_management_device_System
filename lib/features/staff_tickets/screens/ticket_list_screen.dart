import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../../../services/api_service.dart'; // เปลี่ยนมาใช้ ApiService แทน TicketService
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final TextEditingController _searchController = TextEditingController();

  RepairStatus? _selectedStatus;
  List<RepairTicket> _allTickets = []; // เก็บรายการทั้งหมดจาก API
  bool _isLoading = true; // สถานะกำลังโหลด

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  // ฟังก์ชันดึงข้อมูลจาก API จริง
  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.getTickets();

      if (!mounted) return;

      if (data != null) {
        // แปลงข้อมูล JSON List เป็น Model RepairTicket
        // (ตรวจสอบชื่อ Key ใน fromJson ให้ตรงกับโครงสร้าง Backend ของคุณ)
        setState(() {
          _allTickets = data
              .map((json) => RepairTicket.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
      );
    }
  }

  // ฟังก์ชันสำหรับกรองข้อมูล (Search & Status Filter)
  List<RepairTicket> get _filteredTickets {
    final keyword = _searchController.text.toLowerCase().trim();

    return _allTickets.where((ticket) {
      final matchesSearch =
          ticket.id.toLowerCase().contains(keyword) ||
          ticket.customerName.toLowerCase().contains(keyword) ||
          ticket.deviceName.toLowerCase().contains(keyword) ||
          ticket.title.toLowerCase().contains(keyword);

      final matchesStatus =
          _selectedStatus == null || ticket.status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _statusText(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'รอดำเนินการ';
      case RepairStatus.accepted:
        return 'รับงานแล้ว';
      case RepairStatus.inProgress:
        return 'กำลังซ่อม';
      case RepairStatus.completed:
        return 'เสร็จสิ้น';
      case RepairStatus.cancelled:
        return 'ยกเลิก';
    }
  }

  Color _statusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return Colors.orange;
      case RepairStatus.accepted:
        return Colors.blue;
      case RepairStatus.inProgress:
        return Colors.purple;
      case RepairStatus.completed:
        return Colors.green;
      case RepairStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _filteredTickets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการงานซ่อม'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTickets, // ปุ่มกดรีเฟรชข้อมูลจาก API
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ค้นหารหัสงาน ลูกค้า หรืออุปกรณ์',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: _filterChip('ทั้งหมด', null)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _filterChip('รอดำเนินการ', RepairStatus.pending),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _filterChip('รับงานแล้ว', RepairStatus.accepted),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _filterChip('กำลังซ่อม', RepairStatus.inProgress),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _filterChip('เสร็จสิ้น', RepairStatus.completed),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _filterChip('ยกเลิก', RepairStatus.cancelled),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : tickets.isEmpty
                ? const Center(child: Text('ไม่พบรายการงานซ่อม'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            ticket.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('รหัสงาน: ${ticket.id}'),
                                Text('ลูกค้า: ${ticket.customerName}'),
                                const SizedBox(height: 8),
                                Text(
                                  _statusText(ticket.status),
                                  style: TextStyle(
                                    color: _statusColor(ticket.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TicketDetailScreen(ticketId: ticket.id),
                              ),
                            );

                            // เมื่อกลับมาจากหน้า Detail ให้รีโหลดข้อมูลใหม่เผื่อมีการเปลี่ยนสถานะ
                            _fetchTickets();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _filterTickets() {
    setState(() {
      // โค้ดสำหรับกรองข้อมูลรายการซ่อมตามสถานะ _selectedStatus ที่เลือก
    });
  }

  Widget _filterChip(String label, RepairStatus? status) {
    bool isSelected = _selectedStatus == status;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedStatus = status;
          _filterTickets();
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue.shade50 : Colors.transparent,
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // ทำขอบมนให้เหมือน Chip
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ), // ปรับความสูงตามต้องการ
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
