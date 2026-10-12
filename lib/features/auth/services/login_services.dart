
class MockAuthService {
  // บัญชีจำลองสำหรับทดสอบก่อนเชื่อมต่อ Backend
  static const List<Map<String, String>> _accounts = [
    {
      'email': 'user@test.com',
      'password': '123456',
      'role': 'user',
    },
    {
      'email': 'staff@test.com',
      'password': '123456',
      'role': 'staff',
    },
  ];

  static String? login(String email, String password) {
    for (final account in _accounts) {
      if (account['email'] == email.trim().toLowerCase() &&
          account['password'] == password) {
        return account['role'];
      }
    }

    // ไม่พบบัญชีหรือรหัสผ่านไม่ถูกต้อง
    return null;
  }

}
