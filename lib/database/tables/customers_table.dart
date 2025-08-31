import 'package:drift/drift.dart';

@DataClassName('Customer')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get points => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  // เพิ่มข้อมูลสมาชิก
  IntColumn get membershipTierId => integer().nullable()(); // อ้างอิงระดับสมาชิก
  TextColumn get membershipNumber => text().nullable()(); // รหัสสมาชิก
  DateTimeColumn get membershipStartDate => dateTime().nullable()(); // วันที่เริ่มเป็นสมาชิก
  DateTimeColumn get lastPointsEarnDate => dateTime().nullable()(); // วันที่สะสมแต้มล่าสุด
  DateTimeColumn get lastPurchaseDate => dateTime().nullable()(); // วันที่ซื้อล่าสุด
  RealColumn get totalSpent => real().withDefault(const Constant(0.0))(); // ยอดซื้อสะสม
  RealColumn get lifetimePoints => real().withDefault(const Constant(0.0))(); // แต้มสะสมตลอดชีวิต
  
  // ข้อมูลส่วนตัวเพิ่มเติม
  DateTimeColumn get birthDate => dateTime().nullable()(); // วันเกิด
  TextColumn get gender => text().nullable()(); // เพศ
  TextColumn get notes => text().nullable()(); // หมายเหตุ
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
