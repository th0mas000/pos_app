import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class MonthlySalesReportScreen extends StatefulWidget {
  const MonthlySalesReportScreen({super.key});

  @override
  State<MonthlySalesReportScreen> createState() => _MonthlySalesReportScreenState();
}

class _MonthlySalesReportScreenState extends State<MonthlySalesReportScreen> {
  DateTime _selectedDate = DateTime.now();
  List<DailySummary> _dailySummaries = [];
  bool _isLoading = true;
  double _totalSales = 0.0;
  int _totalTransactions = 0;
  double _averageDailySales = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMonthlySales();
  }

  Future<void> _loadMonthlySales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      // คำนวณช่วงเวลาของเดือนที่เลือก
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)
          .subtract(const Duration(microseconds: 1));
      
      final sales = await (database.select(database.sales)
            ..where((sale) => sale.createdAt.isBiggerOrEqualValue(startOfMonth) & 
                              sale.createdAt.isSmallerThanValue(endOfMonth)))
          .get();

      // จัดกลุ่มข้อมูลตามวัน
      Map<String, DailySummary> dailyMap = {};
      
      for (final sale in sales) {
        final dateKey = DateFormat('yyyy-MM-dd').format(sale.createdAt);
        if (dailyMap.containsKey(dateKey)) {
          dailyMap[dateKey]!.totalSales += sale.total;
          dailyMap[dateKey]!.transactionCount++;
        } else {
          dailyMap[dateKey] = DailySummary(
            date: DateTime(sale.createdAt.year, sale.createdAt.month, sale.createdAt.day),
            totalSales: sale.total,
            transactionCount: 1,
          );
        }
      }

      final summaries = dailyMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      double total = 0.0;
      int transactions = 0;
      for (final summary in summaries) {
        total += summary.totalSales;
        transactions += summary.transactionCount;
      }

      setState(() {
        _dailySummaries = summaries;
        _totalSales = total;
        _totalTransactions = transactions;
        _averageDailySales = summaries.isNotEmpty ? total / summaries.length : 0.0;
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

 // Option 1: Using showDatePicker with custom configuration
Future<void> _selectMonth() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime(_selectedDate.year, _selectedDate.month),
    firstDate: DateTime(2020),
    lastDate: DateTime(DateTime.now().year, DateTime.now().month),
    locale: const Locale('th', 'TH'),
    initialDatePickerMode: DatePickerMode.year,
    selectableDayPredicate: (DateTime date) {
      // Only allow selection of the first day of each month
      return date.day == 1;
    },
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            dayStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.transparent,
            ),
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (picked != null) {
    final newDate = DateTime(picked.year, picked.month);
    if (newDate != DateTime(_selectedDate.year, _selectedDate.month)) {
      setState(() {
        _selectedDate = newDate;
      });
      _loadMonthlySales();
    }
  }
}

// Option 2: Custom Month/Year Picker Dialog (Recommended)
Future<void> _selectMonthCustom() async {
  final DateTime? picked = await showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      int selectedYear = _selectedDate.year;
      int selectedMonth = _selectedDate.month;
      
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('เลือกเดือนและปี'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year Dropdown
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(
                    DateTime.now().year - 2020 + 1,
                    (index) => DropdownMenuItem(
                      value: 2020 + index,
                      child: Text('${2020 + index}'),
                    ),
                  ),
                  onChanged: (int? newYear) {
                    if (newYear != null) {
                      setState(() {
                        selectedYear = newYear;
                        // Adjust month if current selection is in future
                        if (selectedYear == DateTime.now().year && 
                            selectedMonth > DateTime.now().month) {
                          selectedMonth = DateTime.now().month;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Month Dropdown
                DropdownButton<int>(
                  value: selectedMonth,
                  items: _getAvailableMonths(selectedYear),
                  onChanged: (int? newMonth) {
                    if (newMonth != null) {
                      setState(() {
                        selectedMonth = newMonth;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  DateTime(selectedYear, selectedMonth),
                ),
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    },
  );
  
  if (picked != null && 
      (picked.year != _selectedDate.year || picked.month != _selectedDate.month)) {
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month);
    });
    _loadMonthlySales();
  }
}

List<DropdownMenuItem<int>> _getAvailableMonths(int year) {
  final List<String> monthNames = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];
  
  int maxMonth = (year == DateTime.now().year) ? DateTime.now().month : 12;
  
  return List.generate(maxMonth, (index) {
    return DropdownMenuItem<int>(
      value: index + 1,
      child: Text(monthNames[index]),
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานยอดขายรายเดือน'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text('เดือน ${_selectedDate.month}/${_selectedDate.year}'),
                      subtitle: const Text('เลือกเดือน'),
                      onTap: _selectMonth,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ElevatedButton.icon(
                  onPressed: _loadMonthlySales,
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
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: AppTheme.spacing8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'ยอดขายเฉลี่ย/วัน',
                          '฿${NumberFormat('#,##0.00').format(_averageDailySales)}',
                          Icons.trending_up,
                          AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: _buildSummaryCard(
                          'วันที่มีการขาย',
                          '${_dailySummaries.length} วัน',
                          Icons.calendar_today,
                          AppTheme.infoColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Daily Sales List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _dailySummaries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_view_month_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            Text(
                              'ไม่มีข้อมูลการขายในเดือนที่เลือก',
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
                        itemCount: _dailySummaries.length,
                        itemBuilder: (context, index) {
                          final summary = _dailySummaries[index];
                          return _buildDailySummaryCard(summary);
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
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              title,
              style: AppTheme.caption.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              value,
              style: AppTheme.heading3.copyWith(color: color, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(DailySummary summary) {
    final percentage = _totalSales > 0 ? (summary.totalSales / _totalSales) * 100 : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(summary.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${summary.transactionCount} รายการ',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '฿${NumberFormat('#,##0.00').format(summary.totalSales)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(percentage / 100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailySummary {
  final DateTime date;
  double totalSales;
  int transactionCount;

  DailySummary({
    required this.date,
    required this.totalSales,
    required this.transactionCount,
  });
}
