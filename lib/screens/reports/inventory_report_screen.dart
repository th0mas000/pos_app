import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, low_stock, out_of_stock, in_stock
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      final products = await (database.select(database.products)
            ..orderBy([(product) => drift.OrderingTerm.asc(product.name)]))
          .get();

      setState(() {
        _products = products;
        _applyFilters();
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

  void _applyFilters() {
    List<Product> filtered = _products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) => 
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
      ).toList();
    }

    // Filter by stock status
    switch (_filterStatus) {
      case 'low_stock':
        filtered = filtered.where((product) => 
          product.stock <= 5 && product.stock > 0
        ).toList();
        break;
      case 'out_of_stock':
        filtered = filtered.where((product) => product.stock <= 0).toList();
        break;
      case 'in_stock':
        filtered = filtered.where((product) => 
          product.stock > 5
        ).toList();
        break;
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _filterStatus = filter;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานสต็อกสินค้า'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'ค้นหาสินค้า',
                    hintText: 'ชื่อสินค้าหรือบาร์โค้ด',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: AppTheme.spacing12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'ทั้งหมด', Icons.inventory),
                      const SizedBox(width: AppTheme.spacing8),
                      _buildFilterChip('in_stock', 'มีสต็อก', Icons.check_circle),
                      const SizedBox(width: AppTheme.spacing8),
                      _buildFilterChip('low_stock', 'สต็อกน้อย', Icons.warning),
                      const SizedBox(width: AppTheme.spacing8),
                      _buildFilterChip('out_of_stock', 'หมดสต็อก', Icons.error),
                    ],
                  ),
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
                      'ทั้งหมด',
                      '${_products.length}',
                      Icons.inventory,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: _buildSummaryCard(
                      'สต็อกน้อย',
                      '${_products.where((p) => p.stock <= 5 && p.stock > 0).length}',
                      Icons.warning,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: _buildSummaryCard(
                      'หมดสต็อก',
                      '${_products.where((p) => p.stock <= 0).length}',
                      Icons.error,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'ไม่พบสินค้าที่ค้นหา'
                                  : 'ไม่มีสินค้าในหมวดหมู่ที่เลือก',
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
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => _onFilterChanged(value),
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

  Widget _buildProductCard(Product product) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (product.stock <= 0) {
      statusColor = AppTheme.errorColor;
      statusText = 'หมดสต็อก';
      statusIcon = Icons.error;
    } else if (product.stock <= 5) {
      statusColor = AppTheme.warningColor;
      statusText = 'สต็อกน้อย';
      statusIcon = Icons.warning;
    } else {
      statusColor = AppTheme.successColor;
      statusText = 'มีสต็อก';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            // Product Image Placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.inventory, color: Colors.grey),
            ),
            const SizedBox(width: AppTheme.spacing12),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  if (product.barcode != null)
                    Text(
                      'บาร์โค้ด: ${product.barcode}',
                      style: AppTheme.caption,
                    ),
                  Text(
                    'ราคา: ฿${NumberFormat('#,##0.00').format(product.price)}',
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stock Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.stock}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  'คงเหลือ',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
