import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPinSetupMode = false; // لتحديد ما إذا كان التطبيق يطلب إنشاء رمز جديد أو تسجيل الدخول
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  // التحقق مما إذا كان هناك رمز سري محفوظ مسبقاً في الهاتف
  Future<void> _checkExistingPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('app_sec_pin');
    
    setState(() {
      if (savedPin == null || savedPin.isEmpty) {
        _isPinSetupMode = true; // لا يوجد رمز، يجب إنشاء واحد
      } else {
        _isPinSetupMode = false; // يوجد رمز، يجب إدخاله للدخول
      }
      _isLoading = false;
    });
  }

  // دالة الدخول أو إنشاء الرمز
  Future<void> _submitPin() async {
    final enteredPin = _pinController.text.trim();
    
    if (enteredPin.isEmpty || enteredPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits'), backgroundColor: Colors.orange),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (_isPinSetupMode) {
      // حفظ الرمز الجديد
      await prefs.setString('app_sec_pin', enteredPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security PIN set successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // التحقق من الرمز المحفوظ
      final savedPin = prefs.getString('app_sec_pin');
      if (enteredPin == savedPin) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN. Please try again.'), backgroundColor: Colors.red),
          );
          _pinController.clear();
        }
      }
    }
  }

  // تصميم موحد لحقل الإدخال
  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPinSetupMode ? Icons.security_rounded : Icons.lock_person_rounded, 
                  size: 70, 
                  color: const Color(0xFF1E3A8A)
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'EMR System',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                _isPinSetupMode 
                    ? 'Create a secure PIN to protect your clinic data' 
                    : 'Enter your security PIN to access the clinic',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _pinController,
                obscureText: !_isPasswordVisible,
                keyboardType: TextInputType.number, // إظهار لوحة الأرقام فقط
                maxLength: 6, // حد أقصى 6 أرقام
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: _buildInputDecoration(
                  _isPinSetupMode ? 'Create New PIN' : 'Enter PIN', 
                  Icons.password_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ).copyWith(counterText: ""), // إخفاء عداد الحروف
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 55, 
                child: ElevatedButton.icon(
                  onPressed: _submitPin,
                  icon: Icon(_isPinSetupMode ? Icons.save_rounded : Icons.login_rounded),
                  label: Text(
                    _isPinSetupMode ? 'Save PIN & Start' : 'Unlock Application', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
