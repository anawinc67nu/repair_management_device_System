import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL จาก ngrok
  static const String baseUrl = 'https://repair-device-api.onrender.com/api';

  // 1. สแกน QR Code ค้นหาอุปกรณ์ (เช่น PC-SC2-307-01)
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
  static Future<bool> createTicket(int deviceId, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'description': description,
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
        headers: {'Content-Type': 'application/json'},
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