// lib/screens/income_list_screen.dart

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
  
  // متغیرهای State برای کارت‌های خلاصه
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
      
      _categoryTotal = incomes.fold(0.0, (sum, i) => sum + i.totalPrice);
      _totalQuantity = incomes.fold(0, (sum, i) => sum + (i.quantity ?? 0));
      _totalWeight = incomes.fold(0.0, (sum, i) => sum + (i.weight ?? 0.0));
      if (_totalQuantity > 0 && _totalWeight > 0) {
        _overallAverageWeight = _totalWeight / _totalQuantity;
      } else {
        _overallAverageWeight = 0.0;
      }
      
      if (mounted) {
        setState(() { _incomes = incomes; _isLoading = false; });
      }
    } catch(e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  void _navigateAndAddIncome() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditIncomeScreen(cycleId: widget.cycleId, category: widget.category)));
    if (result == true) _loadIncomes();
  }

  void _navigateAndEditIncome(Income income) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditIncomeScreen(cycleId: widget.cycleId, category: widget.category, income: income)));
    if (result == true) _loadIncomes();
  }

  Future<void> _deleteIncome(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('تایید حذف'), content: const Text('آیا از حذف این درآمد مطمئن هستید؟'), actions: [ TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))]));
    if(confirm == true) {
      await DatabaseHelper.instance.deleteIncome(id);
      _loadIncomes();
    }
  }
  
  String _formatQuantity(num? qty) {
    if (qty == null) return '0';
    if (qty is int || qty.truncateToDouble() == qty) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Scaffold(
      appBar: AppBar(
        title: Text('درآمدهای ${widget.category}'),
        backgroundColor: primaryColor,
        elevation: 5,
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
                      
                      // ✅✅✅ ۱. محاسبه میانگین وزن برای هر آیتم ✅✅✅
                      double averageWeight = 0;
                      if (widget.category == 'فروش مرغ' && (income.quantity ?? 0) > 0 && (income.weight ?? 0) > 0) {
                        averageWeight = income.weight! / income.quantity!;
                      }

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Color.fromARGB(255, 240, 248, 245),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.2),
                            child: Text('#${index + 1}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(income.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                          subtitle: Text("مبلغ کل: ${formatter.format(income.totalPrice)} تومان", style: TextStyle(color: primaryColor.withOpacity(0.7))),
                          trailing: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 5, 141, 96)),
                          childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
                          children: [
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 8),

                            // ✅✅✅ ۲. نمایش هوشمند و کامل جزئیات ✅✅✅
                            if (income.quantity != null && income.quantity! > 0)
                              _buildInfoRow('تعداد:', _formatQuantity(income.quantity)),
                            if (income.weight != null && income.weight! > 0)
                              _buildInfoRow('وزن کل:', '${_formatQuantity(income.weight)} کیلوگرم'),
                            if (averageWeight > 0)
                              _buildInfoRow('میانگین وزن:', '${averageWeight.toStringAsFixed(3)} کیلوگرم'),
                            
                            _buildInfoRow('قیمت واحد:', income.unitPrice != null ? '${formatter.format(income.unitPrice)} تومان' : 'ثبت نشده'),
                            
                            const Divider(height: 20, color: Colors.grey),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('ویرایش'),
                                  onPressed: () => _navigateAndEditIncome(income),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                                  label: Text('حذف', style: const TextStyle(color: Colors.red)),
                                  onPressed: () => _deleteIncome(income.id!),
                                ),
                              ],
                            )
                          ],
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

  Widget _buildSummaryCard(String title, String value) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: primaryColor.withOpacity(0.7)), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: primaryColor.withOpacity(0.7))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: primaryColor)),
        ],
      ),
    );
  }
}