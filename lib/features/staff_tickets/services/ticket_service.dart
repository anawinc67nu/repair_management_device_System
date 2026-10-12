import '../models/repair_ticket.dart';

class TicketService {
  // ข้อมูลจำลองสำหรับทดสอบหน้ารายการงานซ่อม
  static final List<RepairTicket> _tickets = [
    RepairTicket(
      id: 'REP001',
      title: 'โน้ตบุ๊กเปิดไม่ติด',
      description: 'กดปุ่มเปิดเครื่องแล้วไม่มีการตอบสนอง',
      customerName: 'สมชาย ใจดี',
      deviceName: 'Laptop ASUS',
      createdAt: DateTime(2026, 10, 1),
    ),
    RepairTicket(
      id: 'REP002',
      title: 'โทรศัพท์ชาร์จไม่เข้า',
      description: 'เสียบสายชาร์จแล้วแบตเตอรี่ไม่เพิ่ม',
      customerName: 'สุดา แก้วใส',
      deviceName: 'iPhone',
      createdAt: DateTime(2026, 10, 3),
      status: RepairStatus.accepted,
    ),
    RepairTicket(
      id: 'REP003',
      title: 'คอมพิวเตอร์ทำงานช้า',
      description: 'เปิดโปรแกรมใช้เวลานานกว่าปกติ',
      customerName: 'วิชัย รักดี',
      deviceName: 'Desktop PC',
      createdAt: DateTime(2026, 10, 5),
      status: RepairStatus.inProgress,
    ),
    RepairTicket(
      id: 'REP004',
      title: 'เปลี่ยนหน้าจอแท็บเล็ต',
      description: 'หน้าจอแตกจากการตกกระแทก',
      customerName: 'มาลี มีสุข',
      deviceName: 'Samsung Tablet',
      createdAt: DateTime(2026, 10, 6),
      status: RepairStatus.completed,
    ),
    RepairTicket(
      id: 'REP005',
      title: 'เมาส์ใช้งานไม่ได้',
      description: 'คอมพิวเตอร์ตรวจไม่พบเมาส์',
      customerName: 'ธนา ตั้งใจ',
      deviceName: 'Wireless Mouse',
      createdAt: DateTime(2026, 10, 7),
    ),
  ];

  static List<RepairTicket> getTickets() {
    return List.unmodifiable(_tickets);
  }

  // ค้นหางานซ่อมด้วยรหัส
  static RepairTicket? findById(String id) {
    for (final ticket in _tickets) {
      if (ticket.id == id) {
        return ticket;
      }
    }
    return null;
  }

  // เปลี่ยนสถานะและบันทึกข้อมูลเจ้าหน้าที่
  static void updateStatus(String id, RepairStatus status) {
    final index = _tickets.indexWhere((ticket) => ticket.id == id);

    if (index == -1) return;

    _tickets[index] = _tickets[index].copyWith(
      status: status,
      assignedStaff: status == RepairStatus.pending
          ? null
          : (_tickets[index].assignedStaff ?? 'Staff'),
    );
  }

  // บันทึกผลการซ่อม
  static void saveRepairNotes(String id, String notes) {
    final index = _tickets.indexWhere((ticket) => ticket.id == id);

    if (index == -1) return;

    _tickets[index] = _tickets[index].copyWith(repairNotes: notes);
  }
}
