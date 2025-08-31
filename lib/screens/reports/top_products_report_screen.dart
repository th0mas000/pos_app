import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class TopProductsReportScreen extends StatefulWidget {
  const TopProductsReportScreen({super.key});

  @override
  State<TopProductsReportScreen> createState() => _TopProductsReportScreenState();
}

class _TopProductsReportScreenState extends State<TopProductsReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<ProductSalesData> _topProducts = [];
  bool _isLoading = true;
  String _selectedPeriod = '30 วันที่ผ่านมา';

  @override
  void initState() {
    super.initState();
    _loadTopProducts();
  }

  Future<void> _loadTopProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      
      // ดึงข้อมูลการขายในช่วงเวลาที่เลือก
      final saleItems = await (database.select(database.saleItems)
            .join([
              drift.leftOuterJoin(database.sales, database.sales.id.equalsExp(database.saleItems.saleId))
            ])
            ..where(database.sales.createdAt.isBiggerOrEqualValue(startOfDay) & 
                    database.sales.createdAt.isSmallerThanValue(endOfDay)))
          .get();

      // จัดกลุ่มข้อมูลตามสินค้า
      Map<int, ProductSalesData> productMap = {};
      
      for (final row in saleItems) {
        final saleItem = row.readTable(database.saleItems);
        
        if (productMap.containsKey(saleItem.productId)) {
          productMap[saleItem.productId]!.totalQuantity += saleItem.quantity;
          productMap[saleItem.productId]!.totalRevenue += saleItem.totalPrice;
          productMap[saleItem.productId]!.transactionCount++;
        } else {
          productMap[saleItem.productId] = ProductSalesData(
            productId: saleItem.productId,
            productName: saleItem.productName,
            totalQuantity: saleItem.quantity,
            totalRevenue: saleItem.totalPrice,
            transactionCount: 1,
            unitPrice: saleItem.unitPrice,
          );
        }
      }

      final topProducts = productMap.values.toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      setState(() {
        _topProducts = topProducts.take(20).toList(); // แสดงแค่ 20 อันดับแรก
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

  void _selectPeriod() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกช่วงเวลา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('7 วันที่ผ่านมา'),
              onTap: () {
                _setPeriod(7, '7 วันที่ผ่านมา');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 วันที่ผ่านมา'),
              onTap: () {
                _setPeriod(30, '30 วันที่ผ่านมา');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('90 วันที่ผ่านมา'),
              onTap: () {
                _setPeriod(90, '90 วันที่ผ่านมา');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('กำหนดเอง'),
              onTap: () {
                Navigator.pop(context);
                _selectCustomPeriod();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setPeriod(int days, String periodText) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(Duration(days: days));
      _selectedPeriod = periodText;
    });
    _loadTopProducts();
  }

  Future<void> _selectCustomPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}';
      });
      _loadTopProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานสินค้าขายดี'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(_selectedPeriod),
                      subtitle: const Text('ช่วงเวลา'),
                      onTap: _selectPeriod,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                ElevatedButton.icon(
                  onPressed: _loadTopProducts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('รีเฟรช'),
                ),
              ],
            ),
          ),

          // Top Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _topProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            Text(
                              'ไม่มีข้อมูลการขายในช่วงเวลาที่เลือก',
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
                        itemCount: _topProducts.length,
                        itemBuilder: (context, index) {
                          final product = _topProducts[index];
                          return _buildProductCard(product, index + 1);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductSalesData product, int rank) {
    final maxRevenue = _topProducts.isNotEmpty ? _topProducts[0].totalRevenue : 1.0;
    final percentage = (product.totalRevenue / maxRevenue) * 100;
    
    Color rankColor;
    if (rank <= 3) {
      rankColor = AppTheme.warningColor;
    } else if (rank <= 10) {
      rankColor = AppTheme.primaryColor;
    } else {
      rankColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rankColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ขายได้ ${product.totalQuantity} ชิ้น',
                          style: AppTheme.caption,
                        ),
                      ),
                      Text(
                        '${product.transactionCount} รายการ',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  // Progress bar
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            
            // Revenue
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${NumberFormat('#,##0.00').format(product.totalRevenue)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'รายได้',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSalesData {
  final int productId;
  final String productName;
  int totalQuantity;
  double totalRevenue;
  int transactionCount;
  final double unitPrice;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.transactionCount,
    required this.unitPrice,
  });
}
