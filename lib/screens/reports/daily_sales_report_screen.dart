import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class DailySalesReportScreen extends StatefulWidget {
  const DailySalesReportScreen({super.key});

  @override
  State<DailySalesReportScreen> createState() => _DailySalesReportScreenState();
}

class _DailySalesReportScreenState extends State<DailySalesReportScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Sale> _sales = [];
  bool _isLoading = true;
  double _totalSales = 0.0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadDailySales();
  }

  Future<void> _loadDailySales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      // คำนวณช่วงเวลาของวันที่เลือก
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      
      final sales = await (database.select(database.sales)
            ..where((sale) => sale.createdAt.isBiggerOrEqualValue(startOfDay) & 
                              sale.createdAt.isSmallerThanValue(endOfDay))
            ..orderBy([(sale) => drift.OrderingTerm.desc(sale.createdAt)]))
          .get();

      double total = 0.0;
      for (final sale in sales) {
        total += sale.total;
      }

      setState(() {
        _sales = sales;
        _totalSales = total;
        _totalTransactions = sales.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
      
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailySales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานยอดขายรายวัน'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      subtitle: const Text('เลือกวันที่'),
                      onTap: _selectDate,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ElevatedButton.icon(
                  onPressed: _loadDailySales,
                  icon: const Icon(Icons.refresh),
                  label: const Text('รีเฟรช'),
                ),
              ],
            ),
          ),
          
          // Summary Cards
          if (!_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'ยอดขายรวม',
                      '฿${NumberFormat('#,##0.00').format(_totalSales)}',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: _buildSummaryCard(
                      'จำนวนรายการ',
                      '$_totalTransactions รายการ',
                      Icons.receipt,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Sales List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            Text(
                              'ไม่มีข้อมูลการขายในวันที่เลือก',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        itemCount: _sales.length,
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          return _buildSaleCard(sale);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              title,
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              value,
              style: AppTheme.heading3.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            '#${sale.id}',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          '฿${NumberFormat('#,##0.00').format(sale.total)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เวลา: ${DateFormat('HH:mm:ss').format(sale.createdAt)}'),
            Text('วิธีชำระ: ${_getPaymentMethodText(sale.paymentMethod)}'),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () => _showSaleDetails(sale),
      ),
    );
  }

  String _getPaymentMethodText(String paymentMethod) {
    switch (paymentMethod) {
      case 'cash':
        return 'เงินสด';
      case 'qr':
        return 'QR Code';
      case 'transfer':
        return 'โอน';
      default:
        return 'อื่นๆ';
    }
  }

  void _showSaleDetails(Sale sale) async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    
    // ดึงรายการสินค้าในการขาย
    final saleItems = await (database.select(database.saleItems)
          ..where((item) => item.saleId.equals(sale.id)))
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียดการขาย #${sale.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('วันที่: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(sale.createdAt)}'),
              Text('วิธีชำระ: ${_getPaymentMethodText(sale.paymentMethod)}'),
              Text('ยอดรวม: ฿${NumberFormat('#,##0.00').format(sale.total)}'),
              const SizedBox(height: AppTheme.spacing16),
              const Text('รายการสินค้า:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppTheme.spacing8),
              ...saleItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${item.quantity}'),
                    ),
                    Text('฿${NumberFormat('#,##0.00').format(item.totalPrice)}'),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
