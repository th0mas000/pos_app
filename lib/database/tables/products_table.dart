import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0.0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('ชิ้น'))();
  TextColumn get image => text().nullable()();
  RealColumn get pointsEarned => real().withDefault(const Constant(1.0))(); // แต้มที่ได้รับต่อชิ้น
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
