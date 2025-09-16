
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../helpers/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _exportAllData() async {
    try {
      final bytes = await DatabaseHelper.instance.exportDatabase();
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'لطفا محل ذخیره فایل پشتیبان را انتخاب کنید:',
        fileName: 'PoultryApp_Backup_${DateTime.now().toIso8601String().substring(0, 10)}.db',
        bytes: bytes,
      );

      if (outputFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('پشتیبان‌گیری با موفقیت انجام شد.'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'بستن',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('عملیات پشتیبان‌گیری لغو شد.'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'بستن',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پشتیبان‌گیری: $e'),
            backgroundColor: Colors.redAccent.shade200,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'بستن',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('تایید بازیابی داده‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'داده‌های فایل پشتیبان با داده‌های فعلی ادغام می‌شوند. '
              'دوره‌های با نام مشابه جایگزین شده و سایر دوره‌ها حفظ می‌شوند. '
              'آیا مطمئن هستید؟',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'انصراف',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('تایید', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await DatabaseHelper.instance.importDatabase(bytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('داده‌ها با موفقیت بازیابی شدند.'),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'بستن',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
            Navigator.of(context).pop(true);
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('هیچ فایلی انتخاب نشد.'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'بستن',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بازیابی داده‌ها: $e'),
            backgroundColor: Colors.redAccent.shade200,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'بستن',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedCycles() async {
    // بدون تغییر، چون در کد اصلی پیاده‌سازی نشده
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('این قابلیت هنوز پیاده‌سازی نشده است.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'بستن',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تنظیمات و پشتیبان‌گیری',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'مدیریت داده‌ها',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _exportAllData,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.green.shade500,
                      child: const Icon(Icons.upload_file, color: Colors.white, size: 20),
                    ),
                    title: const Text(
                      'پشتیبان‌گیری کامل',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'ذخیره تمام داده‌های برنامه در یک فایل .db',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _importData,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade500,
                      child: const Icon(Icons.download, color: Colors.white, size: 20),
                    ),
                    title: const Text(
                      'بازیابی داده‌ها',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'ادغام داده‌ها از فایل پشتیبان با حفظ داده‌های فعلی',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _exportSelectedCycles,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
