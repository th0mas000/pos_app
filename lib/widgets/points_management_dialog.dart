import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/membership_provider.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';

class PointsManagementDialog extends StatefulWidget {
  final Customer customer;

  const PointsManagementDialog({
    super.key,
    required this.customer,
  });

  @override
  State<PointsManagementDialog> createState() => _PointsManagementDialogState();
}

class _PointsManagementDialogState extends State<PointsManagementDialog> {
  final _pointsController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isAddingPoints = true; // true = เพิ่มแต้ม, false = ลดแต้ม

  @override
  void dispose() {
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handlePoints() async {
    final pointsText = _pointsController.text.trim();
    if (pointsText.isEmpty) return;

    final points = double.tryParse(pointsText);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกจำนวนแต้มที่ถูกต้อง'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // ตรวจสอบแต้มไม่เพียงพอสำหรับการลดแต้ม
    if (!_isAddingPoints && widget.customer.points < points) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('แต้มไม่เพียงพอสำหรับการหักแต้ม'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final membershipProvider = context.read<MembershipProvider>();
      final reason = _reasonController.text.trim();
      
      if (_isAddingPoints) {
        // เพิ่มแต้ม
        await membershipProvider.addPoints(
          widget.customer.id, 
          points,
          description: reason.isEmpty ? 'เพิ่มแต้มจากผู้ดูแล' : reason,
        );
      } else {
        // ลดแต้ม โดยใช้ adjustPoints เพื่อให้สามารถลดแต้มได้
        await membershipProvider.adjustPoints(
          widget.customer.id, 
          -points, // ใช้ค่าลบเพื่อลดแต้ม
          reason.isEmpty ? 'ลดแต้มจากผู้ดูแล' : reason,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAddingPoints ? 'เพิ่มแต้มสำเร็จ' : 'ลดแต้มสำเร็จ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('จัดการแต้ม - ${widget.customer.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current points
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'แต้มปัจจุบัน: ${widget.customer.points.toStringAsFixed(0)} แต้ม',
                          style: AppTheme.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (widget.customer.lifetimePoints > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'แต้มรวม: ${widget.customer.lifetimePoints.toStringAsFixed(0)} แต้ม',
                            style: AppTheme.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            // เลือกประเภทการจัดการแต้ม
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAddingPoints = true;
                          _pointsController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isAddingPoints ? AppTheme.successColor : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7),
                            bottomLeft: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: _isAddingPoints ? Colors.white : AppTheme.successColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'เพิ่มแต้ม',
                              style: TextStyle(
                                color: _isAddingPoints ? Colors.white : AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAddingPoints = false;
                          _pointsController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isAddingPoints ? AppTheme.errorColor : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove,
                              color: !_isAddingPoints ? Colors.white : AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ลดแต้ม',
                              style: TextStyle(
                                color: !_isAddingPoints ? Colors.white : AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // ระบบการใช้แต้มถูกยกเลิกแล้ว - เฉพาะการเพิ่มแต้ม
            
            // Points input
            TextField(
              controller: _pointsController,
              decoration: InputDecoration(
                labelText: _isAddingPoints ? 'จำนวนแต้มที่จะเพิ่ม' : 'จำนวนแต้มที่จะลด',
                hintText: '0',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  _isAddingPoints ? Icons.add : Icons.remove,
                  color: _isAddingPoints ? AppTheme.successColor : AppTheme.errorColor,
                ),
                helperText: !_isAddingPoints 
                    ? 'แต้มปัจจุบัน: ${widget.customer.points.toStringAsFixed(0)} แต้ม'
                    : null,
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Reason input
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'เหตุผล (ไม่บังคับ)',
                hintText: 'ระบุเหตุผลในการปรับแต้ม',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            
            // ระบบการใช้แต้มถูกยกเลิกแล้ว - ไม่แสดงข้อมูลการใช้แต้ม
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handlePoints,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAddingPoints ? AppTheme.successColor : AppTheme.errorColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isAddingPoints ? 'เพิ่มแต้ม' : 'ลดแต้ม'),
        ),
      ],
    );
  }
}
