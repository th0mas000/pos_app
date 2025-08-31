import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/membership_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/membership_form_dialog.dart';
import '../widgets/points_management_dialog.dart';

class MembershipCard extends StatelessWidget {
  final Customer member;

  const MembershipCard({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMemberAvatar(),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: AppTheme.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (member.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            member.phone!,
                            style: AppTheme.caption.copyWith(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('แก้ไขข้อมูล'),
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
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 8),
                      Text('ประวัติการใช้แต้ม'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('ลบสมาชิก', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        
        // แต้มสะสม
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '${member.points.toStringAsFixed(0)} แต้ม',
                style: AppTheme.caption.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (member.lifetimePoints > 0) ...[
                Text(
                  'รวม ${member.lifetimePoints.toStringAsFixed(0)}',
                  style: AppTheme.caption.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: AppTheme.spacing8),
        
        // วันที่เป็นสมาชิก
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'สมาชิกตั้งแต่: ${_formatDate(member.membershipStartDate ?? member.createdAt)}',
              style: AppTheme.caption.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(BuildContext context, String action) {
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    
    switch (action) {
      case 'edit':
        _editMember(context);
        break;
      case 'points':
        _managePoints(context);
        break;
      case 'history':
        _showPointsHistory(context);
        break;
      case 'delete':
        _deleteMember(context, membershipProvider);
        break;
    }
  }

  void _editMember(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MembershipFormDialog(member: member),
    );
  }

  void _managePoints(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PointsManagementDialog(customer: member),
    );
  }

  void _showPointsHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ประวัติการทำรายการแต้ม',
                      style: AppTheme.heading3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<PointsTransaction>>(
                  future: Provider.of<MembershipProvider>(context, listen: false)
                      .getMemberPointsHistory(member.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                      );
                    }
                    
                    final transactions = snapshot.data ?? [];
                    
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Text('ไม่มีประวัติการทำรายการ'),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return ListTile(
                          leading: Icon(
                            _getTransactionIcon(transaction.type),
                            color: transaction.pointsAmount >= 0 ? Colors.green : Colors.red,
                          ),
                          title: Text(transaction.description ?? transaction.type),
                          subtitle: Text(_formatDate(transaction.transactionDate)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${transaction.pointsAmount >= 0 ? '+' : ''}${transaction.pointsAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: transaction.pointsAmount >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'คงเหลือ: ${transaction.pointsBalance.toStringAsFixed(0)}',
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'earn':
        return Icons.add_circle;
      case 'redeem':
        return Icons.remove_circle;
      case 'bonus':
        return Icons.card_giftcard;
      case 'expired':
        return Icons.access_time;
      case 'adjustment':
        return Icons.edit;
      default:
        return Icons.fiber_manual_record;
    }
  }

  void _deleteMember(BuildContext context, MembershipProvider membershipProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันการลบสมาชิก'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบสมาชิก "${member.name}" หรือไม่?'),
            const SizedBox(height: 12),
            if (member.points > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'สมาชิกนี้มีแต้มคงเหลือ ${member.points.toStringAsFixed(0)} แต้ม',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'หมายเหตุ: การลบจะทำให้ข้อมูลสมาชิกถูกซ่อนออกจากระบบ และสามารถกู้คืนได้ในภายหลัง',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.of(context).pop();
                
                // แสดง loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('กำลังลบสมาชิก...'),
                      ],
                    ),
                  ),
                );
                
                await membershipProvider.deleteMember(member.id);
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // ปิด loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ลบสมาชิก "${member.name}" เรียบร้อยแล้ว'),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'เข้าใจแล้ว',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // ปิด loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาดในการลบสมาชิก: $e'),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'ลองใหม่',
                        textColor: Colors.white,
                        onPressed: () => _deleteMember(context, membershipProvider),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบสมาชิก'),
          ),
        ],
      ),
    );
  }
}