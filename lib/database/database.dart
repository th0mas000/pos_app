import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import all table definitions
import 'tables/shop_settings_table.dart';
import 'tables/categories_table.dart';
import 'tables/products_table.dart';
import 'tables/customers_table.dart';
import 'tables/users_table.dart';
import 'tables/sales_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/membership_settings_table.dart';
import 'tables/membership_tiers_table.dart';
import 'tables/points_transactions_table.dart';
import '../data/sample_data.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  ShopSettings,
  Categories,
  Products,
  Customers,
  Users,
  Sales,
  SaleItems,
  MembershipSettings,
  MembershipTiers,
  PointsTransactions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      
      // Insert default data
      await _insertDefaultData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add the promptPayId column to existing shop_settings table
        await m.addColumn(shopSettings, shopSettings.promptPayId);
      }
      if (from < 3) {
        // Create new membership tables
        await m.createTable(membershipSettings);
        await m.createTable(membershipTiers);
        await m.createTable(pointsTransactions);
        
        // Add new columns to customers table
        await m.addColumn(customers, customers.points);
        await m.addColumn(customers, customers.lifetimePoints);
        await m.addColumn(customers, customers.membershipTierId);
        await m.addColumn(customers, customers.membershipNumber);
        await m.addColumn(customers, customers.membershipStartDate);
        await m.addColumn(customers, customers.lastPointsEarnDate);
        await m.addColumn(customers, customers.lastPurchaseDate);
        await m.addColumn(customers, customers.totalSpent);
        await m.addColumn(customers, customers.birthDate);
        await m.addColumn(customers, customers.gender);
        await m.addColumn(customers, customers.notes);
        
        // Insert default membership data
        await _insertDefaultMembershipData();
      }
      if (from < 4) {
        // Add pointsEarned column to products table
        await m.addColumn(products, products.pointsEarned);
      }
      if (from < 5) {
        // Add navigationPosition column to shop_settings table
        await m.addColumn(shopSettings, shopSettings.navigationPosition);
      }
    },
  );

  Future<void> _insertDefaultMembershipData() async {
    // Insert default membership settings
    await into(membershipSettings).insert(MembershipSettingsCompanion.insert());
    
    // Insert default membership tiers
    await into(membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Bronze',
      description: const Value('สมาชิกระดับเริ่มต้น'),
      minPoints: const Value(0.0),
      maxPoints: const Value(999.0),
      pointsMultiplier: const Value(1.0),
      colorHex: const Value('#CD7F32'),
      iconName: const Value('stars'),
      sortOrder: const Value(1),
    ));
    
    await into(membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Silver',
      description: const Value('สมาชิกระดับเงิน'),
      minPoints: const Value(1000.0),
      maxPoints: const Value(4999.0),
      pointsMultiplier: const Value(1.2),
      discountPercent: const Value(5.0),
      colorHex: const Value('#C0C0C0'),
      iconName: const Value('diamond'),
      sortOrder: const Value(2),
    ));
    
    await into(membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Gold',
      description: const Value('สมาชิกระดับทอง'),
      minPoints: const Value(5000.0),
      maxPoints: const Value(9999.0),
      pointsMultiplier: const Value(1.5),
      discountPercent: const Value(10.0),
      bonusPointsOnSignup: const Value(100.0),
      colorHex: const Value('#FFD700'),
      iconName: const Value('workspace_premium'),
      sortOrder: const Value(3),
    ));
    
    await into(membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Platinum',
      description: const Value('สมาชิกระดับแพลทินัม'),
      minPoints: const Value(10000.0),
      pointsMultiplier: const Value(2.0),
      discountPercent: const Value(15.0),
      bonusPointsOnSignup: const Value(200.0),
      colorHex: const Value('#E5E4E2'),
      iconName: const Value('military_tech'),
      sortOrder: const Value(4),
    ));
  }

  Future<void> _insertDefaultData() async {
    // Insert default shop settings
    await into(shopSettings).insert(ShopSettingsCompanion.insert(
      shopName: 'ร้านค้าของฉัน',
      address: const Value('ที่อยู่ร้านค้า'),
      phone: const Value('0812345678'),
      email: const Value('shop@example.com'),
      vatRate: const Value(7.0),
      currency: const Value('THB'),
      currencySymbol: const Value('฿'),
    ));

    // Insert default categories
    await into(categories).insert(CategoriesCompanion.insert(
      name: 'อาหาร',
      description: const Value('อาหารและเครื่องดื่ม'),
    ));
    
    await into(categories).insert(CategoriesCompanion.insert(
      name: 'เครื่องดื่ม',
      description: const Value('เครื่องดื่มทุกประเภท'),
    ));

    // Insert default admin user
    await into(users).insert(UsersCompanion.insert(
      username: 'admin',
      password: 'admin123',
      fullName: 'ผู้ดูแลระบบ',
      role: const Value('admin'),
      isActive: const Value(true),
    ));

    // Insert sample products
    // await SampleData.insertSampleProducts(this);
    
    // Insert default membership data
    await _insertDefaultMembershipData();
  }

  // Stock management methods
  Future<void> updateProductStock(int productId, int quantity) async {
    await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(stock: Value(quantity)));
  }

  Future<void> reduceProductStock(int productId, int quantity) async {
    final product = await (select(products)..where((p) => p.id.equals(productId))).getSingle();
    final newStock = product.stock - quantity;
    await updateProductStock(productId, newStock >= 0 ? newStock : 0);
  }

  Future<void> increaseProductStock(int productId, int quantity) async {
    final product = await (select(products)..where((p) => p.id.equals(productId))).getSingle();
    final newStock = product.stock + quantity;
    await updateProductStock(productId, newStock);
  }

  // Sales management methods
  Future<int> createSale({
    required String saleNumber,
    int? customerId,
    required int userId,
    required double subtotal,
    double discountAmount = 0.0,
    double taxAmount = 0.0,
    required double total,
    required double paidAmount,
    double changeAmount = 0.0,
    required String paymentMethod,
    String? notes,
  }) async {
    final saleId = await into(sales).insert(SalesCompanion.insert(
      saleNumber: saleNumber,
      customerId: Value(customerId),
      userId: userId,
      subtotal: subtotal,
      discountAmount: Value(discountAmount),
      taxAmount: Value(taxAmount),
      total: total,
      paidAmount: paidAmount,
      changeAmount: Value(changeAmount),
      paymentMethod: Value(paymentMethod),
      notes: Value(notes),
    ));
    return saleId;
  }

  Future<void> addSaleItem({
    required int saleId,
    required int productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) async {
    await into(saleItems).insert(SaleItemsCompanion.insert(
      saleId: saleId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    ));
    
    // Reduce stock
    await reduceProductStock(productId, quantity);
  }

  Future<void> completeSale({
    required List<Map<String, dynamic>> cartItems,
    int? customerId,
    required double total,
    required double paidAmount,
    required String paymentMethod,
    String? notes,
  }) async {
    final saleNumber = 'SALE${DateTime.now().millisecondsSinceEpoch}';
    
    final saleId = await createSale(
      saleNumber: saleNumber,
      customerId: customerId,
      userId: 1, // Default admin user
      subtotal: total,
      total: total,
      paidAmount: paidAmount,
      changeAmount: paidAmount - total,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    for (final item in cartItems) {
      await addSaleItem(
        saleId: saleId,
        productId: item['productId'],
        productName: item['name'],
        quantity: item['quantity'],
        unitPrice: item['price'],
        totalPrice: item['price'] * item['quantity'],
      );
    }
  }

  // Clear all sales data
  Future<void> clearSalesData() async {
    await delete(saleItems).go();
    await delete(sales).go();
  }

  // Get low stock products (products with stock <= 5)
  Future<List<Product>> getLowStockProducts() async {
    return await (select(products)..where((p) => p.stock.isSmallerOrEqualValue(5) & p.isActive.equals(true))).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pos_app.db'));
    return NativeDatabase(file);
  });
}
