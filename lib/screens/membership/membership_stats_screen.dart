import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/membership_provider.dart';
import '../../database/database.dart';
import '../../theme/app_theme.dart';

class MembershipStatsScreen extends StatefulWidget {
  const MembershipStatsScreen({super.key});

  @override
  State<MembershipStatsScreen> createState() => _MembershipStatsScreenState();
}

class _MembershipStatsScreenState extends State<MembershipStatsScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
      final stats = await membershipProvider.getMembershipStats();
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติระบบสมาชิก'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MembershipProvider>(
              builder: (context, membershipProvider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallStats(),
                      const SizedBox(height: AppTheme.spacing24),
                      _buildTierStats(membershipProvider),
                      const SizedBox(height: AppTheme.spacing24),
                      _buildTopMembers(membershipProvider),
                      const SizedBox(height: AppTheme.spacing24),
                      _buildBirthdayMembers(membershipProvider),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOverallStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('สถิติรวม', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacing12,
              mainAxisSpacing: AppTheme.spacing12,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'สมาชิกทั้งหมด',
                  (_stats['totalMembers'] ?? 0).toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  'สมาชิกที่ใช้งาน',
                  (_stats['activeMembers'] ?? 0).toString(),
                  Icons.person_outline,
                  AppTheme.successColor,
                ),
                _buildStatCard(
                  'แต้มรวมทั้งหมด',
                  (_stats['totalPoints'] ?? 0.0).toStringAsFixed(0),
                  Icons.stars,
                  Colors.orange,
                ),
                _buildStatCard(
                  'แต้มเฉลี่ย',
                  (_stats['averagePoints'] ?? 0.0).toStringAsFixed(1),
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTierStats(MembershipProvider membershipProvider) {
    // ลบระบบระดับสมาชิก - ไม่แสดงสถิติตามระดับอีกต่อไป
    return const SizedBox.shrink();
  }

  Widget _buildTopMembers(MembershipProvider membershipProvider) {
    final topMembers = membershipProvider.getTopMembers(limit: 5);
    
    if (topMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text('สมาชิกยอดนิยม (Top 5)', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            ...topMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              // ลบระดับสมาชิก - ไม่ต้องดึงข้อมูล tier อีกต่อไป
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text(member.phone ?? 'ไม่มีเบอร์โทร'), // แสดงเบอร์โทรแทนระดับสมาชิก
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${member.lifetimePoints.toStringAsFixed(0)} แต้ม',
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'คงเหลือ: ${member.points.toStringAsFixed(0)}',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayMembers(MembershipProvider membershipProvider) {
    final birthdayMembers = membershipProvider.getBirthdayMembers();
    
    if (birthdayMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cake, color: Colors.pink),
                SizedBox(width: 8),
                Text('สมาชิกที่มีวันเกิดในเดือนนี้', style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (birthdayMembers.isEmpty)
              const Center(
                child: Text(
                  'ไม่มีสมาชิกที่มีวันเกิดในเดือนนี้',
                  style: AppTheme.body,
                ),
              )
            else
              ...birthdayMembers.map((member) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.pink,
                      child: Icon(
                        Icons.cake,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: member.birthDate != null
                        ? Text('วันเกิด: ${member.birthDate!.day}/${member.birthDate!.month}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.card_giftcard, color: Colors.pink),
                      onPressed: () => _showBirthdayBonusDialog(member),
                      tooltip: 'ให้โบนัสวันเกิด',
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // ทอง
      case 1:
        return Colors.grey; // เงิน
      case 2:
        return Colors.brown; // ทองแดง
      default:
        return AppTheme.primaryColor;
    }
  }

  void _showBirthdayBonusDialog(Customer member) {
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    final settings = membershipProvider.settings;
    
    if (settings?.enableBirthdayBonus != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ระบบโบนัสวันเกิดยังไม่เปิดใช้งาน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cake, color: Colors.pink),
            SizedBox(width: 8),
            Text('โบนัสวันเกิด'),
          ],
        ),
        content: Text(
          'ให้โบนัสวันเกิด ${settings!.birthdayBonusPoints.toStringAsFixed(0)} แต้ม '
          'แก่ ${member.name} หรือไม่?',
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
                
                await membershipProvider.addPoints(
                  member.id,
                  settings.birthdayBonusPoints,
                  description: 'โบนัสวันเกิด',
                  notes: 'โบนัสพิเศษสำหรับวันเกิด',
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ให้โบนัสวันเกิด ${settings.birthdayBonusPoints.toStringAsFixed(0)} แต้ม '
                        'แก่ ${member.name} เรียบร้อยแล้ว',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('ให้โบนัส'),
          ),
        ],
      ),
    );
  }
}
