import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_summary_widget.dart';
import 'daily_sales_report_screen.dart';
import 'monthly_sales_report_screen.dart';
import 'top_products_report_screen.dart';
import 'inventory_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงาน'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            // Dashboard Summary
            const DashboardSummaryWidget(),
            const SizedBox(height: AppTheme.spacing12), // ลดจาก spacing24
            
            // Reports Grid
            Expanded(
              child: Theme.of(context).platform == TargetPlatform.iOS ||
                     Theme.of(context).platform == TargetPlatform.android
                  ? ListView(
                      children: [
                        _buildReportCard(
                          context: context,
                          icon: Icons.trending_up,
                          title: 'ยอดขายรายวัน',
                          subtitle: 'รายงานยอดขายประจำวัน',
                          color: AppTheme.successColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DailySalesReportScreen()),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing12),
                        _buildReportCard(
                          context: context,
                          icon: Icons.calendar_month,
                          title: 'ยอดขายรายเดือน',
                          subtitle: 'รายงานยอดขายประจำเดือน',
                          color: AppTheme.primaryColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MonthlySalesReportScreen()),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing12),
                        _buildReportCard(
                          context: context,
                          icon: Icons.star,
                          title: 'สินค้าขายดี',
                          subtitle: 'รายงานสินค้าที่ขายดีที่สุด',
                          color: AppTheme.warningColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TopProductsReportScreen()),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing12),
                        _buildReportCard(
                          context: context,
                          icon: Icons.inventory,
                          title: 'สต็อกสินค้า',
                          subtitle: 'รายงานสถานะคลังสินค้า',
                          color: AppTheme.infoColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InventoryReportScreen()),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildReportCard(
                            context: context,
                            icon: Icons.trending_up,
                            title: 'ยอดขายรายวัน',
                            subtitle: 'รายงานยอดขายประจำวัน',
                            color: AppTheme.successColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DailySalesReportScreen()),
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacing16),
                        Expanded(
                          child: _buildReportCard(
                            context: context,
                            icon: Icons.calendar_month,
                            title: 'ยอดขายรายเดือน',
                            subtitle: 'รายงานยอดขายประจำเดือน',
                            color: AppTheme.primaryColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MonthlySalesReportScreen()),
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacing16),
                        Expanded(
                          child: _buildReportCard(
                            context: context,
                            icon: Icons.star,
                            title: 'สินค้าขายดี',
                            subtitle: 'รายงานสินค้าที่ขายดีที่สุด',
                            color: AppTheme.warningColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TopProductsReportScreen()),
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacing16),
                        Expanded(
                          child: _buildReportCard(
                            context: context,
                            icon: Icons.inventory,
                            title: 'สต็อกสินค้า',
                            subtitle: 'รายงานสถานะคลังสินค้า',
                            color: AppTheme.infoColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const InventoryReportScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isMobile = Theme.of(context).platform == TargetPlatform.iOS ||
                    Theme.of(context).platform == TargetPlatform.android;
    
    if (isMobile) {
      // List-style card for mobile
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        subtitle,
                        style: AppTheme.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Grid-style card for desktop
      return SizedBox(
        height: 180, // กำหนดความสูงที่เล็กลง
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    title,
                    style: AppTheme.heading3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}