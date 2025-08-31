import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database.dart';

class BarcodeScannerService {
  static Future<Product?> scanForProduct(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // Desktop platforms - show manual input dialog
      return await _showManualBarcodeDialog(context);
    }

    // Mobile platforms - use camera scanner
    return await Navigator.of(context).push<Product?>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
  }

  static Future<Product?> _showManualBarcodeDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    return await showDialog<Product?>(
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
              Navigator.of(context).pop(product);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final product = await _findProductByBarcode(controller.text);
              if (context.mounted) {
                Navigator.of(context).pop(product);
              }
            },
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
  }

  static Future<Product?> _findProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;
    
    final database = AppDatabase();
    final products = await (database.select(database.products)
      ..where((p) => p.barcode.equals(barcode))).get();
    
    return products.isNotEmpty ? products.first : null;
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late MobileScannerController controller;
  bool isScanning = true;

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
        final product = await BarcodeScannerService._findProductByBarcode(code);
        
        if (mounted) {
          if (product != null) {
            Navigator.of(context).pop(product);
          } else {
            // Show product not found dialog
            _showProductNotFoundDialog(code);
          }
        }
      }
    }
    
    setState(() {
      isScanning = true;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกนบาร์โค้ด'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flash_off),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios),
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
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'วางบาร์โค้ดให้อยู่ในกรอบ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      BarcodeScannerService._showManualBarcodeDialog(context)
                          .then((product) {
                        if (product != null && mounted) {
                          Navigator.of(context).pop(product);
                        }
                      });
                    },
                    child: const Text('ใส่รหัสด้วยตนเอง'),
                  ),
                ],
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
    final borderOffset = borderWidth / 2;
    final borderLengthBounded = borderLength > cutOutSize / 2 + borderOffset
        ? borderOffset
        : borderLength;
    final cutOutRect = Rect.fromLTWH(
      rect.center.dx - cutOutSize / 2,
      rect.center.dy - cutOutSize / 2,
      cutOutSize,
      cutOutSize,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        )),
    );

    canvas.drawPath(path, backgroundPaint);

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
