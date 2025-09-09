import 'package:flutter/material.dart';
import '../models/breeding_cycle.dart';
import 'add_edit_expense_screen.dart'; // وارد کردن فرم هزینه
import 'add_edit_income_screen.dart';  // وارد کردن فرم درآمد

class CycleDashboardScreen extends StatefulWidget {
  final BreedingCycle cycle;

  const CycleDashboardScreen({super.key, required this.cycle});

  @override
  State<CycleDashboardScreen> createState() => _CycleDashboardScreenState();
}

class _CycleDashboardScreenState extends State<CycleDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cycle.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // برای نمایش بهتر در صفحه‌های کوچک
          tabs: const [
            Tab(text: 'خلاصه', icon: Icon(Icons.dashboard)),
            Tab(text: 'گزارشات', icon: Icon(Icons.article)),
            Tab(text: 'هزینه‌ها', icon: Icon(Icons.payment)),
            Tab(text: 'درآمدها', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildReportsTab(),
          // محتوای جدید برای تب هزینه‌ها با دکمه فعال
          _buildFinancialTab(
            title: 'لیست هزینه‌ها',
            buttonLabel: 'افزودن هزینه جدید',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
              );
            },
          ),
          // محتوای جدید برای تب درآمدها با دکمه فعال
          _buildFinancialTab(
            title: 'لیست درآمدها',
            buttonLabel: 'افزودن درآمد جدید',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditIncomeScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: باز کردن فرم افزودن گزارش روزانه
        },
        tooltip: 'افزودن گزارش روزانه',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ویجت‌های کمکی برای ساخت UI
  Widget _buildSummaryTab() {
     return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(
          title: 'اطلاعات کلی',
          children: [
            _buildInfoRow('سن جوجه:', '... روز'), // داده‌ها پویا خواهند شد
            _buildInfoRow('تعداد اولیه:', '${widget.cycle.chickCount} قطعه'),
            _buildInfoRow('وضعیت:', widget.cycle.isActive ? 'فعال' : 'بایگانی'),
          ],
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'خلاصه مصرف دان',
          children: [
            _buildInfoRow('پیش دان:', '... کیلوگرم'),
            _buildInfoRow('میان دان:', '... کیلوگرم'),
          ],
        ),
         const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'آمار تلفات',
          children: [
             _buildInfoRow('تلفات کل:', '... قطعه'),
             _buildInfoRow('درصد تلفات:', '... ٪'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildReportsTab() {
      return const Center(
        child: Text('لیست گزارش‌های روزانه در اینجا نمایش داده خواهد شد.'),
      );
  }

  Widget _buildSummaryCard({required String title, required List<Widget> children}) {
     return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinancialTab({
    required String title,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const Divider(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(
              child: Text('هنوز آیتمی ثبت نشده است.'),
            ),
          ),
        ],
      ),
    );
  }
}