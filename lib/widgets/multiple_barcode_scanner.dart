import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';

class MultipleBarcodeScanner extends StatefulWidget {
  final Future<bool> Function(Product) onProductScanned;

  const MultipleBarcodeScanner({
    super.key,
    required this.onProductScanned,
  });

  @override
  State<MultipleBarcodeScanner> createState() => _MultipleBarcodeScannerState();
}

class _MultipleBarcodeScannerState extends State<MultipleBarcodeScanner> {
  late MobileScannerController controller;
  bool isScanning = true;
  bool isTorchOn = false;
  int scannedCount = 0;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      formats: [BarcodeFormat.all],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;
    
    setState(() {
      isScanning = false;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        final product = await _findProductByBarcode(code);
        
        if (mounted) {
          if (product != null) {
            // เพิ่มสินค้าลงในตะกร้าผ่าน callback
            final success = await widget.onProductScanned(product);
            
            if (success) {
              setState(() {
                scannedCount++;
              });
              
              // เปิดการสแกนต่อหลังจากหน่วงเวลาเล็กน้อย
              await Future.delayed(const Duration(milliseconds: 1500));
            }
          } else {
            // แสดง dialog สินค้าไม่พบ
            _showProductNotFoundDialog(code);
            return; // ไม่เปิดการสแกนต่อ ให้ผู้ใช้กดปุ่มเอง
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {
        isScanning = true;
      });
    }
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ไม่พบสินค้า'),
        content: Text('ไม่พบสินค้าที่มีรหัส: $barcode'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
              });
            },
            child: const Text('สแกนต่อ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualBarcodeDialog();
            },
            child: const Text('ใส่รหัสด้วยตนเอง'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualBarcodeDialog() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ใส่รหัสสินค้า'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'สแกนหรือพิมพ์รหัสสินค้า',
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          autofocus: true,
          onSubmitted: (value) async {
            final product = await _findProductByBarcode(value);
            if (context.mounted) {
              if (product != null) {
                Navigator.of(context).pop(true);
                await widget.onProductScanned(product);
                setState(() {
                  scannedCount++;
                  isScanning = true;
                });
              } else {
                Navigator.of(context).pop(false);
                _showProductNotFoundDialog(value);
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final product = await _findProductByBarcode(controller.text);
              if (context.mounted) {
                if (product != null) {
                  Navigator.of(context).pop(true);
                  await widget.onProductScanned(product);
                  setState(() {
                    scannedCount++;
                    isScanning = true;
                  });
                } else {
                  Navigator.of(context).pop(false);
                  _showProductNotFoundDialog(controller.text);
                }
              }
            },
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );

    // หากผู้ใช้ยกเลิก ให้เปิดการสแกนต่อ
    if (result != true && mounted) {
      setState(() {
        isScanning = true;
      });
    }
  }

  Future<Product?> _findProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;
    
    final database = AppDatabase();
    final products = await (database.select(database.products)
      ..where((p) => p.barcode.equals(barcode))).get();
    
    return products.isNotEmpty ? products.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สแกนสินค้า'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios),
          ),
          IconButton(
            onPressed: _showManualBarcodeDialog,
            icon: const Icon(Icons.keyboard),
            tooltip: 'ใส่รหัสด้วยตนเอง',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppTheme.primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'วางบาร์โค้ดให้อยู่ในกรอบ\nสแกนแล้ว $scannedCount รายการ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showManualBarcodeDialog,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('ใส่รหัสเอง'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 204, 204, 204),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check),
                        label: const Text('เสร็จสิ้น'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 124, 226, 127),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // แสดงสถานะการสแกน
          if (!isScanning)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'กำลังประมวลผล...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path cutOut = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, path, cutOut);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    final Rect cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double borderLengthBounded = borderLength > cutOutSize / 2
        ? cutOutSize / 2
        : borderLength;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + borderLengthBounded)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.top,
            cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + borderLengthBounded, cutOutRect.top),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLengthBounded, cutOutRect.top)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.top,
            cutOutRect.right, cutOutRect.top + borderRadius)
        ..lineTo(cutOutRect.right, cutOutRect.top + borderLengthBounded),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.bottom - borderLengthBounded)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.bottom,
            cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + borderLengthBounded, cutOutRect.bottom),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLengthBounded, cutOutRect.bottom)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.bottom,
            cutOutRect.right, cutOutRect.bottom - borderRadius)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderLengthBounded),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
