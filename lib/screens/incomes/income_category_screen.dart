// lib/screens/income_category_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helpers/database_helper.dart';
import 'income_list_screen.dart';

class IncomeCategoryScreen extends StatefulWidget {
  final int cycleId;
  final int remainingChicks;
  const IncomeCategoryScreen({super.key, required this.cycleId , required this.remainingChicks});

  @override
  State<IncomeCategoryScreen> createState() => _IncomeCategoryScreenState();
}

class _IncomeCategoryScreenState extends State<IncomeCategoryScreen> {
  bool _isLoading = true;
  double _grandTotal = 0.0; 
  final Map<String, double> _categoryTotals = {
    'فروش مرغ': 0.0,
    'فروش کود': 0.0,
    'متفرقه': 0.0,
  };

  final List<String> _categories = const ['فروش مرغ', 'فروش کود', 'متفرقه'];
  final formatter = NumberFormat.decimalPattern('en_us');

  @override
  void initState() {
    super.initState();
    _loadIncomeSummary();
  }

  Future<void> _loadIncomeSummary() async {
    setState(() => _isLoading = true);
    try {
      final allIncomes = await DatabaseHelper.instance.getIncomesForCycle(widget.cycleId);

      _grandTotal = 0.0;
      _categoryTotals.updateAll((key, value) => 0.0);

      for (var income in allIncomes) {
        final price = income.totalPrice;
        _grandTotal += price;
        if (_categoryTotals.containsKey(income.category)) {
          _categoryTotals[income.category] = _categoryTotals[income.category]! + price;
        }
      }
    } catch (e) {
      debugPrint("Error loading income summary: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری درآمدها: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateAndRefresh(String category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeListScreen(cycleId: widget.cycleId, category: category , remainingChicks: widget.remainingChicks,),
      ),
    );
    _loadIncomeSummary();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncomeSummary,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Color.fromARGB(255, 240, 248, 245),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'جمع کل درآمدها (تومان)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatter.format(_grandTotal),
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._categories.map((category) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Color.fromARGB(255, 240, 248, 245),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                        subtitle: Text('${formatter.format(_categoryTotals[category] ?? 0.0)} تومان', style: TextStyle(color: Colors.grey[700])),
                        trailing: FilledButton(
                          onPressed: () => _navigateAndRefresh(category),
                          style: FilledButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('مشاهده جزئیات', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}