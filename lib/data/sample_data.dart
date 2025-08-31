// // Sample data that will be inserted when the app first runs
// // You can modify this to add your own sample products

// import 'package:drift/drift.dart';
// import '../database/database.dart';

// class SampleData {
//   static Future<void> insertSampleProducts(AppDatabase database) async {
//     // Check if products already exist
//     final existingProducts = await database.select(database.products).get();
//     if (existingProducts.isNotEmpty) return;

//     // Get categories
//     final categories = await database.select(database.categories).get();
//     final foodCategoryId = categories.firstWhere((c) => c.name == 'อาหาร').id;
//     final drinkCategoryId = categories.firstWhere((c) => c.name == 'เครื่องดื่ม').id;

//     // Sample food products
//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'ข้าวผัดกุ้ง',
//       description: const Value('ข้าวผัดกุ้งสูตรพิเศษ'),
//       categoryId: Value(foodCategoryId),
//       price: 120.0,
//       cost: const Value(60.0),
//       stock: const Value(50),
//       unit: const Value('จาน'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'ผัดไทย',
//       description: const Value('ผัดไทยแท้รสเด็ด'),
//       categoryId: Value(foodCategoryId),
//       price: 100.0,
//       cost: const Value(50.0),
//       stock: const Value(30),
//       unit: const Value('จาน'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'ส้มตำ',
//       description: const Value('ส้มตำไทยรสจัดจ้าน'),
//       categoryId: Value(foodCategoryId),
//       price: 80.0,
//       cost: const Value(35.0),
//       stock: const Value(25),
//       unit: const Value('จาน'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'ต้มยำกุ้ง',
//       description: const Value('ต้มยำกุ้งน้ำใส'),
//       categoryId: Value(foodCategoryId),
//       price: 150.0,
//       cost: const Value(75.0),
//       stock: const Value(20),
//       unit: const Value('ชาม'),
//     ));

//     // Sample drink products
//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'น้ำเปล่า',
//       description: const Value('น้ำดื่มบริสุทธิ์'),
//       categoryId: Value(drinkCategoryId),
//       price: 15.0,
//       cost: const Value(8.0),
//       stock: const Value(100),
//       unit: const Value('ขวด'),
//       barcode: const Value('1234567890123'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'โค้ก',
//       description: const Value('โคคาโคล่า 325 มล.'),
//       categoryId: Value(drinkCategoryId),
//       price: 25.0,
//       cost: const Value(15.0),
//       stock: const Value(80),
//       unit: const Value('ขวด'),
//       barcode: const Value('1234567890124'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'น้ำส้ม',
//       description: const Value('น้ำส้มคั้นสด'),
//       categoryId: Value(drinkCategoryId),
//       price: 35.0,
//       cost: const Value(20.0),
//       stock: const Value(40),
//       unit: const Value('แก้ว'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'กาแฟเย็น',
//       description: const Value('กาแฟเย็นหอมกรุ่น'),
//       categoryId: Value(drinkCategoryId),
//       price: 45.0,
//       cost: const Value(25.0),
//       stock: const Value(35),
//       unit: const Value('แก้ว'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'ชาไทย',
//       description: const Value('ชาไทยเข้มข้น'),
//       categoryId: Value(drinkCategoryId),
//       price: 40.0,
//       cost: const Value(22.0),
//       stock: const Value(30),
//       unit: const Value('แก้ว'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'น้ำแข็งใส',
//       description: const Value('น้ำแข็งใสสะอาด'),
//       categoryId: Value(drinkCategoryId),
//       price: 10.0,
//       cost: const Value(5.0),
//       stock: const Value(200),
//       unit: const Value('ถุง'),
//     ));

//     // Products with low stock for testing validation
//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'ขนมโดรายากิ',
//       description: const Value('ขนมหวานญี่ปุ่น'),
//       categoryId: Value(foodCategoryId),
//       price: 60.0,
//       cost: const Value(30.0),
//       stock: const Value(3), // Low stock for testing
//       unit: const Value('ชิ้น'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'น้ำปลาร้า',
//       description: const Value('น้ำปลาร้าแท้'),
//       categoryId: Value(foodCategoryId),
//       price: 25.0,
//       cost: const Value(12.0),
//       stock: const Value(1), // Very low stock for testing
//       unit: const Value('ขวด'),
//     ));

//     await database.into(database.products).insert(ProductsCompanion.insert(
//       name: 'อาหารหมด',
//       description: const Value('สินค้าที่หมดแล้ว'),
//       categoryId: Value(foodCategoryId),
//       price: 99.0,
//       cost: const Value(50.0),
//       stock: const Value(0), // Zero stock for testing
//       unit: const Value('ชิ้น'),
//     ));
//   }
// }
