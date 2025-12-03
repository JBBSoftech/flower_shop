import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';


// Dynamic Product Data
final List<Map<String, dynamic>> productCards = [
  {
      'id': 'jdch19yqh',
      'productName': 'Rose',
      'price': '250',
      'discountPrice': '20',
      'imageAsset': 'data:image/png;base64,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',
      'category': 'Piece',
    },
  {
      'id': 'p9xwbc8cn',
      'productName': 'Sun Flower',
      'price': '150',
      'discountPrice': '30',
      'imageAsset': 'data:image/png;base64,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',
      'category': 'Piece',
    },
  {
      'id': 'ni0byi5vc',
      'productName': 'Tea',
      'price': '50',
      'discountPrice': '10',
      'imageAsset': 'data:image/png;base64,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',
      'category': 'Piece',
    }
];

// Dynamic GST Configuration
final String gstNumber = '18';
final String selectedCategory = 'Piece';

// Dynamic Store Information
final Map<String, dynamic> storeInfo = {
  'storeName': 'My Store',
  'address': '123 Main St',
  'email': 'support@example.com',
  'phone': '(123) 456-7890',
  'storeLogo': '',
};

// Dynamic Order Summary Configuration
final Map<String, dynamic> orderSummaryConfig = {
  'subtotal': 0.00,
  'shipping': 5.99,
  'tax': 0.00,
  'discount': 0.00,
  'total': 0.00,
};


// Environment configuration
class Environment {
  static const String apiBase = 'http://localhost:5000'; // Update with your backend URL
}

// Real-time data service for instant updates
class DataService {
  static const String baseUrl = '${Environment.apiBase}/api';
  static Timer? _refreshTimer;
  
  static void startAutoRefresh(Function onDataUpdate) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/get-dynamic-fields/USER_ID_PLACEHOLDER'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            onDataUpdate(data['data']);
          }
        }
      } catch (e) {
        print('Error fetching updates: $e');
      }
    });
  }
  
  static void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'My Store',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}

// Cart item model with dynamic pricing
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

