enum RepairStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
}

class RepairTicket {
  final String id;
  final String title;
  final String description;
  final String customerName;
  final String deviceName;
  final DateTime createdAt;
  final RepairStatus status;
  final String? assignedStaff;
  final String repairNotes;

  const RepairTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.customerName,
    required this.deviceName,
    required this.createdAt,
    this.status = RepairStatus.pending,
    this.assignedStaff,
    this.repairNotes = '',
  });

  // แก้ไขตรงนี้: เปลี่ยนเป็น Factory Constructor สำหรับแปลง JSON
  factory RepairTicket.fromJson(Map<String, dynamic> json) {
    return RepairTicket(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['description'] ?? 'ไม่มีหัวข้อ',
      description: json['description'] ?? '',
      customerName: json['reporter']?['name'] ?? json['customerName'] ?? 'ไม่ระบุชื่อ',
      deviceName: json['device']?['name'] ?? json['deviceName'] ?? 'ไม่ระบุอุปกรณ์',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      status: _parseStatus(json['status']),
      assignedStaff: json['assigned_staff'] ?? json['assignedStaff'],
      repairNotes: json['action_note'] ?? json['repairNotes'] ?? '',
    );
  }

  // ฟังก์ชันช่วยแปลงข้อความสถานะจาก Backend ให้เป็น Enum
  static RepairStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'accepted':
        return RepairStatus.accepted;
      case 'in_progress':
      case 'inProgress':
        return RepairStatus.inProgress;
      case 'completed':
        return RepairStatus.completed;
      case 'cancelled':
        return RepairStatus.cancelled;
      case 'pending':
      default:
        return RepairStatus.pending;
    }
  }

  RepairTicket copyWith({
    RepairStatus? status,
    String? assignedStaff,
    String? repairNotes,
  }) {
    return RepairTicket(
      id: id,
      title: title,
      description: description,
      customerName: customerName,
      deviceName: deviceName,
      createdAt: createdAt,
      status: status ?? this.status,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      repairNotes: repairNotes ?? this.repairNotes,
    );
  }
}