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