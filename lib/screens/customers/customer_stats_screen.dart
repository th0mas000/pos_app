import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customers_provider.dart';
import '../../theme/app_theme.dart';

class CustomerStatsScreen extends StatelessWidget {
  const CustomerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติลูกค้า'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<CustomersProvider>(
        builder: (context, customersProvider, child) {
          if (customersProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final customers = customersProvider.customers;
          final topCustomers = customersProvider.getTopCustomers(limit: 10);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummarySection(customers),
                
                const SizedBox(height: AppTheme.spacing24),
                
                // Top Customers
                Text(
                  'ลูกค้าอันดับต้น (คะแนนสูงสุด)',
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                if (topCustomers.isEmpty)
                  const Center(
                    child: Text(
                      'ยังไม่มีข้อมูลลูกค้า',
                      style: AppTheme.body,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = topCustomers[index];
                      return Card(
                        child: ListTile(
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
                          title: Text(customer.name),
                          subtitle: Text(customer.phone ?? 'ไม่มีเบอร์โทร'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${customer.points.toStringAsFixed(0)} คะแนน',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(List customers) {
    final totalCustomers = customers.length;
    final totalPoints = customers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.points,
    );
    final avgPoints = totalCustomers > 0 ? totalPoints / totalCustomers : 0.0;
    final activeCustomers = customers.where((c) => c.isActive).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacing16,
      mainAxisSpacing: AppTheme.spacing16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'ลูกค้าทั้งหมด',
          value: totalCustomers.toString(),
          icon: Icons.people,
          color: AppTheme.primaryColor,
        ),
        _buildStatCard(
          title: 'ลูกค้าที่ใช้งานอยู่',
          value: activeCustomers.toString(),
          icon: Icons.person_outline,
          color: AppTheme.successColor,
        ),
        _buildStatCard(
          title: 'คะแนนรวม',
          value: totalPoints.toStringAsFixed(0),
          icon: Icons.stars,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'คะแนนเฉลี่ย',
          value: avgPoints.toStringAsFixed(1),
          icon: Icons.trending_up,
          color: AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              value,
              style: AppTheme.heading2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              title,
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.brown; // Bronze
      default:
        return AppTheme.primaryColor;
    }
  }
}
