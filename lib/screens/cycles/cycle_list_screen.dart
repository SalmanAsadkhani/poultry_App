import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import 'add_edit_cycle_screen.dart';
import 'cycle_dashboard_screen.dart';
import '../settings_screen.dart';

class CycleListScreen extends StatefulWidget {
  const CycleListScreen({super.key});

  @override
  State<CycleListScreen> createState() => _CycleListScreenState();
}

class _CycleListScreenState extends State<CycleListScreen> with SingleTickerProviderStateMixin {
  late Future<List<BreedingCycle>> _cyclesFuture;
  late AnimationController _animationController;
  String _searchQuery = '';
  String _filter = 'all'; // Filter state: 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _refreshCyclesList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshCyclesList() async {
    setState(() {
      _cyclesFuture = DatabaseHelper.instance.getAllCycles();
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _navigateToAddCycle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditCycleScreen()),
    );
    if (result == true) _refreshCyclesList();
  }

  Future<void> _navigateToEditCycle(BreedingCycle cycle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditCycleScreen(cycle: cycle)),
    );
    if (result == true) _refreshCyclesList();
  }

  Future<void> _deleteCycle(BreedingCycle cycle) async {
    bool hasData = await DatabaseHelper.instance.hasRelatedData(cycle.id!);
    if (hasData) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('این دوره دارای اطلاعات ثبت‌شده است و قابل حذف نیست.'),
          backgroundColor: Colors.redAccent.shade200,
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
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('حذف دوره', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'آیا از حذف «${cycle.name}» مطمئن هستید؟',
          style: const TextStyle(fontSize: 15),
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
              backgroundColor: Colors.redAccent.shade200,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseHelper.instance.deleteCycle(cycle.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('دوره با موفقیت حذف شد.'),
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
      _refreshCyclesList();
    }
  }

  Future<void> _endCycle(BreedingCycle cycle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('پایان دوره', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'آیا از پایان دادن به «${cycle.name}» مطمئن هستید؟ '
          'پس از پایان، نمی‌توانید گزارش جدیدی برای این دوره ثبت کنید.',
          style: const TextStyle(fontSize: 15),
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
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('پایان', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseHelper.instance.endCycle(cycle.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('دوره با موفقیت به پایان رسید.'),
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
      _refreshCyclesList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دوره‌های پرورش',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
            tooltip: 'تنظیمات و پشتیبان‌گیری',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (result == true) {
                _refreshCyclesList();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجوی دوره...',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.95),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('همه'),
                      selected: _filter == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _filter = 'all';
                        });
                      },
                      selectedColor: primaryColor,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: _filter == 'all' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('فعال'),
                      selected: _filter == 'active',
                      onSelected: (selected) {
                        setState(() {
                          _filter = 'active';
                        });
                      },
                      selectedColor: primaryColor,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: _filter == 'active' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('پایان‌یافته'),
                      selected: _filter == 'inactive',
                      onSelected: (selected) {
                        setState(() {
                          _filter = 'inactive';
                        });
                      },
                      selectedColor: primaryColor,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: _filter == 'inactive' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: Colors.white,
        onRefresh: _refreshCyclesList,
        child: FutureBuilder<List<BreedingCycle>>(
          future: _cyclesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
             return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 4,
              ),
              const SizedBox(height: 12),
              Text(
                'در حال بارگذاری...',
                style: TextStyle(
                  color: theme.colorScheme.onBackground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                    const SizedBox(height: 8),
                    Text(
                      'خطا: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('تلاش مجدد'),
                      onPressed: _refreshCyclesList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'هیچ دوره‌ای ثبت نشده است.',
                      style: TextStyle(
                        color: theme.colorScheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('افزودن دوره جدید'),
                      onPressed: _navigateToAddCycle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              );
            }
            final cycles = snapshot.data!
                .where((cycle) => cycle.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .where((cycle) {
                  if (_filter == 'all') return true;
                  if (_filter == 'active') return cycle.isActive == true;
                  return cycle.isActive == false;
                })
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'دوره‌ها: ${cycles.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      Text(
                        'فعال: ${cycles.where((cycle) => cycle.isActive == true).length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: cycles.length,
                    itemBuilder: (context, index) {
                      final cycle = cycles[index];
                      final gradientColors = [
                        [const Color(0xFFFFF3E0), const Color.fromARGB(255, 5, 183, 189)],
                      ];
                      final cardGradient = cycle.isActive == true
                          ? gradientColors[index % gradientColors.length]
                          : [Colors.grey.shade200, const Color.fromARGB(255, 241, 149, 158)];
                      final now = DateTime.now();
                      final createdAt = cycle.startDateTime;
                      final canEnd = cycle.isActive == true &&
                          createdAt != null &&
                          now.difference(createdAt).inDays >= 40;
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              (index / cycles.length) * 0.4,
                              1.0,
                              curve: Curves.easeOutQuad,
                            ),
                          ),
                        ),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CycleDashboardScreen(cycle: cycle)),
                              );
                              _refreshCyclesList();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: cardGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.green.shade600,
                                  child: 
                                      Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      cycle.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cycle.isActive == true ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: cycle.isActive == true ? Colors.green.shade300 : Colors.red.shade200,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        cycle.isActive == true ? 'فعال' : 'پایان‌یافته',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cycle.isActive == true ? Colors.green.shade800 : Colors.red.shade400,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: cycle.isActive == true ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 54, 20, 2)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'شروع: ${cycle.formattedStartDate}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cycle.isActive == true ? const Color.fromARGB(255, 148, 22, 5) : const Color.fromARGB(255, 10, 150, 33),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.catching_pokemon, size: 14, color: cycle.isActive == true ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 54, 20, 2)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'جوجه: ${cycle.chickCount}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cycle.isActive == true ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 54, 20, 2),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (cycle.isActive == false && cycle.endDate != null)
                                      Row(
                                        children: [
                                          Icon(Icons.flag, size: 14, color: const Color.fromARGB(255, 192, 56, 54)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'پایان: ${cycle.formattedEndDate}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: const Color.fromARGB(255, 192, 56, 50),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Color.fromARGB(255, 156, 6, 6), size: 20),
                                  onSelected: (value) {
                                    if (value == 'edit') _navigateToEditCycle(cycle);
                                    else if (value == 'delete') _deleteCycle(cycle);
                                    else if (value == 'end' && cycle.isActive == true) _endCycle(cycle);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      enabled: cycle.isActive == true,
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18, color: cycle.isActive == true ? Colors.blue : Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            cycle.isActive == true ? 'ویرایش' : 'ویرایش (غیرفعال)',
                                            style: TextStyle(fontSize: 14, color: cycle.isActive == true ? Colors.black : Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 6),
                                          Text('حذف', style: TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    if (cycle.isActive == true)
                                      PopupMenuItem(
                                        enabled: canEnd,
                                        value: canEnd ? 'end' : null,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.flag,
                                              size: 18,
                                              color: canEnd ? Colors.orange : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              canEnd ? 'پایان دوره' : 'پایان دوره (بعد از ۴۰ روز)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: canEnd ? Colors.black : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCycle,
        backgroundColor: primaryColor,
        tooltip: 'افزودن دوره جدید',
        child: const Icon(Icons.add, size: 24, color: Colors.white),
      ),
    );
  }
}