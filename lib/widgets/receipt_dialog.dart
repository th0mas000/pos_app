import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';

class ReceiptDialog extends StatelessWidget {
  final Sale sale;
  final Customer? customer;
  final double pointsUsed;
  final double pointsEarned;

  const ReceiptDialog({
    super.key,
    required this.sale,
    this.customer,
    this.pointsUsed = 0.0,
    this.pointsEarned = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing16),
            _buildReceiptContent(),
            const SizedBox(height: AppTheme.spacing24),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.receipt_long,
          size: 32,
          color: AppTheme.successColor,
        ),
        const SizedBox(width: AppTheme.spacing12),
        const Text(
          'ใบเสร็จรับเงิน',
          style: AppTheme.heading2,
        ),
      ],
    );
  }

  Widget _buildReceiptContent() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShopInfo(),
          const Divider(),
          _buildSaleInfo(),
          if (customer != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            _buildCustomerInfo(),
          ],
          const SizedBox(height: AppTheme.spacing16),
          _buildItemsSection(),
          const Divider(),
          _buildSummarySection(),
          if (pointsUsed > 0 || pointsEarned > 0) ...[
            const SizedBox(height: AppTheme.spacing8),
            _buildPointsInfo(),
          ],
          const Divider(),
          _buildPaymentInfo(),
        ],
      ),
    );
  }

  Widget _buildShopInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ร้านค้าของฉัน',
          style: AppTheme.heading3,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppTheme.spacing4),
        Text(
          'ที่อยู่ร้านค้า',
          style: AppTheme.body,
          textAlign: TextAlign.center,
        ),
        Text(
          'โทร: 0812345678',
          style: AppTheme.body,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSaleInfo() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Column(
      children: [
        _buildInfoRow('เลขที่', sale.saleNumber),
        _buildInfoRow('วันที่', dateFormat.format(sale.saleDate)),
        _buildInfoRow('แคชเชียร์', 'ผู้ดูแลระบบ'), // TODO: Get actual user name
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body),
          Text(value, style: AppTheme.body),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return FutureBuilder<List<SaleItem>>(
      future: _getSaleItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('รายการสินค้า', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing8),
            ...items.map((item) => _buildItemRow(item)),
          ],
        );
      },
    );
  }

  Widget _buildItemRow(SaleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.productName,
              style: AppTheme.body,
            ),
          ),
          Expanded(
            child: Text(
              '${item.quantity}',
              style: AppTheme.body,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '฿${item.unitPrice.toStringAsFixed(2)}',
              style: AppTheme.body,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '฿${item.totalPrice.toStringAsFixed(2)}',
              style: AppTheme.body,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        _buildSummaryRow('รวมย่อย', sale.subtotal),
        if (sale.discountAmount > 0)
          _buildSummaryRow('ส่วนลด', -sale.discountAmount),
        _buildSummaryRow('ภาษี', sale.taxAmount),
        const SizedBox(height: AppTheme.spacing8),
        _buildSummaryRow('รวมทั้งสิ้น', sale.total, isTotal: true),
      ],
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
              ? AppTheme.heading3.copyWith(fontWeight: FontWeight.bold)
              : AppTheme.body,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final changeAmount = sale.paidAmount - sale.total;
    
    return Column(
      children: [
        _buildInfoRow('วิธีชำระ', _getPaymentMethodText(sale.paymentMethod)),
        _buildInfoRow('เงินที่รับ', '฿${sale.paidAmount.toStringAsFixed(2)}'),
        _buildInfoRow('เงินทอน', '฿${changeAmount.toStringAsFixed(2)}'),
      ],
    );
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cash':
        return 'เงินสด';
      case 'transfer':
        return 'โอน';
      case 'qr':
        return 'QR Code';
      default:
        return method;
    }
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('การพิมพ์จะพัฒนาในอนาคต')),
              );
            },
            child: const Text('พิมพ์'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    if (customer == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลลูกค้า',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text('ชื่อ: ${customer!.name}', style: AppTheme.body),
          if (customer!.phone != null)
            Text('เบอร์: ${customer!.phone}', style: AppTheme.body),
        ],
      ),
    );
  }

  Widget _buildPointsInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Colors.orange, size: 20),
              SizedBox(width: 4),
              Text(
                'คะแนนสะสม',
                style: AppTheme.heading3,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          if (pointsUsed > 0) ...[
            Text(
              'คะแนนที่ใช้: ${pointsUsed.toStringAsFixed(0)} คะแนน',
              style: AppTheme.body.copyWith(color: Colors.red),
            ),
          ],
          if (pointsEarned > 0) ...[
            Text(
              'คะแนนที่ได้รับ: +${pointsEarned.toStringAsFixed(0)} คะแนน',
              style: AppTheme.body.copyWith(color: Colors.green),
            ),
          ],
          if (customer != null) ...[
            const SizedBox(height: AppTheme.spacing4),
            Text(
              'คะแนนคงเหลือ: ${(customer!.points - pointsUsed + pointsEarned).toStringAsFixed(0)} คะแนน',
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<List<SaleItem>> _getSaleItems() async {
    // This is a placeholder - in a real app, you would get this from the context
    // For now, return empty list
    return [];
  }
}
