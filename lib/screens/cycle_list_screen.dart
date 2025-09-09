import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/breeding_cycle.dart';
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

  void _refreshCyclesList() {
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
    bool hasData = false;
    try {
      hasData = await DatabaseHelper.instance.hasRelatedData(cycle.id!);
    } catch (_) {
      hasData = false;
    }

    if (hasData) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای این دوره اطلاعاتی ثبت شده؛ حذف مجاز نیست.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دوره'),
        content: Text('آیا از حذف «${cycle.name}» مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm != true) return;

    final rows = await DatabaseHelper.instance.deleteCycle(cycle.id!);
    if (!mounted) return;

    if (rows > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دوره با موفقیت حذف شد.')),
      );
      _refreshCyclesList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حذف انجام نشد. دوباره تلاش کنید.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوره‌های پرورش'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('افزودن دوره'),
              onPressed: _navigateToAddCycle,
            ),
          )
        ],
      ),
      body: FutureBuilder<List<BreedingCycle>>(
        future: _cyclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطا در بارگذاری داده‌ها: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'هنوز هیچ دوره‌ای ثبت نشده است.\nیک دوره جدید اضافه کنید!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final cycles = snapshot.data!;
          return ListView.builder(
            itemCount: cycles.length,
            itemBuilder: (context, index) {
              final cycle = cycles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(cycle.id.toString())),
                  title: Text(cycle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('تاریخ شروع: ${cycle.formattedStartDate}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          cycle.isActive ? 'فعال' : 'بایگانی',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: cycle.isActive ? Colors.green : Colors.grey,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _navigateToEditCycle(cycle);
                          } else if (value == 'delete') {
                            await _deleteCycle(cycle);
                          }
                        },
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
          );
        },
      ),
    );
  }
}
