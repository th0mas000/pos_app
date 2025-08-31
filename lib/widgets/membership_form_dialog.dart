import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/membership_provider.dart';
import '../theme/app_theme.dart';
import 'package:drift/drift.dart' as drift;

class MembershipFormDialog extends StatefulWidget {
  final Customer? member;

  const MembershipFormDialog({
    super.key,
    this.member,
  });

  @override
  State<MembershipFormDialog> createState() => _MembershipFormDialogState();
}

class _MembershipFormDialogState extends State<MembershipFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  
  DateTime? _birthDate;
  String? _gender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _addressController = TextEditingController(text: widget.member?.address ?? '');
    _notesController = TextEditingController(text: widget.member?.notes ?? '');
    
    _birthDate = widget.member?.birthDate;
    _gender = widget.member?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.member == null ? Icons.person_add : Icons.edit,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(widget.member == null ? 'เพิ่มสมาชิกใหม่' : 'แก้ไขข้อมูลสมาชิก'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อ-นามสกุล';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 10) {
                        return 'เบอร์โทรศัพท์ต้องมีอย่างน้อย 10 หลัก';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'รูปแบบอีเมลไม่ถูกต้อง';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                // วันเกิด
                InkWell(
                  onTap: _selectBirthDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _birthDate != null
                                ? 'วันเกิด: ${_formatDate(_birthDate!)}'
                                : 'เลือกวันเกิด (ไม่บังคับ)',
                            style: TextStyle(
                              color: _birthDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        if (_birthDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _birthDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                // เพศ
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'เพศ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('ไม่ระบุ')),
                    DropdownMenuItem(value: 'male', child: Text('ชาย')),
                    DropdownMenuItem(value: 'female', child: Text('หญิง')),
                    DropdownMenuItem(value: 'other', child: Text('อื่นๆ')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacing16),
                
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveMember,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.member == null ? 'เพิ่ม' : 'บันทึก'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    
    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);

      if (widget.member == null) {
        // เพิ่มสมาชิกใหม่
        await membershipProvider.addMember(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        // แก้ไขข้อมูลสมาชิก
        await membershipProvider.updateMember(
          widget.member!.id,
          CustomersCompanion(
            name: drift.Value(_nameController.text.trim()),
            phone: drift.Value(_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim()),
            email: drift.Value(_emailController.text.trim().isEmpty ? null : _emailController.text.trim()),
            address: drift.Value(_addressController.text.trim().isEmpty ? null : _addressController.text.trim()),
            birthDate: drift.Value(_birthDate),
            gender: drift.Value(_gender),
            notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.member == null
                ? 'เพิ่มสมาชิกเรียบร้อยแล้ว'
                : 'บันทึกข้อมูลเรียบร้อยแล้ว'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