// Cart manager with dynamic GST calculation
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  final List<CartItem> _wishlistItems = [];
  String _gstNumber = gstNumber;
  
  List<CartItem> get items => List.unmodifiable(_items);
  List<CartItem> get wishlistItems => List.unmodifiable(_wishlistItems);
  
  void updateGstNumber(String newGstNumber) {
    _gstNumber = newGstNumber;
    notifyListeners();
  }
  
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
  
  void addToWishlist(CartItem item) {
    final existingIndex = _wishlistItems.indexWhere((i) => i.id == item.id);
    if (existingIndex < 0) {
      _wishlistItems.add(item);
      notifyListeners();
    }
  }
  
  void removeFromWishlist(String id) {
    _wishlistItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  bool isInWishlist(String id) {
    return _wishlistItems.any((item) => item.id == id);
  }
  
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => 
      sum + ((item.price - item.effectivePrice) * item.quantity));
  }
  
  double get gstAmount {
    return subtotal * (double.tryParse(_gstNumber) ?? 18) / 100;
  }
  
  double get finalTotal {
    return subtotal + gstAmount;
  }
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
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _currentProductCards = [];
  String _currentGstNumber = gstNumber;
  Map<String, dynamic> _currentStoreInfo = Map.from(storeInfo);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _currentProductCards = List.from(productCards);
    _filteredProducts = List.from(_currentProductCards);
    
    // Start real-time data updates
    DataService.startAutoRefresh(_onDataUpdate);
  }

  @override
  void dispose() {
    _pageController.dispose();
    DataService.stopAutoRefresh();
    super.dispose();
  }
  
  void _onDataUpdate(Map<String, dynamic> newData) {
    setState(() {
      // Update product cards
      if (newData['productCards'] != null) {
        _currentProductCards = List<Map<String, dynamic>>.from(newData['productCards']);
        _filteredProducts = _currentProductCards
            .where((product) => product['productName']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
      }
      
      // Update GST number
      if (newData['gstNumber'] != null) {
        _currentGstNumber = newData['gstNumber'];
        _cartManager.updateGstNumber(_currentGstNumber);
      }
      
      // Update store info
      if (newData['storeInfo'] != null) {
        _currentStoreInfo = Map<String, dynamic>.from(newData['storeInfo']);
      }
    });
  }

  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildHomePage(),
          _buildCartPage(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStoreInfo['storeName'] ?? 'My Store'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Manual refresh
              DataService.startAutoRefresh(_onDataUpdate);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing data...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filteredProducts = _currentProductCards
                      .where((product) => product['productName']
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
          ),
          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // FIXED: Proper price parsing without unescaped dollar signs
    final price = product['price']?.toString() ?? '0';
    final discountPrice = product['discountPrice']?.toString() ?? '';
    
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: product['imageAsset'] != null && product['imageAsset'].isNotEmpty
                  ? Image.memory(
                      base64Decode(product['imageAsset'].split(',')[1]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                    )
                  : const Icon(Icons.image, size: 50),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['productName'] ?? 'Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (discountPrice.isNotEmpty)
                      Text(
                        '\$$price',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      discountPrice.isNotEmpty ? '\$$discountPrice' : '\$$price',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          final cartItem = CartItem(
                            id: product['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            name: product['productName'] ?? 'Product',
                            price: double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
                            discountPrice: double.tryParse(discountPrice.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
                            image: product['imageAsset'],
                          );
                          _cartManager.addItem(cartItem);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${product['productName']} added to cart!'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'VIEW CART',
                                textColor: Colors.white,
                                onPressed: () {
                                  _onItemTapped(1);
                                },
                              ),
                            ),
                          );
                        },
                        child: const Text('Add to Cart'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ListenableBuilder(
                        listenable: _cartManager,
                        builder: (context, child) {
                          final isInWishlist = _cartManager.isInWishlist(product['id'] ?? '');
                          return IconButton(
                            onPressed: () {
                              final cartItem = CartItem(
                                id: product['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                name: product['productName'] ?? 'Product',
                                price: double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
                                discountPrice: double.tryParse(discountPrice.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
                                image: product['imageAsset'],
                              );
                              
                              if (isInWishlist) {
                                _cartManager.removeFromWishlist(cartItem.id);
                              } else {
                                _cartManager.addToWishlist(cartItem);
                              }
                            },
                            icon: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWishlist ? Colors.red : Colors.grey,
                            ),
                          );
                        },
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
      body: ListenableBuilder(
        listenable: _cartManager,
        builder: (context, child) {
          return _cartManager.items.isEmpty
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
                                    child: item.image != null && item.image!.isNotEmpty
                                        ? Image.memory(
                                            base64Decode(item.image!.split(',')[1]),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                          )
                                        : const Icon(Icons.image),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('\$${item.effectivePrice.toStringAsFixed(2)}', 
                                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          _buildBillRow('Subtotal', _cartManager.subtotal),
                          if (_cartManager.totalDiscount > 0)
                            _buildBillRow('Discount', _cartManager.totalDiscount, isDiscount: true),
                          _buildBillRow('GST ($_currentGstNumber%)', _cartManager.gstAmount),
                          const Divider(thickness: 1),
                          _buildBillRow('Total', _cartManager.finalTotal, isTotal: true),
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildBillRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            isDiscount 
              ? '-\$${amount.toStringAsFixed(2)}'
              : '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount 
                ? Colors.green 
                : isTotal 
                  ? Colors.black 
                  : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentStoreInfo['storeName'] ?? 'My Store',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_currentStoreInfo['email'] ?? 'support@example.com'),
                    Text(_currentStoreInfo['phone'] ?? '(123) 456-7890'),
                    const SizedBox(height: 8),
                    Text(_currentStoreInfo['address'] ?? '123 Main St'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return ListenableBuilder(
      listenable: _cartManager,
      builder: (context, child) {
        return BottomNavigationBar(
          currentIndex: _currentPageIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
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
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_cartManager.items.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}
