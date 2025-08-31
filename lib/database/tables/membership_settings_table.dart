import 'package:drift/drift.dart';

@DataClassName('MembershipSetting')
class MembershipSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // ระบบการสะสมแต้ม
  RealColumn get pointsPerBaht => real().withDefault(const Constant(1.0))(); // แต้มต่อ 1 บาท
  RealColumn get minSpendForPoints => real().withDefault(const Constant(0.0))(); // ยอดขายขั้นต่ำเพื่อสะสมแต้ม
  RealColumn get maxPointsPerTransaction => real().withDefault(const Constant(1000.0))(); // แต้มสูงสุดต่อรายการ
  
  // ระบบการใช้แต้ม
  RealColumn get pointsToDiscountRate => real().withDefault(const Constant(1.0))(); // แต้ม : บาท เพื่อแลกส่วนลด
  RealColumn get minPointsToRedeem => real().withDefault(const Constant(10.0))(); // แต้มขั้นต่ำเพื่อใช้
  RealColumn get maxDiscountPercent => real().withDefault(const Constant(100.0))(); // % ส่วนลดสูงสุด
  
  // ระดับสมาชิก
  BoolColumn get enableMembershipTiers => boolean().withDefault(const Constant(false))();
  
  // การหมดอายุของแต้ม
  BoolColumn get enablePointsExpiration => boolean().withDefault(const Constant(false))();
  IntColumn get pointsExpirationDays => integer().withDefault(const Constant(365))(); // วันหมดอายุ
  
  // โบนัสและโปรโมชั่น
  BoolColumn get enableBirthdayBonus => boolean().withDefault(const Constant(false))();
  RealColumn get birthdayBonusPoints => real().withDefault(const Constant(100.0))();
  
  BoolColumn get enableReferralBonus => boolean().withDefault(const Constant(false))();
  RealColumn get referralBonusPoints => real().withDefault(const Constant(50.0))();
  
  // การแจ้งเตือน
  BoolColumn get enablePointsNotification => boolean().withDefault(const Constant(true))();
  BoolColumn get enableExpirationWarning => boolean().withDefault(const Constant(true))();
  IntColumn get expirationWarningDays => integer().withDefault(const Constant(30))(); // แจ้งเตือนก่อนหมดอายุ
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
