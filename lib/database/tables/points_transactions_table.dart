import 'package:drift/drift.dart';

@DataClassName('PointsTransaction')
class PointsTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer()();
  IntColumn get saleId => integer().nullable()(); // อ้างอิงการขาย (ถ้ามี)
  
  TextColumn get type => text()(); // 'earn', 'redeem', 'bonus', 'expired', 'adjustment'
  TextColumn get description => text().nullable()(); // คำอธิบายรายการ
  RealColumn get pointsAmount => real()(); // จำนวนแต้ม (+/-)
  RealColumn get pointsBalance => real()(); // ยอดแต้มคงเหลือหลังการทำรายการ
  
  // ข้อมูลเพิ่มเติม
  RealColumn get purchaseAmount => real().nullable()(); // ยอดซื้อ (สำหรับการสะสม)
  RealColumn get discountAmount => real().nullable()(); // ส่วนลดที่ได้ (สำหรับการใช้)
  
  // การหมดอายุ
  DateTimeColumn get expirationDate => dateTime().nullable()(); // วันหมดอายุของแต้มนี้
  BoolColumn get isExpired => boolean().withDefault(const Constant(false))();
  
  TextColumn get notes => text().nullable()(); // หมายเหตุเพิ่มเติม
  DateTimeColumn get transactionDate => dateTime().withDefault(currentDateAndTime)();
}
