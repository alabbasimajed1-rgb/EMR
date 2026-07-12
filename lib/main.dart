import 'package:flutter/material.dart';
// سيتم استدعاء شاشاتك من هنا لاحقاً

void main() {
  // التأكد من تهيئة التطبيق قبل التشغيل
  WidgetsFlutterBinding.ensureInitialized();
  
  // لاحظ: تم حذف Firebase.initializeApp() تماماً
  
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
      ),
      // سنقوم بربطه بشاشة تسجيل الدخول أو الشاشة الرئيسية لاحقاً
      home: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
      ),
    );
  }
}
