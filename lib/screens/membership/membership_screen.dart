import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/membership_provider.dart';
import '../../providers/shop_settings_provider.dart';
import '../../database/database.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/membership_form_dialog.dart';
import 'membership_settings_screen.dart';
import 'membership_stats_screen.dart';
import 'points_report_screen.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedTierId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบสมาชิก'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MembershipStatsScreen(),
                ),
              );
            },
            tooltip: 'สถิติสมาชิก',
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PointsReportScreen(),
                ),
              );
            },
            tooltip: 'รายงานแต้ม',
          ),
          // IconButton(
          //   icon: const Icon(Icons.settings),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const MembershipSettingsScreen(),
          //       ),
          //     );
          //   },
          //   tooltip: 'ตั้งค่าระบบสมาชิก',
          // ),
        ],
      ),
      body: Consumer<MembershipProvider>(
        builder: (context, membershipProvider, child) {
          if (membershipProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (membershipProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'เกิดข้อผิดพลาด: ${membershipProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => membershipProvider.loadMembers(),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final filteredMembers = _getFilteredMembers(membershipProvider);

          return Column(
            children: [
              _buildSearchAndFilter(membershipProvider),
              _buildMemberStats(membershipProvider),
              Expanded(
                child: filteredMembers.isEmpty
                    ? _buildEmptyState()
                    : Consumer<ShopSettingsProvider>(
                        builder: (context, shopSettings, child) {
                          // Get responsive configuration
                          final isConstrained = ResponsiveUtils.isContentAreaConstrained(context, shopSettings.navigationPosition);
                          return _buildMembersList(filteredMembers, isConstrained);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter(MembershipProvider membershipProvider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหาสมาชิก (ชื่อ, เบอร์โทร, รหัสสมาชิก)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // child: Row(
            //   children: [
            //     _buildFilterChip(
            //       label: 'ทั้งหมด',
            //       isSelected: _selectedTierId == null,
            //       onSelected: () {
            //         setState(() {
            //           _selectedTierId = null;
            //         });
            //       },
            //     ),
            //     const SizedBox(width: 8),
            //     // ...membershipProvider.tiers.map((tier) => Padding(
            //     //       padding: const EdgeInsets.only(right: 8),
            //     //       child: _buildFilterChip(
            //     //         label: tier.name,
            //     //         isSelected: _selectedTierId == tier.id,
            //     //         onSelected: () {
            //     //           setState(() {
            //     //             _selectedTierId = tier.id;
            //     //           });
            //     //         },
            //     //         color: Color(int.parse('0xFF${tier.colorHex.substring(1)}')),
            //     //       ),
            //     //     )),
            //   ],
            // ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStats(MembershipProvider membershipProvider) {
    final totalMembers = membershipProvider.members.length;
    final activeMembers = membershipProvider.members.where((m) => m.isActive).length;
    final totalPoints = membershipProvider.members
        .fold<double>(0.0, (sum, member) => sum + member.points);

    return Consumer<ShopSettingsProvider>(
      builder: (context, shopSettings, child) {
        final isConstrained = ResponsiveUtils.isContentAreaConstrained(context, shopSettings.navigationPosition);
        
        return Container(
          padding: EdgeInsets.all(isConstrained ? AppTheme.spacing12 : AppTheme.spacing16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: isConstrained 
              ? _buildCompactStats(totalMembers, activeMembers, totalPoints)
              : _buildStandardStats(totalMembers, activeMembers, totalPoints),
        );
      },
    );
  }

  Widget _buildStandardStats(int totalMembers, int activeMembers, double totalPoints) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'สมาชิกทั้งหมด',
            totalMembers.toString(),
            Icons.people,
            AppTheme.primaryColor,
            false,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildStatCard(
            'สมาชิกที่ใช้งาน',
            activeMembers.toString(),
            Icons.person_outline,
            AppTheme.successColor,
            false,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildStatCard(
            'แต้มรวมทั้งหมด',
            totalPoints.toStringAsFixed(0),
            Icons.stars,
            Colors.orange,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStats(int totalMembers, int activeMembers, double totalPoints) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'สมาชิก',
                totalMembers.toString(),
                Icons.people,
                AppTheme.primaryColor,
                true,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildStatCard(
                'ใช้งาน',
                activeMembers.toString(),
                Icons.person_outline,
                AppTheme.successColor,
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        _buildStatCard(
          'แต้มรวม',
          totalPoints.toStringAsFixed(0),
          Icons.stars,
          Colors.orange,
          true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? AppTheme.spacing8 : AppTheme.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isCompact ? 18 : 24),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            value,
            style: (isCompact ? AppTheme.body : AppTheme.heading2).copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 16 : null,
            ),
          ),
          Text(
            title,
            style: AppTheme.caption.copyWith(
              fontSize: isCompact ? 10 : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'ยังไม่มีสมาชิก',
            style: AppTheme.heading2.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'กดปุ่ม + เพื่อเพิ่มสมาชิกใหม่',
            style: AppTheme.body.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<Customer> members, bool isConstrained) {
    return ListView.builder(
      padding: EdgeInsets.all(isConstrained ? AppTheme.spacing12 : AppTheme.spacing16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return MemberListItem(
          member: member,
          onEdit: () => _editMember(member),
          onDelete: () => _deleteMember(member),
          onPointsChange: (member, newPoints) => _updateMemberPoints(member, newPoints),
          isConstrained: isConstrained,
        );
      },
    );
  }

  List<Customer> _getFilteredMembers(MembershipProvider membershipProvider) {
    List<Customer> members = membershipProvider.members;

    // กรองตามการค้นหา
    if (_searchQuery.isNotEmpty) {
      members = membershipProvider.searchMembers(_searchQuery);
    }

    // กรองตามระดับสมาชิก
    if (_selectedTierId != null) {
      members = members.where((member) => member.membershipTierId == _selectedTierId).toList();
    } else if (_selectedTierId == null && _searchQuery.isEmpty) {
      // แสดงทั้งหมดเมื่อไม่มีการกรอง
      members = membershipProvider.members;
    }

    return members;
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => const MembershipFormDialog(),
    );
  }

  void _editMember(Customer member) {
    showDialog(
      context: context,
      builder: (context) => MembershipFormDialog(member: member),
    );
  }

  void _deleteMember(Customer member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบสมาชิก'),
        content: Text('คุณต้องการลบสมาชิก "${member.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
                await membershipProvider.deleteMember(member.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบสมาชิกเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMemberPoints(Customer member, double newPoints) async {
    if (newPoints < 0) return; // ป้องกันค่าติดลบ
    
    try {
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
      final pointsChange = newPoints - member.points;
      
      await membershipProvider.adjustPoints(
        member.id, 
        pointsChange, 
        'ปรับแต้มจากหน้าจัดการสมาชิก'
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดตแต้มของ ${member.name} เป็น ${newPoints.toStringAsFixed(1)} แต้ม เรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class MemberListItem extends StatelessWidget {
  final Customer member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Customer, double) onPointsChange;
  final bool isConstrained;

  const MemberListItem({
    super.key,
    required this.member,
    required this.onEdit,
    required this.onDelete,
    required this.onPointsChange,
    this.isConstrained = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isConstrained ? 6.0 : AppTheme.spacing8),
      child: isConstrained ? _buildCompactLayout(context) : _buildStandardLayout(context),
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.isActive ? AppTheme.primaryColor : Colors.grey,
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        member.name,
        style: AppTheme.heading3,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (member.phone?.isNotEmpty == true)
            Text(
              member.phone!,
              style: AppTheme.caption,
            ),
          const SizedBox(height: AppTheme.spacing4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius4),
                ),
                child: Text(
                  '${member.points.toStringAsFixed(1)} แต้ม',
                  style: AppTheme.caption.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: member.isActive ? AppTheme.successColor : Colors.grey,
                  borderRadius: BorderRadius.circular(AppTheme.radius4),
                ),
                child: Text(
                  member.isActive ? 'ใช้งาน' : 'ไม่ใช้งาน',
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick points adjustment
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            // child: Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     InkWell(
            //       onTap: () => onPointsChange(member, member.points - 1),
            //       child: Container(
            //         padding: const EdgeInsets.all(4),
            //         child: const Icon(Icons.remove, size: 16),
            //       ),
            //     ),
            //     Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //       child: Text(
            //         '${member.points.toStringAsFixed(1)}',
            //         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            //       ),
            //     ),
            //     InkWell(
            //       onTap: () => onPointsChange(member, member.points + 1),
            //       child: Container(
            //         padding: const EdgeInsets.all(4),
            //         child: const Icon(Icons.add, size: 16),
            //       ),
            //     ),
            //   ],
            // ),
          ),
          const SizedBox(width: 8),
          _buildTrailingActions(context, false),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      child: Row(
        children: [
          // Compact avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: member.isActive ? AppTheme.primaryColor : Colors.grey,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.phone?.isNotEmpty == true)
                  Text(
                    member.phone!,
                    style: AppTheme.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${member.points.toStringAsFixed(0)}แต้ม',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: member.isActive ? AppTheme.successColor : Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        member.isActive ? 'ใช้งาน' : 'ปิด',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Compact trailing actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact points adjustment
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => onPointsChange(member, member.points - 1),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.remove, size: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        '${member.points.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    InkWell(
                      onTap: () => onPointsChange(member, member.points + 1),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.add, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _buildTrailingActions(context, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context, bool isCompact) {
    return PopupMenuButton(
      iconSize: isCompact ? 16 : 24,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('แก้ไข'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'adjust_points',
          child: Row(
            children: [
              Icon(Icons.stars, color: Colors.orange),
              SizedBox(width: 8),
              Text('ปรับแต้ม', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text('ลบ', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'adjust_points') {
          _showPointsAdjustmentDialog(context);
        } else if (value == 'delete') {
          onDelete();
        }
      },
    );
  }

  void _showPointsAdjustmentDialog(BuildContext context) {
    final TextEditingController pointsController = TextEditingController(
      text: member.points.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ปรับแต้มสมาชิก: ${member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('แต้มปัจจุบัน: ${member.points.toStringAsFixed(1)} แต้ม'),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'แต้มใหม่',
                hintText: 'กรอกจำนวนแต้มใหม่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final currentPoints = double.tryParse(pointsController.text) ?? member.points;
                      pointsController.text = (currentPoints + 10).toStringAsFixed(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('+10'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final currentPoints = double.tryParse(pointsController.text) ?? member.points;
                      final newPoints = (currentPoints - 10).clamp(0.0, double.infinity);
                      pointsController.text = newPoints.toStringAsFixed(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('-10'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPoints = double.tryParse(pointsController.text);
              if (newPoints != null && newPoints >= 0) {
                onPointsChange(member, newPoints);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกจำนวนแต้มที่ถูกต้อง'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}