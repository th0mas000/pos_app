import 'package:flutter/material.dart';
import 'package:thaiqr/thaiqr.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PromptPayQRWidget extends StatelessWidget {
  final double amount;
  final String? phoneNumber;
  final String? nationalId;
  final String? taxId;
  
  const PromptPayQRWidget({
    super.key,
    required this.amount,
    this.phoneNumber,
    this.nationalId,
    this.taxId,
  });

  String _generateQRData() {
    // Default PromptPay ID (จะต้องตั้งค่าในแอพ)
    final String promptPayId = phoneNumber ?? 
                               nationalId ?? 
                               taxId ?? 
                               '0123456789'; // เปลี่ยนเป็นเลขที่ต้องการ
    
    try {
      final generator = ThaiQRGenerator();
      return generator.generateCodeFromMobileOrId(
        promptPayId, 
        amount.toStringAsFixed(2)
      );
    } catch (e) {
      // Fallback QR data
      return 'ERROR: Unable to generate QR Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _generateQRData();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'สแกน QR Code เพื่อชำระเงิน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (qrData != 'ERROR: Unable to generate QR Code')
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              )
            else
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'ไม่สามารถสร้าง QR Code ได้\nกรุณาตรวจสอบการตั้งค่า',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'จำนวนเงิน: ฿${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'กรุณาแจ้งยืนยันการชำระเงินหลังสแกน QR Code',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
