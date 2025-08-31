import 'package:drift/drift.dart';

@DataClassName('ShopSetting')
class ShopSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shopName => text().withLength(min: 1, max: 255)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get logo => text().nullable()();
  RealColumn get vatRate => real().withDefault(const Constant(7.0))();
  TextColumn get currency => text().withDefault(const Constant('THB'))();
  TextColumn get currencySymbol => text().withDefault(const Constant('฿'))();
  TextColumn get promptPayId => text().nullable()();
  TextColumn get navigationPosition => text().withDefault(const Constant('bottom'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
