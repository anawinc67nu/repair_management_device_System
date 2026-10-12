import 'package:flutter/material.dart';
import '../models/repair_ticket.dart';
import '../../../services/api_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _isLoading = true;
  RepairTicket? _ticket;
  
  // Controller สำหรับกรอกหมายเหตุการซ่อม (Action Note)
  final TextEditingController _noteController = TextEditingController();
  
  // สถานะที่เลือกเปลี่ยนปัจจุบัน
  RepairStatus? _currentSelectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
  }

  // ดึงรายละเอียดงานซ่อมรายชิ้นจาก API
  Future<void> _fetchTicketDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // เรียกดึงรายการทั้งหมดมาหาตัวที่ตรงกับ ID (หรือถ้า Backend มี endpoint /tickets/{id} ให้เปลี่ยนไปใช้ตัวนั้นได้ครับ)
      final dataList = await ApiService.getTickets();
      if (!mounted) return;

      if (dataList != null) {
        final found = dataList.firstWhere(
          (item) => item['id'].toString() == widget.ticketId,
          orElse: () => null,
        );

        if (found != null) {
          final ticketObj = RepairTicket.fromJson(found);
          setState(() {
            _ticket = ticketObj;
            _currentSelectedStatus = ticketObj.status;
            _noteController.text = ticketObj.repairNotes;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายละเอียด: $e')),
      );
    }
  }

  // แปลง Enum สถานะเป็น String สำหรับส่ง API
  String _statusToString(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return 'pending';
      case RepairStatus.accepted:
        return 'accepted';
      case RepairStatus.inProgress:
        return 'in_progress';
      case RepairStatus.completed:
        return 'completed';
      case RepairStatus.cancelled:
        return 'cancelled';
    }
  }

  // ฟังก์ชันกดบันทึกการเปลี่ยนแปลงสถานะและหมายเหตุ
  Future<void> _saveChanges() async {
    if (_ticket == null || _currentSelectedStatus == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final intId = int.tryParse(widget.ticketId) ?? 0;
      final statusStr = _statusToString(_currentSelectedStatus!);
      final note = _noteController.text.trim();

      // ส่งข้อมูลไปอัปเดตที่ API
      final success = await ApiService.saveRepairAction(intId, statusStr, note);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลและอัปเดตสถานะสำเร็จ')),
        );
        Navigator.pop(context); // กลับหน้าหลักและรีเฟรช
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถบันทึกข้อมูลได้ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดงานซ่อม (รหัส: ${widget.ticketId})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? const Center(child: Text('ไม่พบข้อมูลงานซ่อมนี้'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card แสดงข้อมูลทั่วไป
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ticket!.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 24),
                              _infoRow('รหัสงาน:', _ticket!.id),
                              _infoRow('ชื่อผู้แจ้ง:', _ticket!.customerName),
                              _infoRow('อุปกรณ์:', _ticket!.deviceName),
                              _infoRow('รายละเอียดปัญหา:', _ticket!.description),
                              _infoRow(
                                'วันที่แจ้ง:',
                                _ticket!.createdAt.toLocal().toString().split('.')[0],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ส่วนสำหรับเปลี่ยนสถานะงาน (Workflow ของช่าง)
                      const Text(
                        'เปลี่ยนสถานะการซ่อม',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<RepairStatus>(
                        value: _currentSelectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: RepairStatus.pending,
                            child: Text('รอรับงาน (Pending)'),
                          ),
                          DropdownMenuItem(
                            value: RepairStatus.accepted,
                            child: Text('รับงานแล้ว (Accepted)'),
                          ),
                          DropdownMenuItem(
                            value: RepairStatus.inProgress,
                            child: Text('กำลังซ่อม (In Progress)'),
                          ),
                          DropdownMenuItem(
                            value: RepairStatus.completed,
                            child: Text('เสร็จสิ้น (Completed)'),
                          ),
                          DropdownMenuItem(
                            value: RepairStatus.cancelled,
                            child: Text('ยกเลิก (Cancelled)'),
                          ),
                        ],
                        onChanged: (RepairStatus? newStatus) {
                          setState(() {
                            _currentSelectedStatus = newStatus;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // ส่วนกรอกหมายเหตุผลการซ่อม (Action Note)
                      const Text(
                        'บันทึกผลการซ่อม / หมายเหตุ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'ระบุรายละเอียดการซ่อม หรือสาเหตุที่พบ...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ปุ่มบันทึก
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'บันทึกข้อมูล',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}