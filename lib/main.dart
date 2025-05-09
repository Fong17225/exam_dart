import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Đơn Hàng',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: const CardTheme(elevation: 4),
      ),
      home: const OrderPage(),
    );
  }
}

// Lớp Order để biểu diễn mỗi đơn hàng
class Order {
  final String item;
  final String itemName;
  final double price;
  final String currency;
  final int quantity;

  Order({
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  // Factory để tạo Order từ JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      item: json['Item'] as String,
      itemName: json['ItemName'] as String,
      price: (json['Price'] as num).toDouble(),
      currency: json['Currency'] as String,
      quantity: json['Quantity'] as int,
    );
  }

  // Chuyển Order thành JSON
  Map<String, dynamic> toJson() {
    return {
      'Item': item,
      'ItemName': itemName,
      'Price': price,
      'Currency': currency,
      'Quantity': quantity,
    };
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final List<Order> orders = [];
  List<Order> filteredOrders = [];
  final searchController = TextEditingController();
  final itemController = TextEditingController();
  final itemNameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  String? selectedCurrency;
  final List<String> currencies = ['USD', 'EUR', 'VND', 'JPY'];

  @override
  void initState() {
    super.initState();
    // Đọc dữ liệu từ assets/order.json
    _loadOrders();
    searchController.addListener(_filterOrders);
  }

  Future<void> _loadOrders() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/order.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      setState(() {
        orders.addAll(jsonData.map((json) => Order.fromJson(json)).toList());
        filteredOrders = List.from(orders);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi đọc order.json')),
      );
    }
  }

  void _filterOrders() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredOrders = orders
          .where((order) => order.itemName.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addOrder() {
    // Kiểm tra các trường nhập liệu
    if (itemController.text.isEmpty ||
        itemNameController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedCurrency == null ||
        quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ các trường')),
      );
      return;
    }

    try {
      final price = double.parse(priceController.text);
      final quantity = int.parse(quantityController.text);

      if (price <= 0 || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giá và số lượng phải lớn hơn 0')),
        );
        return;
      }

      final newOrder = Order(
        item: itemController.text.trim(),
        itemName: itemNameController.text.trim(),
        price: price,
        currency: selectedCurrency!,
        quantity: quantity,
      );

      setState(() {
        orders.add(newOrder);
        filteredOrders = List.from(orders);
        // Xóa nội dung các trường nhập liệu
        itemController.clear();
        itemNameController.clear();
        priceController.clear();
        quantityController.clear();
        selectedCurrency = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm đơn hàng thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dữ liệu nhập không hợp lệ')),
      );
    }
  }

  void _deleteOrder(Order order) {
    setState(() {
      orders.remove(order);
      filteredOrders = List.from(orders);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa đơn hàng')),
    );
  }

  void _downloadJson() {
    final jsonData = jsonEncode(orders.map((order) => order.toJson()).toList());
    final bytes = utf8.encode(jsonData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'order.json')
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tải xuống order.json')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Tải xuống order.json',
            onPressed: _downloadJson,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tìm kiếm
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm theo Tên Mặt Hàng',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Danh sách đơn hàng
            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(child: Text('Không tìm thấy đơn hàng'))
                  : ListView.builder(
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              order.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              'Mã: ${order.item}\n'
                              'Giá: ${order.price} ${order.currency}\n'
                              'Số lượng: ${order.quantity}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Xóa đơn hàng',
                              onPressed: () => _deleteOrder(order),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Form thêm đơn hàng
            ExpansionTile(
              title: const Text(
                'Thêm Đơn Hàng Mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                TextField(
                  controller: itemController,
                  decoration: const InputDecoration(
                    labelText: 'Mã Mặt Hàng',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: itemNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên Mặt Hàng',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Tiền Tệ',
                    border: OutlineInputBorder(),
                  ),
                  items: currencies
                      .map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCurrency = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Số Lượng',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Thêm Đơn Hàng'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    itemController.dispose();
    itemNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }
}