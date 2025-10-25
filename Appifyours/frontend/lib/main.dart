import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class AdminConfig {
  static const String adminId = '68fca1d1723fa78a8095bc70';
  static const String shopName = 'Flower Shop';
  static const String backendUrl = 'https://appifyours-backend.onrender.com';
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'shopName': shopName,
          'userData': userData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error storing user data: $e');
    }
  }
  static Future<void> storeUserOrder({
    required String userId,
    required String orderId,
    required List<Map<String, dynamic>> products,
    required double totalOrderValue,
    required int totalQuantity,
    String? paymentMethod,
    String? paymentStatus,
    Map<String, dynamic>? shippingAddress,
    String? notes,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'userId': userId,
          'orderData': {
            'orderId': orderId,
            'products': products,
            'totalOrderValue': totalOrderValue,
            'totalQuantity': totalQuantity,
            'paymentMethod': paymentMethod,
            'paymentStatus': paymentStatus,
            'shippingAddress': shippingAddress,
            'notes': notes,
          },
        }),
      );
    } catch (e) {
      print('Error storing user order: $e');
    }
  }
  static Future<void> updateUserCart({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/update-user-cart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'userId': userId,
          'cartItems': cartItems,
        }),
      );
    } catch (e) {
      print('Error updating user cart: $e');
    }
  }
  static Future<void> trackUserInteraction({
    required String userId,
    required String interactionType,
    String? target,
    Map<String, dynamic>? details,
  }) async {
    try {
      await storeUserData({
        'userId': userId,
        'interactions': [{
          'type': interactionType,
          'target': target,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        }],
      });
    } catch (e) {
      print('Error tracking user interaction: $e');
    }
  }
  static Future<void> registerUser({
    required String userId,
    required String name,
    required String email,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'shopName': shopName,
          'userData': {
            'userId': userId,
            'userInfo': {
              'name': name,
              'email': email,
              'phone': phone ?? '',
              'address': address ?? {},
              'preferences': {}
            },
            'orders': [],
            'cartItems': [],
            'wishlistItems': [],
            'interactions': [],
          },
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error registering user: $e');
    }
  }
  static Future<Map<String, dynamic>?> getDynamicConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/get-admin-config/$adminId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting dynamic config: $e');
    }
    return null;
  }
}
class PriceUtils {
  static String formatPrice(double price, {String currency = '$'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    String numericString = priceString.replaceAll(RegExp(r'[^d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('$')) return '$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '$'; // Default to dollar
  }
  static double calculateDiscountPrice(double originalPrice, double discountPercentage) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }
  static double applyShipping(double total, double shippingFee, {double freeShippingThreshold = 100.0}) {
    return total >= freeShippingThreshold ? total : total + shippingFee;
  }
}
class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  int quantity;
  final String? image;
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.quantity = 1,
    this.image,
  });
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
  double get totalPrice => effectivePrice * quantity;
}
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  void updateQuantity(String id, int quantity) {
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  double get totalWithTax {
    final tax = PriceUtils.calculateTax(subtotal, 8.0); // 8% tax
    return subtotal + tax;
  }
  double get finalTotal {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}
class WishlistItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final String? image;
  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.image,
  });
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
}
class WishlistManager extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  List<WishlistItem> get items => List.unmodifiable(_items);
  void addItem(WishlistItem item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  bool isInWishlist(String id) {
    return _items.any((item) => item.id == id);
  }
}
final List<Map<String, dynamic>> productCards = [
  {
    'productName': 'Coffee',
    'shortDescription': '100% cotton, Free size',
    'imageAsset': 'data:image/png;base64,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',
    'price': '100',
    'discountPrice': '10',
    'rating': '4.5',
    'reviewCount': '128',
    'brandName': 'Brand Name',
    'stockStatus': 'In Stock',
    'badgeText': 'New',
    'badgeColor': '#FF0000',
    'quantity': 1,
    'weight': '',
    'weightUnit': 'kg',
  }
];
void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
          elevation: 4, shadowColor: Colors.black38, color: Colors.blue, foregroundColor: Colors.white),
      cardTheme: CardThemeData(
          elevation: 3, shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final CartManager _cartManager = CartManager();
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _filteredProducts = List.from(productCards);
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);
  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
  }
  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(productCards);
      } else {
        _filteredProducts = productCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || 
                 price.contains(searchLower) || 
                 discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _currentPageIndex,
      children: [
        _buildHomePage(),
        _buildCartPage(),
        _buildWishlistPage(),
        _buildProfilePage(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Color(0xFFFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            final product = productCards[index];
                            final productId = 'product_$index';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:                               Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                      ),
                                      child: product['imageAsset'] != null
                                          ? Image.network(
                                              product['imageAsset'],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (product['shortDescription'] != null && product['shortDescription'].isNotEmpty)
                                            Text(
                                              product['shortDescription'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Brand: ' + (product['brandName'] ?? '') + '',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          Text(
                                            'Weight: ' + (product['weight'] ?? '') + '',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          Text(
                                            'Stock: ' + (product['stockStatus'] ?? '') + '',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                PriceUtils.formatPrice(
                                                  product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                      : double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: product['discountPrice'] != null ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                              if (product['discountPrice'] != null && product['price'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 6.0),
                                                  child: Text(
                                                    PriceUtils.formatPrice(double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final cartItem = CartItem(
                                                      id: productId,
                                                      name: product['productName'] ?? 'Product',
                                                      price: double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0,
                                                      discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                          ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                          : 0.0,
                                                      image: product['imageAsset'],
                                                    );
                                                    _cartManager.addItem(cartItem);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Added to cart: ${cartItem.effectivePrice.toStringAsFixed(2)}')),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    minimumSize: const Size(double.infinity, 30),
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                  ),
                                                  child: const Text('Add to Cart', style: TextStyle(fontSize: 10)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () {
                                                  if (isInWishlist) {
                                                    _wishlistManager.removeItem(productId);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Removed from wishlist')),
                                                    );
                                                  } else {
                                                    final wishlistItem = WishlistItem(
                                                      id: productId,
                                                      name: product['productName'] ?? 'Product',
                                                      price: double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0,
                                                      discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                          ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                          : 0.0,
                                                      image: product['imageAsset'],
                                                    );
                                                    _wishlistManager.addItem(wishlistItem);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Added to wishlist')),
                                                    );
                                                  }
                                                },
                                                icon: Icon(
                                                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                                                  color: isInWishlist ? Colors.red : Colors.grey,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                      ),
                                      child: product['imageAsset'] != null
                                          ? Image.network(
                                              product['imageAsset'],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'My Flower Shop',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 20),
                            if (_wishlistManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_wishlistManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (searchQuery) {
                            setState(() {
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search products by name or price',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Search by product name or price (e.g., "Product Name" or "$299")',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }
  Widget _buildCartPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: _cartManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(PriceUtils.formatPrice(item.effectivePrice)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    onPressed: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (8%):', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(PriceUtils.calculateTax(_cartManager.subtotal, 8.0)), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(5.99), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  Widget _buildWishlistPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
      ),
      body: _wishlistManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlistManager.items.length,
              itemBuilder: (context, index) {
                final item = _wishlistManager.items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                    title: Text(item.name),
                    subtitle: Text(PriceUtils.formatPrice(item.effectivePrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              discountPrice: item.discountPrice,
                              image: item.image,
                            );
                            _cartManager.addItem(cartItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                        ),
                        IconButton(
                          onPressed: () {
                            _wishlistManager.removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  Widget _buildProfilePage() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Profile Page', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (_cartManager.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cartManager.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.favorite),
              if (_wishlistManager.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_wishlistManager.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Wishlist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}