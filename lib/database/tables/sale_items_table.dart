import 'package:drift/drift.dart';
import 'sales_table.dart';
import 'products_table.dart';

@DataClassName('SaleItem')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // Store product name at time of sale
  RealColumn get unitPrice => real()();
  IntColumn get quantity => integer()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalPrice => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
