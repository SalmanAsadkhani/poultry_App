// lib/screens/expense_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helpers/database_helper.dart';
import '../../models/expense.dart';
import 'add_edit_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final int cycleId;
  final String category;

  const ExpenseListScreen({super.key, required this.cycleId, required this.category});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  bool _isLoading = true;
  List<Expense> _expenses = [];
  double _categoryTotal = 0.0;
  final formatter = NumberFormat.decimalPattern('en_us');

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final expenses = await DatabaseHelper.instance.getExpensesForCycle(widget.cycleId, category: widget.category);
    _categoryTotal = expenses.fold(0.0, (sum, expense) => sum + expense.totalPrice);
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    }
  }
  
  void _navigateAndAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(cycleId: widget.cycleId, category: widget.category),
      ),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  void _navigateAndEditExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(
          cycleId: widget.cycleId,
          category: widget.category,
          expense: expense,
        ),
      ),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید حذف'),
        content: const Text('آیا از حذف این هزینه مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if(confirm == true) {
      await DatabaseHelper.instance.deleteExpense(id);
      _loadExpenses();
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'دان':
        return Icons.grain;
      case 'داروخانه':
        return Icons.local_pharmacy_outlined;
      case 'متفرقه':
        return Icons.inventory_2_outlined;
      default:
        return Icons.monetization_on;
    }
  }

  String _formatQuantity(num qty) {
    if (qty.truncateToDouble() == qty) {
      return qty.toInt().toString();
    } else {
      return qty.toString();
    }
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(expense.title, style: Theme.of(context).textTheme.headlineSmall),
              const Divider(height: 24),
              if (widget.category == 'دان') ...[
                _buildInfoRow('تعداد کیسه:', _formatQuantity(expense.bagCount ?? 0)),
                _buildInfoRow('وزن کل:', '${_formatQuantity(expense.weight ?? 0)} کیلوگرم'),
              ] else ...[
                 _buildInfoRow('تعداد:', _formatQuantity(expense.quantity)),
              ],
              _buildInfoRow(widget.category == 'دان' ? 'قیمت هر کیلو:' : 'قیمت واحد:', 
                expense.unitPrice != null ? '${formatter.format(expense.unitPrice)} تومان' : 'ثبت نشده'
              ),
              _buildInfoRow('قیمت کل:', '${formatter.format(expense.totalPrice)} تومان', isBold: true),
              const SizedBox(height: 12),
              const Text('توضیحات:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(expense.description != null && expense.description!.isNotEmpty ? expense.description! : 'ثبت نشده است.'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('ویرایش'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateAndEditExpense(expense);
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
                        _deleteExpense(expense.id!);
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Scaffold(
      appBar: AppBar(
        title: Text('هزینه‌های ${widget.category}'),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 240, 248, 245),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5),
                    ],
                  ),
                  child: Text(
                    'جمع کل: ${formatter.format(_categoryTotal)} تومان',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(child: Text('هیچ هزینه‌ای ثبت نشده است.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 80.0),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.2),
                                  child: Icon(_getCategoryIcon(widget.category), color: primaryColor),
                                ),
                                title: Text(expense.title, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.category == 'دان') ...[
                                      Text('تعداد: ${_formatQuantity(expense.bagCount ?? 0)} کیسه', style: TextStyle(color: Colors.grey[700])),
                                      if (expense.weight != null)
                                        Text('وزن: ${_formatQuantity(expense.weight!)} کیلوگرم', style: TextStyle(color: Colors.grey[700])),
                                    ] else ...[
                                      Text('تعداد: ${_formatQuantity(expense.quantity)}', style: TextStyle(color: Colors.grey[700])),
                                      Text('قیمت کل: ${formatter.format(expense.totalPrice)} تومان', style: TextStyle(color: Colors.grey[700])),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  _showExpenseDetails(expense);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddExpense,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'افزودن هزینه جدید',
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.black)),
        ],
      ),
    );
  }
}