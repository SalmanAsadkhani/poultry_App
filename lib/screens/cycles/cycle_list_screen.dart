// lib/screens/cycle_list_screen.dart

import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import 'add_edit_cycle_screen.dart';
import 'cycle_dashboard_screen.dart';

class CycleListScreen extends StatefulWidget {
  const CycleListScreen({super.key});

  @override
  State<CycleListScreen> createState() => _CycleListScreenState();
}

class _CycleListScreenState extends State<CycleListScreen> {
  late Future<List<BreedingCycle>> _cyclesFuture;

  @override
  void initState() {
    super.initState();
    _refreshCyclesList();
  }

  // ✅ تابع async برای RefreshIndicator
  Future<void> _refreshCyclesList() async {
    setState(() {
      _cyclesFuture = DatabaseHelper.instance.getAllCycles();
    });
  }

  void _navigateToAddCycle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditCycleScreen(),
      ),
    );
    _refreshCyclesList();
  }

  Future<void> _navigateToEditCycle(BreedingCycle cycle) async {
    // پاس دادن دوره برای ویرایش
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCycleScreen(cycle: cycle),
      ),
    );
    _refreshCyclesList();
  }

  Future<void> _deleteCycle(BreedingCycle cycle) async {
    // ✅ ۱. ابتدا از دیتابیس می‌پرسیم که آیا این دوره داده‌ای دارد یا نه
    bool hasData = await DatabaseHelper.instance.hasRelatedData(cycle.id!);

    // ✅ ۲. اگر داده داشت، خطا نمایش بده و خارج شو
    if (hasData) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('این دوره دارای گزارش یا هزینه ثبت‌شده است و قابل حذف نیست.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // از ادامه عملیات جلوگیری کن
    }

    // ۳. اگر داده‌ای نداشت، روال عادی حذف را ادامه بده
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دوره'),
        content: Text('آیا از حذف «${cycle.name}» مطمئن هستید؟ این دوره هیچ داده‌ای ندارد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm != true) return;

    await DatabaseHelper.instance.deleteCycle(cycle.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دوره با موفقیت حذف شد.'), backgroundColor: Colors.green),
      );
      _refreshCyclesList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوره‌های پرورش'),
        backgroundColor: primaryColor,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('افزودن دوره', style: TextStyle(color: Colors.white)),
              onPressed: _navigateToAddCycle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<List<BreedingCycle>>(
        future: _cyclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 71, 71, 31)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Color.fromARGB(255, 240, 248, 245),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text('خطا در بارگذاری داده‌ها: ${snapshot.error}', style: TextStyle(color: primaryColor.withOpacity(0.7))),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Color.fromARGB(255, 240, 248, 245),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_outlined, size: 64, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'هنوز هیچ دوره‌ای ثبت نشده است.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: primaryColor.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'یک دوره جدید اضافه کنید!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ✅ مرتب‌سازی معکوس: جدیدترین دوره اول (شماره ۱)
          final cycles = snapshot.data!.reversed.toList();
          return RefreshIndicator(
            onRefresh: _refreshCyclesList,
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Color.fromARGB(255, 240, 248, 245),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.2),
                      child: Text((index + 1).toString(), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(cycle.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 88, 19, 19))),
                    subtitle: Text('تاریخ شروع: ${cycle.formattedStartDate}', style: TextStyle( color: const Color.fromARGB(255, 131, 81, 81).withOpacity(0.7))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(
                            cycle.isActive ? 'فعال' : 'بایگانی',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: cycle.isActive ? primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _navigateToEditCycle(cycle);
                            } else if (value == 'delete') {
                              await _deleteCycle(cycle);
                            }
                          },
                          icon: Icon(Icons.more_vert, color: primaryColor),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("ویرایش"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("حذف"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CycleDashboardScreen(cycle: cycle),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}