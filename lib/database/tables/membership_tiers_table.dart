import 'package:drift/drift.dart';

@DataClassName('MembershipTier')
class MembershipTiers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)(); // ชื่อระดับ เช่น Bronze, Silver, Gold
  TextColumn get description => text().nullable()(); // คำอธิบายระดับ
  RealColumn get minPoints => real().withDefault(const Constant(0.0))(); // แต้มขั้นต่ำ
  RealColumn get maxPoints => real().nullable()(); // แต้มสูงสุด (null = ไม่จำกัด)
  
  // สิทธิพิเศษ
  RealColumn get pointsMultiplier => real().withDefault(const Constant(1.0))(); // ตัวคูณแต้ม
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))(); // ส่วนลดพิเศษ %
  RealColumn get bonusPointsOnSignup => real().withDefault(const Constant(0.0))(); // แต้มโบนัสเมื่อเลื่อนระดับ
  
  // สี Theme
  TextColumn get colorHex => text().withDefault(const Constant('#4CAF50'))(); // สีประจำระดับ
  TextColumn get iconName => text().withDefault(const Constant('stars'))(); // ชื่อ icon
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))(); // ลำดับการแสดงผล
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
