import 'package:flutter/foundation.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';

class MembershipService extends ChangeNotifier {
  final AppDatabase _database;
  MembershipSetting? _currentSettings;
  List<MembershipTier> _tiers = [];

  MembershipService(this._database);

  // เพิ่มการโหลดข้อมูลแบบ lazy
  Future<void> ensureInitialized() async {
    if (_currentSettings == null) {
      await _loadMembershipData();
    }
  }

  MembershipSetting? get currentSettings => _currentSettings;
  List<MembershipTier> get tiers => _tiers;

  Future<void> _loadMembershipData() async {
    try {
      // ตรวจสอบว่าตารางมีอยู่หรือไม่และสร้างข้อมูลเริ่มต้นถ้าจำเป็น
      await _ensureDefaultData();
      
      // โหลดการตั้งค่าระบบสมาชิก
      final settings = await _database.select(_database.membershipSettings).getSingleOrNull();
      _currentSettings = settings;

      // โหลดระดับสมาชิก
      _tiers = await (_database.select(_database.membershipTiers)
            ..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading membership data: $e');
      // สร้างค่าเริ่มต้นถ้าเกิดข้อผิดพลาด
      _currentSettings = null;
      _tiers = [];
      notifyListeners();
    }
  }

  Future<void> _ensureDefaultData() async {
    try {
      // ตรวจสอบว่ามีการตั้งค่าอยู่แล้วหรือไม่
      final existingSettings = await _database.select(_database.membershipSettings).getSingleOrNull();
      if (existingSettings == null) {
        // สร้างการตั้งค่าเริ่มต้น
        await _database.into(_database.membershipSettings).insert(MembershipSettingsCompanion.insert());
      }

      // ตรวจสอบว่ามีระดับสมาชิกอยู่แล้วหรือไม่
      final existingTiers = await _database.select(_database.membershipTiers).get();
      if (existingTiers.isEmpty) {
        // สร้างระดับสมาชิกเริ่มต้น
        await _createDefaultTiers();
      }
    } catch (e) {
      debugPrint('Error ensuring default membership data: $e');
      // หากยังไม่สามารถสร้างได้ ให้รอและลองใหม่
      rethrow;
    }
  }

  Future<void> _createDefaultTiers() async {
    await _database.into(_database.membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Bronze',
      description: const Value('สมาชิกระดับเริ่มต้น'),
      minPoints: const Value(0.0),
      maxPoints: const Value(999.0),
      pointsMultiplier: const Value(1.0),
      colorHex: const Value('#CD7F32'),
      iconName: const Value('stars'),
      sortOrder: const Value(1),
    ));
    
    await _database.into(_database.membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Silver',
      description: const Value('สมาชิกระดับเงิน'),
      minPoints: const Value(1000.0),
      maxPoints: const Value(4999.0),
      pointsMultiplier: const Value(1.2),
      discountPercent: const Value(5.0),
      colorHex: const Value('#C0C0C0'),
      iconName: const Value('stars'),
      sortOrder: const Value(2),
    ));
    
