// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/cycles/cycle_list_screen.dart';
import 'helpers/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
      ],
      locale: const Locale('fa', 'IR'),

      // ✅✅✅ تغییر اصلی اینجاست ✅✅✅
      theme: ThemeData(
        fontFamily: 'Vazir',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        
        // استایل سراسری برای تمام فیلدهای متنی در برنامه
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          // این گزینه باعث می‌شود لیبل همیشه بالای فیلد باشد و تداخل ایجاد نکند
          floatingLabelBehavior: FloatingLabelBehavior.always, 
          // کمی فاصله داخلی برای زیبایی بیشتر
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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