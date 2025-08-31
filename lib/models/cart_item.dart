class CartItem {
  final int productId;
  final String productName;
  final double unitPrice;
  final double pointsEarned; // แต้มที่ได้รับต่อชิ้น
  int quantity;
  double discountAmount;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.pointsEarned = 1.0,
    this.quantity = 1,
    this.discountAmount = 0.0,
  });

  double get totalPrice => (unitPrice * quantity) - discountAmount;
  double get totalPointsEarned => pointsEarned * quantity; // แต้มรวมที่ได้รับ

  CartItem copyWith({
    int? productId,
    String? productName,
    double? unitPrice,
    double? pointsEarned,
    int? quantity,
    double? discountAmount,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
