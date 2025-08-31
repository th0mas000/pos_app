import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/membership_provider.dart';
import '../../database/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/quick_add_customer_dialog.dart';
import '../../widgets/promptpay_qr_widget.dart';
import '../../utils/responsive_utils.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _paidAmountController = TextEditingController();
  String _paymentMethod = 'cash';
  Customer? _selectedCustomer;
  // ระบบการใช้แต้มถูกยกเลิกแล้ว - เก็บเฉพาะการให้แต้ม
  double _pointsToEarn = 0.0;
  String? _promptPayId;
  
  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    _calculatePointsToEarn(cart.total);
    _updatePaidAmount();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  void _calculatePointsToEarn(double total) {
    // ใช้แต้มจากสินค้าแทนการคำนวณจากยอดเงิน
    final cart = Provider.of<CartProvider>(context, listen: false);
    _pointsToEarn = cart.totalPointsEarned;
  }

  void _updatePaidAmount() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    // ไม่มีส่วนลดจากคะแนนแล้ว
    _paidAmountController.text = cart.total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // Use responsive layout for better landscape experience
          if (ResponsiveUtils.shouldUseWideLayout(context)) {
            return _buildWideLayout(cart);
          } else {
            return _buildNarrowLayout(cart);
          }
        },
      ),
    );
  }

  Widget _buildWideLayout(CartProvider cart) {
    return Row(
      children: [
        // Left side - Order summary and customer info
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderSummary(cart),
                const SizedBox(height: AppTheme.spacing24),
                _buildCustomerSection(),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right side - Payment information
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPaymentMethodSection(cart),
                const SizedBox(height: AppTheme.spacing24),
                if (_paymentMethod == 'cash') _buildPaymentAmount(cart),
                if (_paymentMethod == 'cash') const SizedBox(height: AppTheme.spacing24),
                if (_paymentMethod == 'qr') _buildQRPaymentSection(cart),
                if (_paymentMethod == 'qr') const SizedBox(height: AppTheme.spacing24),
                if (_paymentMethod == 'cash') _buildChangeAmount(cart),
                if (_paymentMethod == 'cash') const SizedBox(height: AppTheme.spacing24),
                _buildCheckoutButtons(cart),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(CartProvider cart) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderSummary(cart),
          const SizedBox(height: AppTheme.spacing24),
          _buildCustomerSection(),
          const SizedBox(height: AppTheme.spacing24),
          _buildPaymentMethodSection(cart),
          const SizedBox(height: AppTheme.spacing24),
          if (_paymentMethod == 'cash') _buildPaymentAmount(cart),
          if (_paymentMethod == 'cash') const SizedBox(height: AppTheme.spacing24),
          if (_paymentMethod == 'qr') _buildQRPaymentSection(cart),
          if (_paymentMethod == 'qr') const SizedBox(height: AppTheme.spacing24),
          if (_paymentMethod == 'cash') _buildChangeAmount(cart),
          if (_paymentMethod == 'cash') const SizedBox(height: AppTheme.spacing24),
          _buildCheckoutButtons(cart),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สรุปรายการ',
              style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${item.quantity}x '),
                      Expanded(child: Text(item.productName)),
                      Text('฿${(item.unitPrice * item.quantity).toStringAsFixed(2)}'),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            _buildSummaryRow('รวมย่อย', cart.subtotal),
            if (cart.totalDiscount > 0)
              _buildSummaryRow('ส่วนลด', -cart.totalDiscount, isDiscount: true),
            // ระบบการใช้แต้มถูกยกเลิกแล้ว
            _buildSummaryRow('ภาษี (${cart.vatRate.toStringAsFixed(1)}%)', cart.vatAmount),
            const Divider(),
            _buildSummaryRow('รวมทั้งสิ้น', cart.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTheme.heading3.copyWith(fontWeight: FontWeight.bold) : AppTheme.body,
          ),
          Text(
            '฿${amount.toStringAsFixed(2)}',
            style: isTotal 
              ? AppTheme.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                )
              : AppTheme.body.copyWith(
                  color: isDiscount ? AppTheme.errorColor : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
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
                  'ลูกค้า',
                  style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_selectedCustomer == null)
                  TextButton.icon(
                    onPressed: _selectCustomer,
                    icon: const Icon(Icons.person_add),
                    label: const Text('เลือกลูกค้า'),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            if (_selectedCustomer == null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey),
                    SizedBox(width: AppTheme.spacing8),
                    Text('ยังไม่ได้เลือกลูกค้า'),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            _selectedCustomer!.name.isNotEmpty 
                                ? _selectedCustomer!.name[0].toUpperCase() 
                                : 'C',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCustomer!.name,
                                style: AppTheme.heading3,
                              ),
                              if (_selectedCustomer!.phone != null)
                                Text(
                                  _selectedCustomer!.phone!,
                                  style: AppTheme.body.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _selectCustomer,
                          child: const Text('เปลี่ยน'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    
                    // คะแนนปัจจุบัน
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'คะแนนปัจจุบัน: ${_selectedCustomer!.points.toStringAsFixed(0)}',
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    
                    // ระบบการใช้แต้มถูกยกเลิกแล้ว
                    
                    // คะแนนที่จะได้รับ
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'จะได้รับคะแนน: +${_pointsToEarn.toStringAsFixed(0)}',
                            style: AppTheme.body.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacing8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCustomer = null;
                                // ระบบการใช้แต้มถูกยกเลิกแล้ว
                                _updatePaidAmount();
                              });
                            },
                            icon: const Icon(Icons.person_remove, size: 16),
                            label: const Text('ยกเลิกลูกค้า'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectCustomer() async {
    final customersProvider = Provider.of<CustomersProvider>(context, listen: false);
    await customersProvider.loadCustomers();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เลือกลูกค้า'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: customersProvider.customers.length,
                    itemBuilder: (context, index) {
                      final customer = customersProvider.customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase() 
                                : 'C',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(customer.phone ?? 'ไม่มีเบอร์โทร'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${customer.points.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCustomer = customer;
                            // ระบบการใช้แต้มถูกยกเลิกแล้ว
                            _updatePaidAmount();
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await showDialog<Customer>(
                  context: context,
                  builder: (context) => const QuickAddCustomerDialog(),
                );
                if (result != null) {
                  setState(() {
                    _selectedCustomer = result;
                    // ระบบการใช้แต้มถูกยกเลิกแล้ว
                    _updatePaidAmount();
                  });
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('เพิ่มลูกค้าใหม่'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodSection(CartProvider cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วิธีการชำระเงิน',
              style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('เงินสด'),
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                        _updatePaidAmount();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('โอนเงิน/QR'),
                    value: 'qr',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                        _updatePaidAmount();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAmount(CartProvider cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'จำนวนเงินที่รับ',
              style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _paidAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'จำนวนเงิน',
                prefixText: '฿',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRPaymentSection(CartProvider cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชำระผ่าน QR Code',
              style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Center(
              child: PromptPayQRWidget(
                amount: cart.total,
                phoneNumber: _promptPayId ?? '0123456789',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeAmount(CartProvider cart) {
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    // ไม่มีส่วนลดจากคะแนนแล้ว
    final changeAmount = paidAmount - cart.total;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: changeAmount >= 0 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เงินทอน',
                style: AppTheme.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '฿${changeAmount.toStringAsFixed(2)}',
                style: AppTheme.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: changeAmount >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          if (changeAmount < 0) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'จำนวนเงินไม่เพียงพอ',
              style: AppTheme.body.copyWith(color: AppTheme.errorColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutButtons(CartProvider cart) {
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
    // ไม่มีส่วนลดจากคะแนนแล้ว
    final canCheckout = _paymentMethod == 'qr' || paidAmount >= cart.total;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canCheckout ? () => _processCheckout(cart) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            child: Text(
              _paymentMethod == 'cash' 
                ? 'ชำระเงิน' 
                : 'ยืนยันการชำระ',
              style: AppTheme.heading3,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _showQRPaymentConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการชำระเงิน'),
        content: const Text('กรุณาตรวจสอบว่าลูกค้าได้ชำระเงินผ่าน QR Code แล้ว'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _processCheckout(CartProvider cart) async {
    try {
      final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
      // ไม่มีส่วนลดจากคะแนนแล้ว
      
      // Validation สำหรับ QR payment
      if (_paymentMethod == 'qr') {
        // สำหรับ QR payment ไม่ต้องตรวจสอบเงินทอน
        final confirmed = await _showQRPaymentConfirmation();
        if (!confirmed) return;
      } else if (_paymentMethod == 'cash') {
        // สำหรับเงินสด ตรวจสอบจำนวนเงินที่รับ
        if (paidAmount < cart.total) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('จำนวนเงินที่รับไม่เพียงพอ')),
          );
          return;
        }
      }
      
      // Process customer points if customer is selected
      if (_selectedCustomer != null) {
        final customersProvider = Provider.of<CustomersProvider>(context, listen: false);
        
        // ระบบการใช้แต้มถูกยกเลิกแล้ว - ให้เฉพาะแต้ม
        
        // Add earned points
        if (_pointsToEarn > 0) {
          await customersProvider.addPoints(_selectedCustomer!.id, _pointsToEarn);
        }
        
        // Force reload customers data to ensure UI updates
        await customersProvider.loadCustomers();
      }
      
      // Process checkout with customer ID
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      // Prepare cart items for database
      final cartItems = cart.items.map((item) => {
        'productId': item.productId,
        'name': item.productName,
        'quantity': item.quantity,
        'price': item.unitPrice,
      }).toList();
      
      // Save sale to database
      await database.completeSale(
        cartItems: cartItems,
        customerId: _selectedCustomer?.id,
        total: cart.total,
        paidAmount: paidAmount,
        paymentMethod: _paymentMethod,
        notes: _selectedCustomer != null 
          ? 'คะแนนที่ได้: $_pointsToEarn'
          : null,
      );
      
      // Clear cart
      cart.clear();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการขายเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Force reload customers data in all customer-related providers
        final customersProvider = Provider.of<CustomersProvider>(context, listen: false);
        final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
        
        // Don't wait for these to complete as user can navigate away
        customersProvider.loadCustomers();
        membershipProvider.loadMembers();
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
