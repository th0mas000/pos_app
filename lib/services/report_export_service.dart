import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';

class ReportExportService {
  static Future<String> exportDailySalesCSV(List<Sale> sales, DateTime date) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'daily_sales_${DateFormat('yyyy-MM-dd').format(date)}.csv';
    final file = File('${directory.path}/$fileName');

    String csvContent = 'วันที่,เวลา,หมายเลขใบเสร็จ,วิธีชำระ,ยอดรวม\n';
    
    for (final sale in sales) {
      csvContent += '${DateFormat('dd/MM/yyyy').format(sale.createdAt)},'
                   '${DateFormat('HH:mm:ss').format(sale.createdAt)},'
                   '#${sale.id},'
                   '${_getPaymentMethodText(sale.paymentMethod)},'
                   '${sale.total.toStringAsFixed(2)}\n';
    }

    await file.writeAsString(csvContent, encoding: utf8);
    return file.path;
  }

  static Future<String> exportMonthlySalesCSV(List<Sale> sales, DateTime month) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'monthly_sales_${DateFormat('yyyy-MM').format(month)}.csv';
    final file = File('${directory.path}/$fileName');

    String csvContent = 'วันที่,หมายเลขใบเสร็จ,วิธีชำระ,ยอดรวม\n';
    
    for (final sale in sales) {
      csvContent += '${DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt)},'
                   '#${sale.id},'
                   '${_getPaymentMethodText(sale.paymentMethod)},'
                   '${sale.total.toStringAsFixed(2)}\n';
    }

    await file.writeAsString(csvContent, encoding: utf8);
    return file.path;
  }

  static Future<String> exportInventoryCSV(List<Product> products) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'inventory_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');

    String csvContent = 'ชื่อสินค้า,บาร์โค้ด,ราคา,จำนวนคงเหลือ,สต็อกขั้นต่ำ,สถานะ\n';
    
    for (final product in products) {
      String status;
      if (product.stock <= 0) {
        status = 'หมดสต็อก';
      } else if (product.stock <= 5) {
        status = 'สต็อกน้อย';
      } else {
        status = 'มีสต็อก';
      }

      csvContent += '${product.name},'
                   '${product.barcode ?? ''},'
                   '${product.price.toStringAsFixed(2)},'
                   '${product.stock},'
                  //  '${product.minStock},'
                   '$status\n';
    }

    await file.writeAsString(csvContent, encoding: utf8);
    return file.path;
  }

  static String _getPaymentMethodText(String paymentMethod) {
    switch (paymentMethod) {
      case 'cash':
        return 'เงินสด';
      case 'qr':
        return 'QR Code';
      case 'transfer':
        return 'โอน';
      default:
        return 'อื่นๆ';
    }
  }

  static Future<void> shareFile(String filePath, String title) async {
    // สำหรับการแชร์ไฟล์ - ในอนาคตสามารถใช้ package share_plus
    // ตอนนี้แค่แสดง dialog ที่บอกตำแหน่งไฟล์
  }
}
