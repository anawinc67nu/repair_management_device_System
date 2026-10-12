import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'room_management_screen.dart';
import 'equipment_management_screen.dart';
import 'repair_management_screen.dart';
import 'my_profile_screen.dart';
import '../../staff_tickets/screens/ticket_list_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  static const Color navy = Color(0xFF172554);
  static const Color blue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF5F7FB);
  Map<String, dynamic> userData = {
    'id': '-',
    'name': 'Staff User',
    'email': '-',
    'role': 'staff',
  };
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  void _openPage(BuildContext context, int index) {
    final pages = <Widget>[
      const StaffDashboardScreen(),
      const TicketListScreen(),
      const RoomManagementScreen(),
      const EquipmentManagementScreen(),
      MyProfileScreen(user: userData),
    ];

    if (index == 0) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => pages[index]));
  }

  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _recentTickets = [];
  bool _isLoadingTickets = true;
  String? _ticketsError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadRecentTickets();
  }

  Future<void> _reloadDashboard() async {
    if (_isLoading || _isLoadingTickets) return;

    await Future.wait([_loadDashboard(), _loadRecentTickets()]);
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getDashboardStats();

      if (result == null) {
        throw Exception('ไม่สามารถโหลดข้อมูล Dashboard ได้');
      }

      final summary = result['summary'];

      if (summary is! Map) {
        throw Exception('รูปแบบข้อมูล summary ไม่ถูกต้อง');
      }

      if (!mounted) return;

      setState(() {
        _summary = Map<String, dynamic>.from(summary);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _statValue(String key) {
    if (_isLoading) return '...';
    if (_errorMessage != null) return '-';

    return (_summary?[key] ?? 0).toString();
  }

  Future<void> _loadRecentTickets() async {
    setState(() {
      _isLoadingTickets = true;
      _ticketsError = null;
    });

    try {
      final data = await ApiService.getTickets();

      if (!mounted) return;

      if (data == null) {
        setState(() {
          _ticketsError = 'โหลดรายการแจ้งซ่อมไม่สำเร็จ';
          _isLoadingTickets = false;
        });
        return;
      }

      final tickets = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      DateTime getDate(Map<String, dynamic> item) {
        return DateTime.tryParse(
              (item['created_at'] ?? item['createdAt'] ?? '').toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      tickets.sort((a, b) => getDate(b).compareTo(getDate(a)));

      setState(() {
        _recentTickets = tickets.take(3).toList();
        _isLoadingTickets = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _ticketsError = 'เกิดข้อผิดพลาดในการโหลดรายการ';
        _isLoadingTickets = false;
      });
    }
  }

  String _ticketStatus(dynamic rawStatus) {
    switch ((rawStatus ?? 'pending').toString()) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'accepted':
        return 'รับงานแล้ว';
      case 'in_progress':
        return 'กำลังซ่อม';
      case 'completed':
        return 'ซ่อมเสร็จแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return (rawStatus ?? 'ไม่ระบุสถานะ').toString();
    }
  }

  Color _ticketStatusColor(String status) {
    switch (status) {
      case 'รอดำเนินการ':
        return const Color(0xFFD97706);
      case 'รับงานแล้ว':
        return const Color.fromARGB(255, 50, 180, 255);
      case 'กำลังซ่อม':
        return const Color(0xFF7C3AED);
      case 'ซ่อมเสร็จแล้ว':
        return const Color(0xFF16A34A);
      case 'ยกเลิก':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  String _ticketDate(Map<String, dynamic> ticket) {
    final date = DateTime.tryParse(
      (ticket['created_at'] ?? ticket['createdAt'] ?? '').toString(),
    );

    if (date == null) return 'ไม่ระบุวันที่';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _ticketId(Map<String, dynamic> ticket) {
    final id = ticket['id'] ?? '-';
    return 'REP-${id.toString().padLeft(3, '0')}';
  }

  String _ticketEquipment(Map<String, dynamic> ticket) {
    return (ticket['equipment_name'] ??
            ticket['device_name'] ??
            ticket['equipment'] ??
            ticket['device_code'] ??
            'ไม่ระบุอุปกรณ์')
        .toString();
  }

  String _ticketRoom(Map<String, dynamic> ticket) {
    return (ticket['room_number'] ??
            ticket['room'] ??
            ticket['room_name'] ??
            'ไม่ระบุห้อง')
        .toString();
  }

  String _ticketDescription(Map<String, dynamic> ticket) {
    return (ticket['description'] ?? ticket['problem'] ?? 'ไม่ระบุรายละเอียด')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: background,

          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  title: const Row(
                    children: [
                      Icon(Icons.build_circle, color: navy, size: 30),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repair System',
                            style: TextStyle(
                              color: navy,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ระบบจัดการงานซ่อม',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'รีโหลดข้อมูล',
                      onPressed: (_isLoading || _isLoadingTickets)
                          ? null
                          : _reloadDashboard,
                      icon: (_isLoading || _isLoadingTickets)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, color: navy),
                    ),
                    IconButton(
                      tooltip: 'ข้อมูลผู้ใช้งาน',
                      onPressed: () => _openPage(context, 4),
                      icon: const Icon(
                        Icons.account_circle_outlined,
                        color: navy,
                        size: 28,
                      ),
                    ),
                  ],
                )
              : null,

          body: Row(
            children: [
              if (!isMobile)
                Container(
                  width: 230,
                  color: navy,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(22),
                          child: Row(
                            children: [
                              Icon(
                                Icons.build_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Repair System',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),
                        _menuItem(Icons.dashboard_outlined, 'Dashboard', true),
                        _menuItem(
                          Icons.assignment_outlined,
                          'งานแจ้งซ่อม',
                          false,
                          onTap: () => _openPage(context, 1),
                        ),
                        _menuItem(
                          Icons.meeting_room_outlined,
                          'จัดการห้อง',
                          false,
                          onTap: () => _openPage(context, 2),
                        ),
                        _menuItem(
                          Icons.devices_outlined,
                          'จัดการอุปกรณ์',
                          false,
                          onTap: () => _openPage(context, 3),
                        ),
                        _menuItem(
                          Icons.person_outline,
                          'ข้อมูลผู้ใช้งาน',
                          false,
                          onTap: () => _openPage(context, 4),
                        ),
                        const Spacer(),
                        _menuItem(
                          Icons.logout,
                          'ออกจากระบบ',
                          false,
                          onTap: () => _showLogoutDialog(context),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: Column(
                  children: [
                    if (!isMobile)
                      Container(
                        height: 76,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        color: Colors.white,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Staff Dashboard',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: navy,
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openPage(context, 4),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle,
                                      size: 36,
                                      color: navy,
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Staff User',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'เจ้าหน้าที่',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(child: _dashboardContent(context, isMobile)),
                  ],
                ),
              ),
            ],
          ),

          bottomNavigationBar: isMobile
              ? NavigationBar(
                  backgroundColor: Colors.white,
                  selectedIndex: 0,
                  indicatorColor: const Color(0xFFE3ECFF),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) => _openPage(context, index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'ภาพรวม',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.assignment_outlined),
                      label: 'งานซ่อม',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.meeting_room_outlined),
                      label: 'ห้อง',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.devices_outlined),
                      label: 'อุปกรณ์',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      label: 'โปรไฟล์',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _dashboardContent(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 400
            ? 12.0
            : width < 700
            ? 16.0
            : width < 1100
            ? 24.0
            : 28.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ภาพรวมระบบแจ้งซ่อม',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'โหลดข้อมูลไม่สำเร็จ: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton.icon(
                      onPressed: _loadDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองโหลดอีกครั้ง'),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'ตรวจสอบสถานะงานซ่อมได้ในหน้าเดียว',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 22),

                  // Summary cards: 1, 2 หรือ 4 คอลัมน์
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
                          (availableWidth - spacing * (columns - 1)) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              'งานแจ้งซ่อมทั้งหมด',
                              _statValue('total'),
                              Icons.assignment,
                              const Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              'รอดำเนินการ',
                              _statValue('pending'),
                              Icons.schedule,
                              const Color(0xFFD97706),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              'กำลังซ่อม',
                              _statValue('inProgress'),
                              Icons.build_outlined,
                              const Color(0xFF7C3AED),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              'ซ่อมเสร็จแล้ว',
                              _statValue('completed'),
                              Icons.check_circle_outline,
                              const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'รายการแจ้งซ่อมล่าสุด',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openPage(context, 1),
                        child: const Text('ดูทั้งหมด'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // มือถือใช้การ์ด ส่วนแท็บเล็ตและคอมใช้ตาราง
                  if (_isLoadingTickets)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_ticketsError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _ticketsError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          TextButton.icon(
                            onPressed: _loadRecentTickets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('ลองอีกครั้ง'),
                          ),
                        ],
                      ),
                    )
                  else if (_recentTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('ยังไม่มีรายการแจ้งซ่อม'),
                      ),
                    )
                  else if (width < 700)
                    Column(
                      children: _recentTickets.map((ticket) {
                        final status = _ticketStatus(ticket['status']);
                        final color = _ticketStatusColor(status);

                        return _repairCard(
                          _ticketId(ticket),
                          _ticketDescription(ticket),
                          _ticketRoom(ticket),
                          _ticketDate(ticket),
                          status,
                          color,
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('รหัส')),
                            DataColumn(label: Text('รายการ')),
                            DataColumn(label: Text('ห้อง')),
                            DataColumn(label: Text('วันที่')),
                            DataColumn(label: Text('สถานะ')),
                          ],
                          rows: _recentTickets.map((ticket) {
                            final status = _ticketStatus(ticket['status']);

                            return _repairRow(
                              _ticketId(ticket),
                              _ticketDescription(ticket),
                              _ticketRoom(ticket),
                              _ticketDate(ticket),
                              status,
                              _ticketStatusColor(status),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _menuItem(
    IconData icon,
    String label,
    bool selected, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF33477D) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        onTap: onTap,
      ),
    );
  }

  static Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _repairCard(
    String id,
    String title,
    String room,
    String date,
    String status,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build_outlined, color: blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$id • $room',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: blue, size: 25),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  static DataRow _repairRow(
    String id,
    String title,
    String room,
    String date,
    String status,
    Color color,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(id)),
        DataCell(Text(title)),
        DataCell(Text(room)),
        DataCell(Text(date)),
        DataCell(
          Container(
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
          ),
        ),
      ],
    );
  }
}
