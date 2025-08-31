import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_grid.dart';
import '../../widgets/cart_panel.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/multiple_barcode_scanner.dart';
import '../../utils/responsive_utils.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Use responsive utilities instead of hardcoded breakpoint
    final isWideScreen = ResponsiveUtils.shouldUseWideLayout(context);
    final showScannerButton = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text('${cart.itemCount} รายการ'),
                  backgroundColor: cart.itemCount > 0 
                    ? AppTheme.successColor 
                    : Colors.grey.shade200,
                ),
              );
            },
          ),
        ],
      ),
      body: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
      // เพิ่มปุ่มสแกนบาร์โค้ดที่มุมขวาล่าง
      floatingActionButton: showScannerButton 
        ? FloatingActionButton(
            onPressed: _scanBarcodeMultiple,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'สแกนบาร์โค้ด',
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildProductSection(),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: CartPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(child: _buildProductSection()),
        Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.items.isEmpty) return const SizedBox.shrink();
            
            return Container(
              height: 80,
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${cart.itemCount} รายการ',
                          style: AppTheme.body,
                        ),
                        Text(
                          '฿${cart.total.toStringAsFixed(2)}',
                          style: AppTheme.heading3.copyWith(
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showCartBottomSheet();
                    },
                    child: const Text('ดูตะกร้า'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductSection() {
    return Column(
      children: [
        Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'ค้นหาสินค้า...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        CategoryTabs(
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (categoryId) {
            setState(() {
              _selectedCategoryId = categoryId;
            });
          },
        ),
        Expanded(
          child: ProductGrid(
            categoryId: _selectedCategoryId,
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CartPanel(scrollController: scrollController),
        ),
      ),
    );
  }

  Future<void> _scanBarcodeMultiple() async {
    try {
      // เปิดหน้าสแกนบาร์โค้ดแบบต่อเนื่อง
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => MultipleBarcodeScanner(
            onProductScanned: (product) async {
              // เพิ่มสินค้าลงในตะกร้าทันที
              final success = await Provider.of<CartProvider>(context, listen: false).addItem(product);
              
              // แสดงข้อความแจ้งเตือน
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'เพิ่ม ${product.name} ลงในตะกร้าแล้ว'
                        : 'ไม่สามารถเพิ่ม ${product.name} ได้ (สต็อกไม่เพียงพอ)',
                    ),
                    backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
              return success;
            },
          ),
        ),
      );
    } catch (e) {
      // แสดงข้อความเมื่อเกิดข้อผิดพลาด
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
