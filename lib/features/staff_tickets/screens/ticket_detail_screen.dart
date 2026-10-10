
import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../services/ticket_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketDetailScreen> createState() =>
      _TicketDetailScreenState();
}

class _TicketDetailScreenState
    extends State<TicketDetailScreen> {
  final TextEditingController _notesController =
      TextEditingController();

  RepairTicket? _ticket;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  void _loadTicket() {
    _ticket = TicketService.findById(widget.ticketId);
    _notesController.text = _ticket?.repairNotes ?? '';
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

  void _changeStatus(RepairStatus status) {
    TicketService.updateStatus(widget.ticketId, status);

    setState(() {
      _loadTicket();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เปลี่ยนสถานะแล้ว')),
    );
  }

  void _saveNotes() {
    TicketService.saveRepairNotes(
      widget.ticketId,
      _notesController.text.trim(),
    );

    setState(() {
      _loadTicket();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกผลการซ่อมแล้ว')),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดงานซ่อม')),
        body: const Center(child: Text('ไม่พบงานซ่อม')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('งานซ่อม ${ticket.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            ticket.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          _info('รหัสงาน', ticket.id),
          _info('ชื่อลูกค้า', ticket.customerName),
          _info('อุปกรณ์', ticket.deviceName),
          _info('อาการเสีย', ticket.description),
          _info(
            'วันที่แจ้งซ่อม',
            '${ticket.createdAt.day}/'
                '${ticket.createdAt.month}/'
                '${ticket.createdAt.year}',
          ),
          _info('สถานะ', _statusText(ticket.status)),
          _info(
            'เจ้าหน้าที่',
            ticket.assignedStaff ?? 'ยังไม่มีผู้รับงาน',
          ),

          const Divider(height: 32),

          const Text(
            'จัดการสถานะงาน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (ticket.status == RepairStatus.pending)
            ElevatedButton.icon(
              onPressed: () =>
                  _changeStatus(RepairStatus.accepted),
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('รับงานนี้'),
            ),

          if (ticket.status == RepairStatus.accepted)
            ElevatedButton.icon(
              onPressed: () =>
                  _changeStatus(RepairStatus.inProgress),
              icon: const Icon(Icons.build),
              label: const Text('เริ่มดำเนินการซ่อม'),
            ),

          if (ticket.status == RepairStatus.inProgress)
            ElevatedButton.icon(
              onPressed: () =>
                  _changeStatus(RepairStatus.completed),
              icon: const Icon(Icons.check_circle),
              label: const Text('ทำเครื่องหมายว่าเสร็จสิ้น'),
            ),

          if (ticket.status == RepairStatus.completed)
            const Text(
              'งานนี้ดำเนินการเสร็จสิ้นแล้ว',
              style: TextStyle(color: Colors.green),
            ),

          const Divider(height: 32),

          const Text(
            'บันทึกผลการซ่อม',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'ระบุอาการที่ตรวจพบ วิธีแก้ไข หรืออะไหล่ที่เปลี่ยน',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _saveNotes,
            icon: const Icon(Icons.save),
            label: const Text('บันทึกผลการซ่อม'),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
