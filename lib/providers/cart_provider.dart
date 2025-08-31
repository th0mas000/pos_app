import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../models/cart_item.dart';
import '../database/database.dart';
import 'shop_settings_provider.dart';

class CartProvider with ChangeNotifier {
  final AppDatabase _database;
  final List<CartItem> _items = [];
  String _paymentMethod = 'cash';
  double _discountAmount = 0.0;
  int? _customerId;
  ShopSettingsProvider? _shopSettingsProvider;

  CartProvider(this._database);

  // เพิ่มฟังก์ชันสำหรับเชื่อม ShopSettingsProvider
  void setShopSettingsProvider(ShopSettingsProvider provider) {
    _shopSettingsProvider = provider;
    notifyListeners();
  }

  List<CartItem> get items => _items;
  String get paymentMethod => _paymentMethod;
  double get discountAmount => _discountAmount;
  double get vatRate => _shopSettingsProvider?.vatRate ?? 7.0;
  int? get customerId => _customerId;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
  }

  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => sum + item.discountAmount) + _discountAmount;
  }

  double get subtotalAfterDiscount {
    return subtotal - totalDiscount;
  }

  double get vatAmount {
    return subtotalAfterDiscount * (vatRate / 100);
  }

  double get total {
    return subtotalAfterDiscount + vatAmount;
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPointsEarned {
    return _items.fold(0.0, (sum, item) => sum + item.totalPointsEarned);
  }

  Future<int> _getCurrentStock(int productId) async {
    final product = await (_database.select(_database.products)
      ..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
    return product?.stock ?? 0;
  }

  Future<int> getAvailableStock(int productId) async {
    return await _getCurrentStock(productId);
  }

  int getCartQuantityForProduct(int productId) {
    final cartItem = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(productId: -1, productName: '', unitPrice: 0),
    );
    return cartItem.productId == -1 ? 0 : cartItem.quantity;
  }

  Future<bool> addItem(Product product) async {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id);
    
    // Get current stock from database
    final currentStock = await _getCurrentStock(product.id);
    
    if (existingIndex >= 0) {
      // Check if adding one more item exceeds stock
      final newQuantity = _items[existingIndex].quantity + 1;
      if (newQuantity > currentStock) {
        return false; // Cannot add more items due to insufficient stock
      }
      
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: newQuantity,
      );
    } else {
      // Check if stock is available for new item
      if (currentStock < 1) {
        return false; // Cannot add item due to no stock
      }
      
      _items.add(CartItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        pointsEarned: product.pointsEarned,
      ));
    }
    notifyListeners();
    return true; // Successfully added item
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  Future<bool> updateQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      removeItem(productId);
      return true;
    }

    // Get current stock from database
    final currentStock = await _getCurrentStock(productId);
    
    // Check if requested quantity exceeds available stock
    if (quantity > currentStock) {
      return false; // Cannot update quantity due to insufficient stock
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateItemDiscount(int productId, double discount) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(discountAmount: discount);
      notifyListeners();
    }
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDiscountAmount(double amount) {
    _discountAmount = amount;
    notifyListeners();
  }

  void setCustomer(int? customerId) {
    _customerId = customerId;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _paymentMethod = 'cash';
    _discountAmount = 0.0;
    _customerId = null;
    notifyListeners();
  }

  Future<Sale> checkout(int userId, double paidAmount, {int? customerId}) async {
    if (_items.isEmpty) {
      throw Exception('Cart is empty');
    }

    final saleNumber = 'SALE-${DateTime.now().millisecondsSinceEpoch}';
    final changeAmount = paidAmount - total;

    // Insert sale record
    final saleId = await _database.into(_database.sales).insert(
      SalesCompanion.insert(
        saleNumber: saleNumber,
        customerId: customerId != null ? Value(customerId) : Value(_customerId),
        userId: userId,
        subtotal: subtotal,
        discountAmount: Value(totalDiscount),
        taxAmount: Value(vatAmount),
        total: total,
        paidAmount: paidAmount,
        changeAmount: Value(changeAmount),
        paymentMethod: Value(_paymentMethod),
      ),
    );

    // Insert sale items
    for (final item in _items) {
      await _database.into(_database.saleItems).insert(
        SaleItemsCompanion.insert(
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          discountAmount: Value(item.discountAmount),
          totalPrice: item.totalPrice,
        ),
      );

      // Update product stock
      final product = await (_database.select(_database.products)
            ..where((tbl) => tbl.id.equals(item.productId)))
          .getSingle();
      
      await _database.update(_database.products).replace(
        product.copyWith(stock: product.stock - item.quantity),
      );
    }

    // Get the created sale
    final sale = await (_database.select(_database.sales)
          ..where((tbl) => tbl.id.equals(saleId)))
        .getSingle();

    clear();
    return sale;
  }
}
