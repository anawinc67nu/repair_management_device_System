import 'package:flutter/material.dart';
import '../services/login_services.dart';
import '../../staff_tickets/screens/ticket_list_screen.dart';
import '../../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    // 1. ตรวจสอบข้อมูลก่อนส่ง
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. เรียกใช้งาน API จริงจาก ApiService ที่คุณสร้างไว้
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // 3. ป้องกันปัญหา Async Gap (เช็คว่า Widget ยังอยู่บนจอไหมหลังรอ Response)
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 4. ถ้าผลลัพธ์เป็น null แสดงว่า Login ไม่ผ่าน (รหัสผิด หรือเชื่อมต่อไม่ได้)
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
        );
        return;
      }

      // 5. แกะข้อมูล Role จาก Response ของ API
      // (ปรับ Key ให้ตรงกับโครงสร้าง JSON จริงฝั่ง Backend ของคุณ เช่น result['role'] หรือ result['user']['role'])
      final userData = result['user'] ?? result;
      final role = userData['role'];

      // (ทางเลือกเสริม) หากคุณต้องการเก็บบันทึก Token ไว้ใช้ต่อในหน้าอื่น
      // final token = result['token'];
      // TODO: บันทึก token ลง SharedPreferences หรือ SecureStorage

      // 6. นำทางไปยังหน้าตามบทบาท
      final destination = (role == 'staff' || role == 'admin')
          ? const TicketListScreen() // หน้าของช่าง/เจ้าหน้าที่
          : const UserHomeScreen(); // หน้าของผู้ใช้งานทั่วไป

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Repair Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เข้าสู่ระบบเพื่อใช้งาน',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'อีเมล',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('เข้าสู่ระบบ'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'บัญชีสำหรับทดลอง\n'
                    'User: user@test.com / 123456\n'
                    'Staff: staff@test.com / 123456',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// หน้าชั่วคราวสำหรับทดสอบการนำทาง
// ภายหลังเปลี่ยนเป็นหน้าจริงของแต่ละบทบาทได้
class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: const Center(
        child: Text('หน้าหลักเจ้าหน้าที่', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: const Center(
        child: Text('หน้าหลักผู้ใช้', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}
