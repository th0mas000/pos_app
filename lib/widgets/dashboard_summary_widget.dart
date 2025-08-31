import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class DashboardSummaryWidget extends StatefulWidget {
  const DashboardSummaryWidget({super.key});

  @override
  State<DashboardSummaryWidget> createState() => _DashboardSummaryWidgetState();
}

class _DashboardSummaryWidgetState extends State<DashboardSummaryWidget> {
  bool _isLoading = true;
  double _todaySales = 0.0;
  double _monthSales = 0.0;
  int _todayTransactions = 0;
  int _lowStockProducts = 0;
  int _outOfStockProducts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      // ยอดขายวันนี้
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final todaySales = await (database.select(database.sales)
            ..where((sale) => sale.createdAt.isBiggerOrEqualValue(startOfDay) & 
                              sale.createdAt.isSmallerThanValue(endOfDay)))
          .get();

      double todayTotal = 0.0;
      for (final sale in todaySales) {
        todayTotal += sale.total;
      }

      // ยอดขายเดือนนี้
      final startOfMonth = DateTime(today.year, today.month, 1);
      final endOfMonth = DateTime(today.year, today.month + 1, 1);
      
      final monthSales = await (database.select(database.sales)
            ..where((sale) => sale.createdAt.isBiggerOrEqualValue(startOfMonth) & 
                              sale.createdAt.isSmallerThanValue(endOfMonth)))
          .get();

      double monthTotal = 0.0;
      for (final sale in monthSales) {
        monthTotal += sale.total;
      }

      // สต็อกสินค้า
      final products = await database.select(database.products).get();
      int lowStock = 0;
      int outOfStock = 0;
      
      for (final product in products) {
        if (product.stock <= 0) {
          outOfStock++;
        } else if (product.stock <= 5) {
          lowStock++;
        }
      }

      setState(() {
        _todaySales = todayTotal;
        _monthSales = monthTotal;
        _todayTransactions = todaySales.length;
        _lowStockProducts = lowStock;
        _outOfStockProducts = outOfStock;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
  Text(
    'สรุปข้อมูลรวดเร็ว',
    style: AppTheme.heading2.copyWith(fontSize: 20), // เปลี่ยน 28 เป็นขนาดที่ต้องการ
  ),
  TextButton.icon(
    onPressed: _loadDashboardData,
    icon: const Icon(Icons.refresh, size: 16),
    label: const Text(''),
  ),
],
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            // Sales Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'ยอดขายวันนี้',
                    '฿${NumberFormat('#,##0.00').format(_todaySales)}',
                    '$_todayTransactions รายการ',
                    Icons.today,
                    AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildSummaryItem(
                    'ยอดขายเดือนนี้',
                    '฿${NumberFormat('#,##0.00').format(_monthSales)}',
                    'เดือน ${DateTime.now().month}/${DateTime.now().year}',
                    Icons.calendar_month,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Inventory Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'สต็อกน้อย',
                    '$_lowStockProducts',
                    'สินค้า',
                    Icons.warning,
                    AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildSummaryItem(
                    'หมดสต็อก',
                    '$_outOfStockProducts',
                    'สินค้า',
                    Icons.error,
                    AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.caption.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppTheme.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
