import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL บน Render
  static const String baseUrl = 'https://repair-device-api.onrender.com/api';

  // Header มาตรฐาน
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ==========================================
  // ระบบสมาชิก & เข้าสู่ระบบ (Auth)
  // ==========================================

  // เข้าสู่ระบบ (Login)
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Login Error: $e');
    }
    return null;
  }

  // สมัครสมาชิกผู้ใช้งานทั่วไป (Register User)
  static Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Register User Error: $e');
    }
    return null;
  }

  // สมัครสมาชิกเจ้าหน้าที่ช่าง (Register Staff)
  static Future<Map<String, dynamic>?> registerStaff({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-staff'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Register Staff Error: $e');
    }
    return null;
  }

  // ==========================================
  // ระบบสถานที่ & อุปกรณ์ (Equipments & Locations)
  // ==========================================

  // 1. สแกน QR Code ค้นหาอุปกรณ์รายชิ้น (เช่น PC-SC2-307-01)
  static Future<Map<String, dynamic>?> scanEquipment(String deviceCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/equipments/scan/$deviceCode'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Scan Error: $e');
    }
    return null;
  }

  // 1.1 สแกน QR Code ประจำห้องเพื่อดึงรายการอุปกรณ์ทั้งหมดในห้อง (เช่น SC2-307)
  static Future<Map<String, dynamic>?> getRoomEquipments(String roomCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations/room/$roomCode'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Get Room Equipments Error: $e');
    }
    return null;
  }

  // ==========================================
  // ระบบการแจ้งซ่อม (Tickets)
  // ==========================================

  // 2. เช็กการแจ้งซ่อมซ้ำ (R2)
  static Future<Map<String, dynamic>?> checkDuplicate(int deviceId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets/check-duplicate?device_id=$deviceId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Check Duplicate Error: $e');
    }
    return null;
  }

  // 3. ส่งฟอร์มแจ้งซ่อมใหม่ (R1 - แจ้งเตือนเข้า LINE ช่างอัตโนมัติ)
  static Future<bool> createTicket({
    required int deviceId,
    required String description,
    int reporterId = 1,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: _headers,
        body: jsonEncode({
          'device_id': deviceId,
          'reporter_id': reporterId,
          'description': description,
          'image_url': imageUrl,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create Ticket Error: $e');
      return false;
    }
  }

  // 4. ดึงรายการแจ้งซ่อมทั้งหมด (สำหรับช่าง/แอดมิน)
  static Future<List<dynamic>?> getTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('tickets')) {
          return data['tickets'];
        }
      }
    } catch (e) {
      print('Get Tickets Error: $e');
    }
    return null;
  }

  // 4.1 ดึงรายการแจ้งซ่อมตาม ID ผู้ใช้ (สำหรับหน้า "ประวัติของฉัน")
  static Future<List<dynamic>?> getUserTickets(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/user/$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('tickets')) {
          return data['tickets'];
        }
      }
    } catch (e) {
      print('Get User Tickets Error: $e');
    }
    return null;
  }

  // 4.2 ช่างอัปเดตเฉพาะสถานะงาน (เช่น 'in_progress', 'pending')
  static Future<bool> updateTicketStatus(int ticketId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets/$ticketId/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Ticket Status Error: $e');
      return false;
    }
  }

  // 4.3 ช่างบันทึกผลการซ่อมพร้อมเปลี่ยนสถานะ
  static Future<bool> saveRepairAction(int ticketId, String status, String actionNote) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets/$ticketId/status'),
        headers: _headers,
        body: jsonEncode({
          'status': status,
          'action_note': actionNote,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Save Repair Action Error: $e');
      return false;
    }
  }

  // 4.4 ช่างปิดงานซ่อม (R5 - สำเร็จและยิงเตือนเข้า LINE ผู้แจ้ง)
  static Future<bool> completeTicket(int ticketId, String actionNote) async {
    return saveRepairAction(ticketId, 'completed', actionNote);
  }

  // ==========================================
  // แดชบอร์ดสรุปผล (Dashboard)
  // ==========================================

  // 5. สถิติ Dashboard สำหรับแอดมิน (R3)
  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/dashboard-stats'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Dashboard Stats Error: $e');
    }
    return null;
  }
}