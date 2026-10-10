import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../services/ticket_service.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final TextEditingController _searchController = TextEditingController();

  RepairStatus? _selectedStatus;

  List<RepairTicket> get _filteredTickets {
    final keyword = _searchController.text.toLowerCase().trim();

    return TicketService.getTickets().where((ticket) {
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
        return 'รอรับงาน';
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
      appBar: AppBar(title: const Text('รายการงานซ่อม')),
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
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('ทั้งหมด', null),
                _filterChip('รอรับงาน', RepairStatus.pending),
                _filterChip('รับงานแล้ว', RepairStatus.accepted),
                _filterChip('กำลังซ่อม', RepairStatus.inProgress),
                _filterChip('เสร็จสิ้น', RepairStatus.completed),
                _filterChip('ยกเลิก', RepairStatus.cancelled),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tickets.isEmpty
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
                                Text('อุปกรณ์: ${ticket.deviceName}'),
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

                            setState(() {});
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

  Widget _filterChip(String label, RepairStatus? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedStatus == status,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
      ),
    );
  }
}
