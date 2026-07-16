import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart'; // تأكد أن هذا المسار صحيح لشاشة البداية لديك

void main() async {
  // هذا السطر ضروري جداً قبل قراءة SharedPreferences
  WidgetsFlutterBinding.ensureInitialized(); 
  
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language_code') ?? 'en';

  runApp(MyApp(initialLanguage: savedLanguage));
}

class MyApp extends StatefulWidget {
  final String initialLanguage;
  
  const MyApp({super.key, required this.initialLanguage});

  // هذه الدالة السحرية تسمح لنا بتغيير لغة التطبيق من أي شاشة (مثل الإعدادات)
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLanguage);
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EMR',
      locale: _locale, // <-- هنا نخبر التطبيق باللغة الحالية الديناميكية
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A8A),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0F766E),
        ),
      ),
      home: const LoginScreen(), 
    );
  }
}
