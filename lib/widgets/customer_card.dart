import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database.dart';
import '../../providers/customers_provider.dart';
import '../../providers/membership_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customer_form_dialog.dart';
import '../../widgets/points_management_dialog.dart';

class CustomerCard extends StatelessWidget {
  final int customerId;

  const CustomerCard({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomersProvider>(
      builder: (context, customersProvider, child) {
        // หาลูกค้าในรายการล่าสุดเพื่อให้แน่ใจว่าข้อมูลเป็นปัจจุบัน
        final customer = customersProvider.getCustomerById(customerId);
        
        if (customer == null) {
          print('CustomerCard: Customer ID $customerId not found');
          return const Card(child: Center(child: Text('Customer not found')));
        }
        
        print('CustomerCard: Displaying customer ${customer.name} with ${customer.points} points');
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: AppTheme.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (customer.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              customer.phone!,
                              style: AppTheme.caption.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, value, customer),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('แก้ไข'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'points',
                          child: Row(
                            children: [
                              Icon(Icons.stars, size: 18),
                              SizedBox(width: 8),
                              Text('จัดการแต้ม'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('ลบ', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        '${customer.points.toStringAsFixed(0)} คะแนน',
                        style: AppTheme.caption.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (customer.email != null || customer.address != null) ...[
                  const SizedBox(height: AppTheme.spacing8),
                  if (customer.email != null)
                    Text(
                      customer.email!,
                      style: AppTheme.caption.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (customer.address != null)
                    Text(
                      customer.address!,
                      style: AppTheme.caption.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
                const Spacer(),
                Text(
                  'สมาชิกตั้งแต่: ${_formatDate(customer.createdAt)}',
                  style: AppTheme.caption.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action, Customer updatedCustomer) {
    switch (action) {
      case 'edit':
        _editCustomer(context, updatedCustomer);
        break;
      case 'points':
        _managePoints(context, updatedCustomer);
        break;
      case 'delete':
        _deleteCustomer(context, updatedCustomer);
        break;
    }
  }

  void _editCustomer(BuildContext context, Customer updatedCustomer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomerFormDialog(customer: updatedCustomer),
    );
    
    if (result == true) {
      // Refresh both customers and membership data after editing
      if (context.mounted) {
        await context.read<CustomersProvider>().loadCustomers();
        await context.read<MembershipProvider>().loadMembers();
      }
    }
  }

  void _managePoints(BuildContext context, Customer updatedCustomer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PointsManagementDialog(customer: updatedCustomer),
    );
    
    if (result == true) {
      // Refresh both customers and membership data after points management
      if (context.mounted) {
        await context.read<CustomersProvider>().loadCustomers();
        await context.read<MembershipProvider>().loadMembers();
      }
    }
  }

  void _deleteCustomer(BuildContext context, Customer updatedCustomer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบลูกค้า "${updatedCustomer.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<CustomersProvider>().deleteCustomer(updatedCustomer.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ลบลูกค้าสำเร็จ'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year + 543}';
  }
}
