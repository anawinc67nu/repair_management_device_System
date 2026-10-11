import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL บน Render (ตัด /api ออกเพื่อให้เรียก path ได้ชัดเจน)
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

  // 4. ช่างปิดงาน/อัปเดตสถานะ (R5 - แจ้งเตือนเข้า LINE ผู้แจ้งอัตโนมัติ)
  static Future<bool> completeTicket(int ticketId, String actionNote) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets/$ticketId/status'),
        headers: _headers,
        body: jsonEncode({
          'status': 'completed',
          'action_note': actionNote,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Complete Ticket Error: $e');
      return false;
    }
  }

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