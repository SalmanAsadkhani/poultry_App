// lib/screens/income_list_screen.dart (کد کامل درآمد، اصلاح‌شده)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helpers/database_helper.dart';
import '../../models/income.dart';
import 'add_edit_income_screen.dart';

class IncomeListScreen extends StatefulWidget {
  final int cycleId;
  final String category;

  const IncomeListScreen({super.key, required this.cycleId, required this.category});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  bool _isLoading = true;
  List<Income> _incomes = [];
  double _categoryTotal = 0.0;
  int _totalQuantity = 0;
  double _totalWeight = 0.0;
  double _overallAverageWeight = 0.0;
  final formatter = NumberFormat.decimalPattern('en_us');

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    setState(() => _isLoading = true);
    try {
      final incomes = await DatabaseHelper.instance.getIncomesForCycle(widget.cycleId, category: widget.category);
      _categoryTotal = incomes.fold(0.0, (sum, income) => sum + (income.totalPrice ?? 0.0));
      if (widget.category == 'فروش مرغ') {
        _totalQuantity = incomes.fold(0, (sum, i) => sum + (i.quantity ?? 0));
        _totalWeight = incomes.fold(0.0, (sum, i) => sum + (i.weight ?? 0.0)); // مدیریت null با ?? 0.0
        _overallAverageWeight = _totalQuantity > 0 ? _totalWeight / _totalQuantity : 0.0;
      }
      if (mounted) {
        setState(() {
          _incomes = incomes..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('خطا در لود درآمدها: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAndAddIncome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditIncomeScreen(cycleId: widget.cycleId, category: widget.category),
      ),
    );
    if (result == true) {
      _loadIncomes();
    }
  }

  void _navigateAndEditIncome(Income income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditIncomeScreen(
          cycleId: widget.cycleId,
          category: widget.category,
          income: income,
        ),
      ),
    );
    if (result == true) {
      _loadIncomes();
    }
  }

  Future<void> _deleteIncome(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید حذف'),
        content: const Text('آیا از حذف این درآمد مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteIncome(id);
      _loadIncomes();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'فروش مرغ':
        return Icons.kebab_dining;
      case 'فروش کود':
        return Icons.compost;
      default:
        return Icons.monetization_on;
    }
  }

  String _formatQuantity(num qty) {
    if (qty.truncateToDouble() == qty) {
      return qty.toInt().toString();
    } else {
      return qty.toStringAsFixed(2);
    }
  }

  Widget _buildSummaryCard(String label, String value) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Card(
      color: Color.fromARGB(255, 240, 248, 245),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: primaryColor, fontSize: 14)),
            Text(value, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showIncomeDetails(Income income) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        double averageWeight = 0;
        if (widget.category == 'فروش مرغ' && (income.quantity ?? 0) > 0 && (income.weight ?? 0) > 0) {
          averageWeight = (income.weight ?? 0) / (income.quantity ?? 1); // مدیریت null با ?? 0 و ?? 1
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(income.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: primaryColor)),
              const Divider(height: 24),
              if (income.quantity != null && income.quantity! > 0)
                _buildInfoRow('تعداد:', _formatQuantity(income.quantity!), primaryColor),
              if (income.weight != null && income.weight! > 0)
                _buildInfoRow('وزن کل:', '${_formatQuantity(income.weight!)} کیلوگرم', primaryColor),
              if (averageWeight > 0)
                _buildInfoRow('میانگین وزن:', '${averageWeight.toStringAsFixed(3)} کیلوگرم', primaryColor),
              _buildInfoRow('قیمت واحد:', income.unitPrice != null ? '${formatter.format(income.unitPrice!)} تومان' : 'ثبت نشده', primaryColor),
              _buildInfoRow('مبلغ کل:', '${formatter.format(income.totalPrice ?? 0)} تومان', primaryColor, isBold: true),
              if (income.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                const Text('توضیحات:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(income.description ?? 'ثبت نشده است.'),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('ویرایش'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateAndEditIncome(income);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteIncome(income.id!);
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Scaffold(
      appBar: AppBar(
        title: Text('درآمدهای ${widget.category}'),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 5, 141, 96)))
          : RefreshIndicator(
              onRefresh: _loadIncomes,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.category == 'فروش مرغ') ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Color.fromARGB(255, 240, 248, 245),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('خلاصه آمار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard('تعداد کل فروش', formatter.format(_totalQuantity))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard('مجموع کل وزن', _formatQuantity(_totalWeight))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard('میانگین کل وزن', _overallAverageWeight.toStringAsFixed(3))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Color.fromARGB(255, 240, 248, 245),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('جمع کل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'جمع کل: ${formatter.format(_categoryTotal)} تومان',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_incomes.isEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Color.fromARGB(255, 240, 248, 245),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: primaryColor.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text('هیچ درآمدی در این دسته ثبت نشده است.', style: TextStyle(fontSize: 16, color: primaryColor.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._incomes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final income = entry.value;
                      // محاسبه میانگین وزن برای هر آیتم
                      double averageWeight = 0;
                      if (widget.category == 'فروش مرغ' && (income.quantity ?? 0) > 0 && (income.weight ?? 0) > 0) {
                        averageWeight = (income.weight ?? 0) / (income.quantity ?? 1); // مدیریت null
                      }

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Color.fromARGB(255, 240, 248, 245),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.2),
                            child: Text('#${index + 1}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(income.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (income.quantity != null && income.quantity! > 0)
                              if(widget.category == 'فروش مرغ')
                                Text('تعداد مرغ: ${_formatQuantity(income.quantity!)} ', style: TextStyle(color: Colors.grey[700])),
                              
                              if (income.weight != null && income.weight! > 0)
                                if(widget.category != 'فروش مرغ')
                                  Text('تعداد: ${_formatQuantity(income.weight!)}', style: TextStyle(color: Colors.grey[700])),
                                 
                              if(widget.category != 'فروش مرغ')
                               Text('مبلغ کل: ${formatter.format(income.totalPrice ?? 0)} تومان', style: TextStyle(color: Colors.grey[700])),

                              if (averageWeight > 0)
                                Text('میانگین وزن: ${averageWeight.toStringAsFixed(3)} کیلوگرم', style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            _showIncomeDetails(income);
                          },
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddIncome,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'افزودن درآمد جدید',
      ),
    );
  }
}