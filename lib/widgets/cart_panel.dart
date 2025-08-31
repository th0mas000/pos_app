import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/shop_settings_provider.dart';
import '../theme/app_theme.dart';
import '../screens/checkout/checkout_screen.dart';

class CartPanel extends StatelessWidget {
  final ScrollController? scrollController;

  const CartPanel({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, ShopSettingsProvider>(
      builder: (context, cart, shopSettings, child) {
        if (cart.items.isEmpty) {
          return _buildEmptyCart();
        }

        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildCartItems(cart),
            ),
            _buildSummary(cart, shopSettings),
            _buildCheckoutButton(context, cart),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'ตะกร้าว่าง',
            style: AppTheme.heading3.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'เลือกสินค้าเพื่อเริ่มการขาย',
            style: AppTheme.body.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacing8),
          const Text(
            'ตะกร้าสินค้า',
            style: AppTheme.heading3,
          ),
          const Spacer(),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return TextButton(
                onPressed: cart.items.isNotEmpty ? () => cart.clear() : null,
                child: const Text('ล้างทั้งหมด'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return CartItemCard(
          item: item,
          onQuantityChanged: (quantity) async {
            final success = await cart.updateQuantity(item.productId, quantity);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ไม่สามารถเพิ่มจำนวน "${item.productName}" ได้ เนื่องจากสินค้าไม่เพียงพอในคลัง'),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          onRemove: () {
            cart.removeItem(item.productId);
          },
          onDiscountChanged: (discount) {
            cart.updateItemDiscount(item.productId, discount);
          },
        );
      },
    );
  }

  Widget _buildSummary(CartProvider cart, ShopSettingsProvider shopSettings) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow('รวมย่อย', cart.subtotal),
          if (cart.totalDiscount > 0)
            _buildSummaryRow('ส่วนลด', -cart.totalDiscount),
          _buildSummaryRow('ราคาหลังหักส่วนลด', cart.subtotalAfterDiscount),
          _buildSummaryRow('ภาษี (${shopSettings.vatRate.toStringAsFixed(1)}%)', cart.vatAmount),
          const Divider(),
          _buildPointsRow('แต้มที่จะได้รับ', cart.totalPointsEarned),
          const Divider(),
          _buildSummaryRow(
            'รวมทั้งสิ้น',
            cart.total,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTheme.heading3 : AppTheme.body,
          ),
          Text(
            '฿${amount.toStringAsFixed(2)}',
            style: isTotal 
              ? AppTheme.heading3.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                )
              : AppTheme.body,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsRow(String label, double points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.body,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${points.toStringAsFixed(1)} แต้ม',
              style: AppTheme.body.copyWith(
                color: Colors.orange[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context, CartProvider cart) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: ElevatedButton(
        onPressed: cart.items.isNotEmpty 
          ? () => _navigateToCheckout(context) 
          : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          'ชำระเงิน (฿${cart.total.toStringAsFixed(2)})',
          style: AppTheme.heading3.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final dynamic item; // CartItem
  final Future<void> Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final Function(double) onDiscountChanged;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: AppTheme.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Consumer<ShopSettingsProvider>(
                  builder: (context, shopSettings, child) {
                    final priceWithVat = shopSettings.calculatePriceWithVat(item.unitPrice);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '฿${priceWithVat.toStringAsFixed(2)}',
                          style: AppTheme.body.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (shopSettings.vatRate > 0)
                          Text(
                            'รวมภาษี ${shopSettings.vatRate.toStringAsFixed(1)}%',
                            style: AppTheme.caption.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: AppTheme.spacing8),
                Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return FutureBuilder<int>(
                      future: cart.getAvailableStock(item.productId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final stock = snapshot.data!;
                          final stockColor = stock <= 0 
                            ? AppTheme.errorColor
                            : stock <= 5 
                              ? AppTheme.warningColor 
                              : AppTheme.successColor;
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing8,
                              vertical: AppTheme.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: stockColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radius4),
                              border: Border.all(color: stockColor),
                            ),
                            child: Text(
                              'คงเหลือ: $stock',
                              style: AppTheme.caption.copyWith(
                                color: stockColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
                const Spacer(),
                _buildQuantityControls(),
              ],
            ),
            if (item.discountAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacing4),
                child: Text(
                  'ส่วนลด: -฿${item.discountAmount.toStringAsFixed(2)}',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _showDiscountDialog(context),
                  child: const Text('ส่วนลด'),
                ),
                Text(
                  '฿${item.totalPrice.toStringAsFixed(2)}',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: item.quantity > 1 
            ? () async => await onQuantityChanged(item.quantity - 1)
            : null,
          icon: const Icon(Icons.remove),
          iconSize: 16,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12,
            vertical: AppTheme.spacing4,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppTheme.radius4),
          ),
          child: Text(
            '${item.quantity}',
            style: AppTheme.body,
          ),
        ),
        IconButton(
          onPressed: () async => await onQuantityChanged(item.quantity + 1),
          icon: const Icon(Icons.add),
          iconSize: 16,
        ),
      ],
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final controller = TextEditingController(
      text: item.discountAmount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ส่วนลดสินค้า'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'จำนวนเงินส่วนลด',
            suffixText: '฿',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(controller.text) ?? 0.0;
              onDiscountChanged(discount);
              Navigator.pop(context);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}
