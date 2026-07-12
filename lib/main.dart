import 'package:flutter/material.dart';
import 'screens/login.screen.dart'; // تأكد أن الاسم يطابق اسم ملفك في مجلد screens

void main() {
  // التأكد من تهيئة التطبيق قبل التشغيل
  WidgetsFlutterBinding.ensureInitialized();
  
  // تشغيل التطبيق
  runApp(const EMRApp());
}

class EMRApp extends StatelessWidget {
  const EMRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMR App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A8A),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
      ),
      // توجيه التطبيق للبدء من شاشة تسجيل الدخول (القفل)
      home: const LoginScreen(), 
    );
  }
}