    await _database.into(_database.membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Gold',
      description: const Value('สมาชิกระดับทอง'),
      minPoints: const Value(5000.0),
      maxPoints: const Value(19999.0),
      pointsMultiplier: const Value(1.5),
      discountPercent: const Value(10.0),
      colorHex: const Value('#FFD700'),
      iconName: const Value('stars'),
      sortOrder: const Value(3),
    ));
    
    await _database.into(_database.membershipTiers).insert(MembershipTiersCompanion.insert(
      name: 'Platinum',
      description: const Value('สมาชิกระดับแพลทินัม'),
      minPoints: const Value(20000.0),
      pointsMultiplier: const Value(2.0),
      discountPercent: const Value(15.0),
      colorHex: const Value('#E5E4E2'),
      iconName: const Value('diamond'),
      sortOrder: const Value(4),
    ));
  }

  // การตั้งค่าระบบสมาชิก
  Future<void> updateSettings(MembershipSettingsCompanion settings) async {
    try {
      if (_currentSettings != null) {
        await (_database.update(_database.membershipSettings)
              ..where((s) => s.id.equals(_currentSettings!.id)))
            .write(settings.copyWith(updatedAt: Value(DateTime.now())));
      } else {
        await _database.into(_database.membershipSettings).insert(settings);
      }
      await _loadMembershipData();
    } catch (e) {
      debugPrint('Error updating membership settings: $e');
      rethrow;
    }
  }

  // จัดการระดับสมาชิก
  Future<void> addTier(MembershipTiersCompanion tier) async {
    try {
      await _database.into(_database.membershipTiers).insert(tier);
      await _loadMembershipData();
    } catch (e) {
      debugPrint('Error adding tier: $e');
      rethrow;
    }
  }

  Future<void> updateTier(int id, MembershipTiersCompanion tier) async {
    try {
      await (_database.update(_database.membershipTiers)
            ..where((t) => t.id.equals(id)))
          .write(tier.copyWith(updatedAt: Value(DateTime.now())));
      await _loadMembershipData();
    } catch (e) {
      debugPrint('Error updating tier: $e');
      rethrow;
    }
  }

  Future<void> deleteTier(int id) async {
    try {
      await (_database.update(_database.membershipTiers)
            ..where((t) => t.id.equals(id)))
          .write(const MembershipTiersCompanion(isActive: Value(false)));
      await _loadMembershipData();
    } catch (e) {
      debugPrint('Error deleting tier: $e');
      rethrow;
    }
  }

  // คำนวณแต้มที่ได้รับ (ใช้แต้มจากสินค้าแทน)
  double calculatePointsToEarn(double amount, {Customer? customer}) {
    // ฟังก์ชันนี้ไม่ใช้แล้ว จะใช้แต้มจากสินค้าแทน
    return 0.0;
  }

  // คำนวณส่วนลดจากแต้ม
  double calculateDiscountFromPoints(double points) {
    if (_currentSettings == null) return points; // default 1:1
    return points * _currentSettings!.pointsToDiscountRate;
  }

  // ตรวจสอบระดับสมาชิก
  MembershipTier? getMembershipTier(double totalPoints) {
    for (final tier in _tiers.reversed) {
      if (totalPoints >= tier.minPoints) {
        if (tier.maxPoints == null || totalPoints <= tier.maxPoints!) {
          return tier;
        }
      }
    }
    return _tiers.isNotEmpty ? _tiers.first : null;
  }

  // อัปเดตระดับสมาชิกของลูกค้า
  Future<void> updateCustomerMembership(int customerId, double currentPoints) async {
    try {
      final newTier = getMembershipTier(currentPoints);
      if (newTier != null) {
        await (_database.update(_database.customers)
              ..where((c) => c.id.equals(customerId)))
            .write(CustomersCompanion(
              membershipTierId: Value(newTier.id),
              updatedAt: Value(DateTime.now()),
            ));
      }
    } catch (e) {
      debugPrint('Error updating customer membership: $e');
    }
  }

  // บันทึกรายการแต้ม
  Future<void> recordPointsTransaction({
    required int customerId,
    required String type,
    required double pointsAmount,
    required double pointsBalance,
    int? saleId,
    String? description,
    double? purchaseAmount,
    double? discountAmount,
    DateTime? expirationDate,
    String? notes,
  }) async {
    try {
      await _database.into(_database.pointsTransactions).insert(
        PointsTransactionsCompanion.insert(
          customerId: customerId,
          type: type,
          pointsAmount: pointsAmount,
          pointsBalance: pointsBalance,
          saleId: Value(saleId),
          description: Value(description),
          purchaseAmount: Value(purchaseAmount),
          discountAmount: Value(discountAmount),
          expirationDate: Value(expirationDate),
          notes: Value(notes),
        ),
      );
    } catch (e) {
      debugPrint('Error recording points transaction: $e');
      rethrow;
    }
  }

  // ดึงประวัติการทำรายการแต้ม
  Future<List<PointsTransaction>> getPointsHistory(int customerId, {int limit = 50}) async {
    try {
      return await (_database.select(_database.pointsTransactions)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(limit))
          .get();
    } catch (e) {
      debugPrint('Error getting points history: $e');
      return [];
    }
  }

  // ดึงรายการทำรายการแต้มทั้งหมดสำหรับรายงาน
  Future<List<PointsTransaction>> getAllPointsTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
  }) async {
    try {
      var query = _database.select(_database.pointsTransactions);
      
      // ใส่เงื่อนไขการกรอง
      query = query..where((t) {
        var conditions = <Expression<bool>>[];
        
        if (startDate != null) {
          conditions.add(t.transactionDate.isBiggerOrEqualValue(startDate));
        }
        
        if (endDate != null) {
          conditions.add(t.transactionDate.isSmallerThanValue(endDate));
        }
        
        if (type != null && type.isNotEmpty) {
          conditions.add(t.type.equals(type));
        }
        
        // รวมเงื่อนไขทั้งหมดด้วย AND
        if (conditions.isNotEmpty) {
          return conditions.reduce((a, b) => a & b);
        }
        
        return const Constant(true);
      });
      
      // เรียงลำดับตามวันที่ล่าสุด
      query = query..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]);
      
      // จำกัดจำนวน
      if (limit != null) {
        query = query..limit(limit);
      }
      
      return await query.get();
    } catch (e) {
      debugPrint('Error getting all points transactions: $e');
      return [];
    }
  }

  // สร้างรหัสสมาชิก
  Future<String> generateMembershipNumber() async {
    final now = DateTime.now();
    final prefix = 'MB${now.year.toString().substring(2)}';
    
    // หาเลขที่มากที่สุด
    final lastCustomer = await (_database.select(_database.customers)
          ..where((c) => c.membershipNumber.isNotNull())
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    int nextNumber = 1;
    if (lastCustomer?.membershipNumber != null) {
      final lastNumber = lastCustomer!.membershipNumber!;
      final numberPart = lastNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (numberPart.isNotEmpty) {
        nextNumber = int.tryParse(numberPart) ?? 0;
        nextNumber++;
      }
    }

    return '$prefix${nextNumber.toString().padLeft(4, '0')}';
  }

  // ตรวจสอบแต้มหมดอายุ
  Future<void> processExpiredPoints() async {
    if (_currentSettings?.enablePointsExpiration != true) return;

    try {
      final now = DateTime.now();
      final expiredTransactions = await (_database.select(_database.pointsTransactions)
            ..where((t) => t.expirationDate.isNotNull() &
                t.expirationDate.isSmallerThanValue(now) &
                t.isExpired.equals(false) &
                t.pointsAmount.isBiggerThanValue(0.0)))
          .get();

      for (final transaction in expiredTransactions) {
        // หักแต้มที่หมดอายุ
        final customer = await (_database.select(_database.customers)
              ..where((c) => c.id.equals(transaction.customerId)))
            .getSingle();

        final newPoints = (customer.points - transaction.pointsAmount).clamp(0.0, double.infinity);

        await (_database.update(_database.customers)
              ..where((c) => c.id.equals(transaction.customerId)))
            .write(CustomersCompanion(
              points: Value(newPoints),
              updatedAt: Value(DateTime.now()),
            ));

        // ทำเครื่องหมายว่าหมดอายุแล้ว
        await (_database.update(_database.pointsTransactions)
              ..where((t) => t.id.equals(transaction.id)))
            .write(const PointsTransactionsCompanion(isExpired: Value(true)));

        // บันทึกรายการหักแต้มหมดอายุ
        await recordPointsTransaction(
          customerId: transaction.customerId,
          type: 'expired',
          pointsAmount: -transaction.pointsAmount,
          pointsBalance: newPoints,
          description: 'แต้มหมดอายุ',
          notes: 'หมดอายุจากรายการ ID: ${transaction.id}',
        );
      }
    } catch (e) {
      debugPrint('Error processing expired points: $e');
    }
  }

  // ดึงสถิติระบบสมาชิก
  Future<Map<String, dynamic>> getMembershipStats() async {
    try {
      // ดึงเฉพาะสมาชิกที่ยังใช้งานอยู่
      final activeCustomers = await (_database.select(_database.customers)
            ..where((c) => c.isActive.equals(true)))
          .get();
      
      final transactions = await _database.select(_database.pointsTransactions).get();

      final totalMembers = activeCustomers.length; // นับเฉพาะสมาชิกที่ยังใช้งานอยู่
      final activeMembers = activeCustomers.length; // จำนวนสมาชิกที่ใช้งานอยู่
      final totalPoints = activeCustomers.fold<double>(0.0, (sum, c) => sum + c.points);
      final totalLifetimePoints = activeCustomers.fold<double>(0.0, (sum, c) => sum + c.lifetimePoints);

      // สถิติตามระดับ (เฉพาะสมาชิกที่ยังใช้งานอยู่)
      final tierStats = <String, int>{};
      for (final tier in _tiers) {
        final count = activeCustomers.where((c) => c.membershipTierId == tier.id).length;
        tierStats[tier.name] = count;
      }

      return {
        'totalMembers': totalMembers,
        'activeMembers': activeMembers,
        'totalPoints': totalPoints,
        'totalLifetimePoints': totalLifetimePoints,
        'averagePoints': totalMembers > 0 ? totalPoints / totalMembers : 0.0,
        'tierStats': tierStats,
        'totalTransactions': transactions.length,
      };
    } catch (e) {
      debugPrint('Error getting membership stats: $e');
      return {};
    }
  }
}
