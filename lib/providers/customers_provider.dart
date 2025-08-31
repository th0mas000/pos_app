import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../services/membership_service.dart';

class CustomersProvider with ChangeNotifier {
  final AppDatabase _database;
  late final MembershipService _membershipService;
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  CustomersProvider(this._database) {
    _membershipService = MembershipService(_database);
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      await _membershipService.ensureInitialized();
      await loadCustomers();
    } catch (e) {
      debugPrint('Error initializing customers provider: $e');
    }
  }

  List<Customer> get customers {
    if (_searchQuery.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer.phone?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (customer.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (customer.membershipNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  MembershipService get membershipService => _membershipService;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Loading customers from database...');
      final query = _database.select(_database.customers)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]);
      _customers = await query.get();
      debugPrint('Loaded ${_customers.length} customers');
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('CustomersProvider notifyListeners() called');
    }
  }

  Future<void> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    double points = 0.0,
  }) async {
    try {
      final companion = CustomersCompanion.insert(
        name: name,
        phone: phone != null ? Value(phone) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        address: address != null ? Value(address) : const Value.absent(),
        points: Value(points),
      );

      await _database.into(_database.customers).insert(companion);
      await loadCustomers();
    } catch (e) {
      debugPrint('Error adding customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer({
    required int id,
    required String name,
    String? phone,
    String? email,
    String? address,
    double? points,
  }) async {
    try {
      await (_database.update(_database.customers)..where((tbl) => tbl.id.equals(id)))
          .write(CustomersCompanion(
            name: Value(name),
            phone: phone != null ? Value(phone) : const Value.absent(),
            email: email != null ? Value(email) : const Value.absent(),
            address: address != null ? Value(address) : const Value.absent(),
            points: points != null ? Value(points) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ));
      await loadCustomers();
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      // Soft delete by setting isActive to false
      await (_database.update(_database.customers)..where((tbl) => tbl.id.equals(id)))
          .write(CustomersCompanion(
            isActive: const Value(false),
            updatedAt: Value(DateTime.now()),
          ));
      await loadCustomers();
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      rethrow;
    }
  }

  Future<void> addPoints(int customerId, double points) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      final newPoints = customer.points + points;
      final newLifetimePoints = customer.lifetimePoints + points;

      debugPrint('Adding points: Customer ${customer.name} (ID: $customerId)');
      debugPrint('Current points: ${customer.points}, Adding: $points, New total: $newPoints');

      await (_database.update(_database.customers)..where((tbl) => tbl.id.equals(customerId)))
          .write(CustomersCompanion(
            points: Value(newPoints),
            lifetimePoints: Value(newLifetimePoints),
            lastPointsEarnDate: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));
      
      // อัปเดตระดับสมาชิกตาม points ใหม่
      await _membershipService.updateCustomerMembership(customerId, newPoints);
      
      await loadCustomers();
      
      debugPrint('Points added successfully: $points points to customer $customerId');
      debugPrint('Updated customer points: ${getCustomerById(customerId)?.points}');
    } catch (e) {
      debugPrint('Error adding points: $e');
      rethrow;
    }
  }

  Future<void> redeemPoints(int customerId, double points) async {
    try {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      
      if (customer.points < points) {
        throw Exception('คะแนนไม่เพียงพอ');
      }

      final newPoints = customer.points - points;

      await (_database.update(_database.customers)..where((tbl) => tbl.id.equals(customerId)))
          .write(CustomersCompanion(
            points: Value(newPoints),
            updatedAt: Value(DateTime.now()),
          ));
      await loadCustomers();
    } catch (e) {
      debugPrint('Error redeeming points: $e');
      rethrow;
    }
  }

  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Customer> getTopCustomers({int limit = 10}) {
    final sortedCustomers = List<Customer>.from(_customers);
    sortedCustomers.sort((a, b) => b.points.compareTo(a.points));
    return sortedCustomers.take(limit).toList();
  }
}
