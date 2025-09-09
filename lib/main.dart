
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/cycle_list_screen.dart';
import 'helpers/database_helper.dart';

void main() async {
  // اطمینان از آماده بودن Flutter bindings قبل از انجام async
  WidgetsFlutterBinding.ensureInitialized();

  // مقداردهی اولیه دیتابیس
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مدیریت مرغداری',

      // پشتیبانی از فارسی و RTL
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      locale: const Locale('fa', 'IR'),

      // Theme اصلی
      theme: ThemeData(
        fontFamily: 'Vazir', // فونت فارسی (اگر اضافه کرده‌اید)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,

        // استایل دکمه‌ها
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // استایل کارت‌ها
         cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      home: const CycleListScreen(),
    );
  }
}
