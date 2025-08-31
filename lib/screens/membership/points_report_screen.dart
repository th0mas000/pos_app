import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/membership_provider.dart';
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class PointsReportScreen extends StatefulWidget {
  const PointsReportScreen({super.key});

  @override
  State<PointsReportScreen> createState() => _PointsReportScreenState();
}

class _PointsReportScreenState extends State<PointsReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'all'; // all, earn, adjustment, redeem, expired
  List<PointsTransaction> _transactions = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final membershipProvider = context.read<MembershipProvider>();
      final allTransactions = await membershipProvider.membershipService.getAllPointsTransactions(
        startDate: _startDate,
        endDate: _endDate.add(const Duration(days: 1)), // Include end date
        type: _selectedType == 'all' ? null : _selectedType,
      );
      
      setState(() {
        _transactions = allTransactions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    
    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานการเพิ่ม/ลดแต้ม'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSummaryCards(),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('วันที่เริ่มต้น', style: AppTheme.caption),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('วันที่สิ้นสุด', style: AppTheme.caption),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Row(
          //   children: [
          //     const Text('ประเภท: ', style: AppTheme.body),
          //     Expanded(
          //       child: DropdownButton<String>(
          //         value: _selectedType,
          //         isExpanded: true,
          //         onChanged: (value) {
          //           setState(() {
          //             _selectedType = value!;
          //           });
          //           _loadTransactions();
          //         },
          //         items: const [
          //           DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
          //           DropdownMenuItem(value: 'earn', child: Text('เพิ่มแต้ม')),
          //           DropdownMenuItem(value: 'adjustment', child: Text('ปรับแต้ม')),
          //           DropdownMenuItem(value: 'redeem', child: Text('ใช้แต้ม')),
          //           DropdownMenuItem(value: 'expired', child: Text('แต้มหมดอายุ')),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_transactions.isEmpty) return const SizedBox.shrink();

    final earnedPoints = _transactions
        .where((t) => t.pointsAmount > 0)
        .fold<double>(0.0, (sum, t) => sum + t.pointsAmount);
    
    final reducedPoints = _transactions
        .where((t) => t.pointsAmount < 0)
        .fold<double>(0.0, (sum, t) => sum + t.pointsAmount.abs());
    
    final netPoints = earnedPoints - reducedPoints;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'เพิ่มแต้ม',
              '+${earnedPoints.toStringAsFixed(0)}',
              Colors.green,
              Icons.add,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: _buildSummaryCard(
              'ลดแต้ม',
              '-${reducedPoints.toStringAsFixed(0)}',
              Colors.red,
              Icons.remove,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: _buildSummaryCard(
              'สุทธิ',
              '${netPoints >= 0 ? '+' : ''}${netPoints.toStringAsFixed(0)}',
              netPoints >= 0 ? Colors.green : Colors.red,
              Icons.balance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ไม่มีรายการในช่วงเวลาที่เลือก',
              style: AppTheme.body,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(PointsTransaction transaction) {
    final isPositive = transaction.pointsAmount >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description ?? _getTransactionTypeName(transaction.type),
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ลูกค้า ID: ${transaction.customerId}',
              style: AppTheme.caption,
            ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(transaction.transactionDate),
              style: AppTheme.caption.copyWith(color: Colors.grey[600]),
            ),
            if (transaction.notes != null) ...[
              const SizedBox(height: 2),
              Text(
                'หมายเหตุ: ${transaction.notes}',
                style: AppTheme.caption.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPositive ? '+' : ''}${transaction.pointsAmount.toStringAsFixed(0)}',
              style: AppTheme.body.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'คงเหลือ: ${transaction.pointsBalance.toStringAsFixed(0)}',
              style: AppTheme.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'earn':
        return Icons.add_circle;
      case 'adjustment':
        return Icons.edit;
      case 'redeem':
        return Icons.remove_circle;
      case 'expired':
        return Icons.schedule;
      default:
        return Icons.circle;
    }
  }

  String _getTransactionTypeName(String type) {
    switch (type) {
      case 'earn':
        return 'เพิ่มแต้ม';
      case 'adjustment':
        return 'ปรับแต้ม';
      case 'redeem':
        return 'ใช้แต้ม';
      case 'expired':
        return 'แต้มหมดอายุ';
      default:
        return type;
    }
  }
}
