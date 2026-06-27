import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../helpers/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isImporting = false; // ← وضعیت لودینگ
  bool _isExporting = false; // ← وضعیت لودینگ export

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

  // ── نمایش دیالوگ لودینگ ─────────────────────────────────────
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // کاربر نمی‌تواند ببندد
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // جلوگیری از بستن با دکمه back
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'لطفاً صبر کنید...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── پشتیبان‌گیری ─────────────────────────────────────────────
  Future<void> _exportAllData() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      _showLoadingDialog('در حال آماده‌سازی فایل پشتیبان...');
      final bytes = await DatabaseHelper.instance.exportDatabase();
      if (mounted) Navigator.of(context).pop(); // بستن لودینگ

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'لطفا محل ذخیره فایل پشتیبان را انتخاب کنید:',
        fileName:
            'PoultryApp_Backup_${DateTime.now().toIso8601String().substring(0, 10)}.db',
        bytes: bytes,
      );

      if (!mounted) return;

      if (outputFile != null) {
        _showSnackBar('پشتیبان‌گیری با موفقیت انجام شد.', Colors.green.shade600);
      } else {
        _showSnackBar('عملیات پشتیبان‌گیری لغو شد.', Colors.orange.shade600);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // بستن لودینگ در صورت خطا
      if (mounted) {
        _showSnackBar('خطا در پشتیبان‌گیری: $e', Colors.redAccent.shade200,
            duration: 4);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── بازیابی داده‌ها ───────────────────────────────────────────
  Future<void> _importData() async {
    if (_isImporting) return;

    try {
      // انتخاب فایل
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        if (mounted) {
          _showSnackBar('هیچ فایلی انتخاب نشد.', Colors.orange.shade600);
        }
        return;
      }

      final bytes = result.files.single.bytes!;

      // دیالوگ تأیید
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('تایید بازیابی داده‌ها',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'داده‌های فایل پشتیبان با داده‌های فعلی ادغام می‌شوند.\n'
            'دوره‌های با نام مشابه جایگزین شده و سایر دوره‌ها حفظ می‌شوند.\n\n'
            'آیا مطمئن هستید؟',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'انصراف',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('تایید',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      // ── شروع لودینگ ────────────────────────────────────────
      setState(() => _isImporting = true);
      _showLoadingDialog('در حال بازیابی داده‌ها...');

      await DatabaseHelper.instance.importDatabase(bytes);

      // بستن دیالوگ لودینگ
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        // نمایش پیام موفقیت
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                const Text('بازیابی موفق',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'داده‌ها با موفقیت بازیابی شدند.\nبرنامه به صفحه اصلی بازمی‌گردد.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('باشه',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (mounted) Navigator.of(context).pop(true); // برگشت به صفحه اصلی
      }
    } catch (e) {
      // بستن لودینگ در صورت خطا
      if (mounted && _isImporting) Navigator.of(context).pop();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              children: [
                Icon(Icons.error_outline,
                    color: Colors.redAccent.shade200, size: 24),
                const SizedBox(width: 8),
                const Text('خطا در بازیابی',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'متأسفانه بازیابی داده‌ها با خطا مواجه شد:\n\n$e',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('بستن',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _exportSelectedCycles() async {
    if (mounted) {
      _showSnackBar(
          'این قابلیت هنوز پیاده‌سازی نشده است.', Colors.orange.shade600);
    }
  }

  // ── SnackBar کمکی ────────────────────────────────────────────
  void _showSnackBar(String message, Color color, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: Duration(seconds: duration),
        action: SnackBarAction(
          label: 'بستن',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تنظیمات و پشتیبان‌گیری',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF388E3C),
                Color(0xFF66BB6A)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: Stack(
        children: [
          ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

              // ── پشتیبان‌گیری کامل ─────────────────────────
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve:
                      const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isExporting ? null : _exportAllData,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE8F5E9),
                            Color(0xFFC8E6C9)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.green.shade500,
                          child: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file,
                                  color: Colors.white, size: 20),
                        ),
                        title: const Text(
                          'پشتیبان‌گیری کامل',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        subtitle: Text(
                          _isExporting
                              ? 'در حال آماده‌سازی...'
                              : 'ذخیره تمام داده‌های برنامه در یک فایل .db',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── بازیابی داده‌ها ───────────────────────────
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve:
                      const Interval(0.2, 0.7, curve: Curves.easeOut),
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isImporting ? null : _importData,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE3F2FD),
                            Color(0xFFBBDEFB)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue.shade500,
                          child: _isImporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.download,
                                  color: Colors.white, size: 20),
                        ),
                        title: const Text(
                          'بازیابی داده‌ها',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        subtitle: Text(
                          _isImporting
                              ? 'در حال بازیابی داده‌ها...'
                              : 'ادغام داده‌ها از فایل پشتیبان با حفظ داده‌های فعلی',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),             
            ],
          ),
        ],
      ),
    );
  }
}