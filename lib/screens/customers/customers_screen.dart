import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/membership_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/customer_form_dialog.dart';
import '../../widgets/customer_card.dart';
import 'customer_stats_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลลูกค้าเมื่อเข้าสู่หน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomersProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการลูกค้า'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _showStats(context),
            icon: const Icon(Icons.analytics),
            tooltip: 'สถิติลูกค้า',
          ),
          IconButton(
            onPressed: () => _addCustomer(context),
            icon: const Icon(Icons.person_add),
            tooltip: 'เพิ่มลูกค้าใหม่',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาลูกค้า...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<CustomersProvider>().setSearchQuery('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<CustomersProvider>().setSearchQuery(value);
              },
            ),
          ),
          
          // Customer List
          Expanded(
            child: Consumer<CustomersProvider>(
              builder: (context, customersProvider, child) {
                if (customersProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final customers = customersProvider.customers;

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        Text(
                          customersProvider.searchQuery.isNotEmpty
                              ? 'ไม่พบลูกค้าที่ค้นหา'
                              : 'ยังไม่มีลูกค้า',
                          style: AppTheme.heading2.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          customersProvider.searchQuery.isNotEmpty
                              ? 'ลองค้นหาด้วยคำอื่น'
                              : 'เริ่มต้นด้วยการเพิ่มลูกค้าใหม่',
                          style: AppTheme.body.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (customersProvider.searchQuery.isEmpty) ...[
                          const SizedBox(height: AppTheme.spacing24),
                          ElevatedButton.icon(
                            onPressed: () => _addCustomer(context),
                            icon: const Icon(Icons.person_add),
                            label: const Text('เพิ่มลูกค้าใหม่'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => customersProvider.loadCustomers(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      crossAxisSpacing: AppTheme.spacing16,
                      mainAxisSpacing: AppTheme.spacing16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return CustomerCard(customerId: customer.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCustomer(context),
        tooltip: 'เพิ่มลูกค้าใหม่',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _addCustomer(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CustomerFormDialog(),
    );
    
    if (result == true) {
      // Refresh customers data
      if (mounted) {
        await context.read<CustomersProvider>().loadCustomers();
        
        // Also refresh membership provider to keep both providers in sync
        await context.read<MembershipProvider>().loadMembers();
      }
    }
  }

  void _showStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerStatsScreen(),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
