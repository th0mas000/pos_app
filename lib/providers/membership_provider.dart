import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../services/membership_service.dart';
import 'package:drift/drift.dart';

class MembershipProvider extends ChangeNotifier {
  final AppDatabase _database;
  late final MembershipService _membershipService;
  
  List<Customer> _members = [];
  List<MembershipTier> _tiers = [];
  MembershipSetting? _settings;
  bool _isLoading = false;
  String? _error;

  MembershipProvider(this._database) {
    _membershipService = MembershipService(_database);
    _membershipService.addListener(_onMembershipServiceChanged);
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      await _membershipService.ensureInitialized();
      await loadMembers();
    } catch (e) {
      debugPrint('Error initializing membership provider: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _membershipService.removeListener(_onMembershipServiceChanged);
    super.dispose();
  }

  void _onMembershipServiceChanged() {
    _settings = _membershipService.currentSettings;
    _tiers = _membershipService.tiers;
    notifyListeners();
  }

  // Getters
  List<Customer> get members => _members;
  List<MembershipTier> get tiers => _tiers;
  MembershipSetting? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MembershipService get membershipService => _membershipService;

  // โหลดข้อมูลสมาชิก
  Future<void> loadMembers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final query = _database.select(_database.customers)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]);
      _members = await query.get();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading members: $e');
    }
  }

  // เพิ่มสมาชิกใหม่
  Future<void> addMember({
    required String name,
    String? phone,
    String? email,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // สร้างรหัสสมาชิก
      final membershipNumber = await _membershipService.generateMembershipNumber();
      
      // หาระดับสมาชิกเริ่มต้น (ระดับแรก)
      final defaultTier = _tiers.isNotEmpty ? _tiers.first : null;

      await _database.into(_database.customers).insert(
        CustomersCompanion.insert(
          name: name,
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          membershipNumber: Value(membershipNumber),
          membershipTierId: Value(defaultTier?.id),
          membershipStartDate: Value(DateTime.now()),
          birthDate: Value(birthDate),
          gender: Value(gender),
          notes: Value(notes),
        ),
      );

      await loadMembers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  // อัปเดตข้อมูลสมาชิก
  Future<void> updateMember(int id, CustomersCompanion updates) async {
    try {
      _isLoading = true;
      notifyListeners();

      await (_database.update(_database.customers)
            ..where((c) => c.id.equals(id)))
          .write(updates.copyWith(updatedAt: Value(DateTime.now())));

      await loadMembers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating member: $e');
      rethrow;
    }
  }

  // ลบสมาชิก (soft delete)
  Future<void> deleteMember(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await (_database.update(_database.customers)
            ..where((c) => c.id.equals(id)))
          .write(CustomersCompanion(
            isActive: const Value(false),
            updatedAt: Value(DateTime.now()),
          ));

      await loadMembers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting member: $e');
      rethrow;
    }
  }

  // เพิ่มแต้ม
  Future<void> addPoints(int memberId, double points, {String? description, String? notes}) async {
    try {
      final member = _members.firstWhere((m) => m.id == memberId);
      final newPoints = member.points + points;
      final newLifetimePoints = member.lifetimePoints + points;

      // อัปเดตแต้มของสมาชิก
      await (_database.update(_database.customers)
            ..where((c) => c.id.equals(memberId)))
          .write(CustomersCompanion(
            points: Value(newPoints),
            lifetimePoints: Value(newLifetimePoints),
            lastPointsEarnDate: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ));

      // บันทึกรายการ
      await _membershipService.recordPointsTransaction(
        customerId: memberId,
        type: 'earn',
        pointsAmount: points,
        pointsBalance: newPoints,
        description: description ?? 'เพิ่มแต้มจากผู้ดูแล',
        notes: notes,
      );

      // ลบระบบระดับสมาชิก - ไม่ต้องอัปเดตระดับสมาชิกแล้ว

      await loadMembers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding points: $e');
      rethrow;
    }
  }

  // ใช้แต้ม
  Future<void> redeemPoints(int memberId, double points, {String? description, String? notes}) async {
    try {
      final member = _members.firstWhere((m) => m.id == memberId);
      
      if (member.points < points) {
        throw Exception('แต้มไม่เพียงพอ');
      }

      final newPoints = member.points - points;
      final discountAmount = _membershipService.calculateDiscountFromPoints(points);

      // อัปเดตแต้มของสมาชิก
      await (_database.update(_database.customers)
            ..where((c) => c.id.equals(memberId)))
          .write(CustomersCompanion(
            points: Value(newPoints),
            updatedAt: Value(DateTime.now()),
          ));

      // บันทึกรายการ
      await _membershipService.recordPointsTransaction(
        customerId: memberId,
        type: 'redeem',
        pointsAmount: -points,
        pointsBalance: newPoints,
        discountAmount: discountAmount,
        description: description ?? 'ใช้แต้มแลกส่วนลด',
        notes: notes,
      );

      await loadMembers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error redeeming points: $e');
      rethrow;
    }
  }

  // ปรับแต้ม (adjustment)
  Future<void> adjustPoints(int memberId, double pointsChange, String reason) async {
    try {
      final member = _members.firstWhere((m) => m.id == memberId);
      final newPoints = (member.points + pointsChange).clamp(0.0, double.infinity);

      // อัปเดตแต้มของสมาชิก
      await (_database.update(_database.customers)
            ..where((c) => c.id.equals(memberId)))
          .write(CustomersCompanion(
            points: Value(newPoints),
            updatedAt: Value(DateTime.now()),
          ));

      // บันทึกรายการ
      await _membershipService.recordPointsTransaction(
        customerId: memberId,
        type: 'adjustment',
        pointsAmount: pointsChange,
        pointsBalance: newPoints,
        description: 'ปรับแต้ม: $reason',
        notes: reason,
      );

      await loadMembers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adjusting points: $e');
      rethrow;
    }
  }

  // ค้นหาสมาชิก
  List<Customer> searchMembers(String query) {
    if (query.isEmpty) return _members;
    
    final lowercaseQuery = query.toLowerCase();
    return _members.where((member) {
      return member.name.toLowerCase().contains(lowercaseQuery) ||
             (member.phone?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (member.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (member.membershipNumber?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // ดึงสมาชิกตามระดับ
  List<Customer> getMembersByTier(int? tierId) {
    if (tierId == null) return _members.where((m) => m.membershipTierId == null).toList();
    return _members.where((m) => m.membershipTierId == tierId).toList();
  }

  // ดึงสมาชิกที่มีวันเกิดในเดือนนี้
  List<Customer> getBirthdayMembers() {
    final now = DateTime.now();
    return _members.where((member) {
      if (member.birthDate == null) return false;
      return member.birthDate!.month == now.month;
    }).toList();
  }

  // ดึงสมาชิกยอดนิยม (แต้มสูงสุด)
  List<Customer> getTopMembers({int limit = 10}) {
    final sortedMembers = List<Customer>.from(_members);
    sortedMembers.sort((a, b) => b.lifetimePoints.compareTo(a.lifetimePoints));
    return sortedMembers.take(limit).toList();
  }

  // ดึงประวัติแต้มของสมาชิก
  Future<List<PointsTransaction>> getMemberPointsHistory(int memberId) async {
    return await _membershipService.getPointsHistory(memberId);
  }

  // ค้นหาสมาชิกตามรหัส
  Customer? getMemberByNumber(String membershipNumber) {
    try {
      return _members.firstWhere((m) => m.membershipNumber == membershipNumber);
    } catch (e) {
      return null;
    }
  }

  // ดึงสถิติระบบสมาชิก
  Future<Map<String, dynamic>> getMembershipStats() async {
    return await _membershipService.getMembershipStats();
  }

  // อัปเดตการตั้งค่าระบบสมาชิก
  Future<void> updateMembershipSettings(MembershipSettingsCompanion settings) async {
    try {
      await _membershipService.updateSettings(settings);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // จัดการระดับสมาชิก
  Future<void> addMembershipTier(MembershipTiersCompanion tier) async {
    try {
      await _membershipService.addTier(tier);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMembershipTier(int id, MembershipTiersCompanion tier) async {
    try {
      await _membershipService.updateTier(id, tier);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMembershipTier(int id) async {
    try {
      await _membershipService.deleteTier(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ประมวลผลแต้มหมดอายุ
  Future<void> processExpiredPoints() async {
    try {
      await _membershipService.processExpiredPoints();
      await loadMembers(); // รีโหลดข้อมูลหลังจากประมวลผล
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error processing expired points: $e');
    }
  }
}
