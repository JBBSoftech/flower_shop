import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

// Define PriceUtils class
class PriceUtils {
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency\${price.toStringAsFixed(2)}';
  }
  
  // Extract numeric value from price string with any currency symbol
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    // Remove all currency symbols and non-numeric characters except decimal point
    String numericString = priceString.replaceAll(RegExp(r'[^\\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  // Detect currency symbol from price string
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('\$')) return '\$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '\$'; // Default to dollar
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

// Cart item model
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

// Cart manager
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
  
  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => 
      sum + ((item.price - item.effectivePrice) * item.quantity));
  }
  
  double get gstAmount {
    return PriceUtils.calculateTax(subtotal, 18.0); // 18% GST
  }
  
  double get finalTotal {
    return subtotal + gstAmount;
  }
  
  double get finalTotalWithShipping {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}

// Wishlist item model
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

// Wishlist manager
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
    'productName': 'Rose',
    'imageAsset': 'data:image/png;base64,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',
    'price': '\$200',
    'discountPrice': '\$20',
  },
  {
    'productName': 'Sun Flower',
    'imageAsset': 'data:image/png;base64,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',
    'price': '150',
    'discountPrice': '30',
  }
];


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      appBarTheme: const AppBarTheme(
        elevation: 4,
        shadowColor: Colors.black38,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.grey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    ),
    home: const SplashScreen(),
    debugShowCheckedModeBanner: false,
  );
}

// API Configuration - Auto-updated with your server details
class ApiConfig {
  static String get baseUrl => Environment.apiBase;
  static const String adminObjectId = '69257132848b7a78482dca18'; // Will be replaced during publish
}

// Splash Screen - First screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _appName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchAppNameAndNavigate();
  }

  Future<void> _fetchAppNameAndNavigate() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin-element-screen/${ApiConfig.adminObjectId}/shop-name'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _appName = data['shopName'] ?? 'AppifyYours';
          });
        }
      }
    } catch (e) {
      print('Error fetching shop name: \$e');
      if (mounted) {
        setState(() {
          _appName = 'AppifyYours';
        });
      }
    }
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.shopping_bag,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                _appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.white),
              const Spacer(),
              const Text(
                'Powered by AppifyYours',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Sign In Page
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          throw Exception(data['error'] ?? 'Sign in failed');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Invalid credentials');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: \${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.shopping_bag,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAccountPage(),
                    ),
                  );
                },
                child: const Text('Create Your Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create Account Page
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,4}$').hasMatch(email);
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> _createAccount() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (!_validatePhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    if (!_validatePassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final result = await apiService.dynamicSignup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final data = result['data'];
        String message = 'Failed to create account';
        if (data is Map<String, dynamic> && data['message'] != null) {
          message = data['message'].toString();
        }
        throw Exception(message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: 2.718281828459045'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Join Us Today',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '10 digit number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email ID',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
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
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _dynamicProductCards = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _dynamicProductCards = List.from(productCards); // Fallback to static data
    _filteredProducts = List.from(_dynamicProductCards);
    _loadDynamicData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Auto-refresh every 5 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadDynamicData(showLoading: false);
    });
  }

  // Load dynamic data from backend
  Future<void> _loadDynamicData({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() => _isLoading = true);
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/app/dynamic/${ApiConfig.adminObjectId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['config'] != null) {
          final config = data['config'];
          final newProducts = List<Map<String, dynamic>>.from(config['productCards'] ?? []);
          
          setState(() {
            _dynamicProductCards = newProducts.isNotEmpty ? newProducts : productCards;
            _filterProducts(_searchQuery); // Re-apply current filter
            _isLoading = false;
          });
          print('✅ Loaded ${_dynamicProductCards.length} products from backend');
        }
      }
    } catch (e) {
      print('❌ Error loading dynamic data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);

  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
    _pageController.jumpToPage(index);
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(_dynamicProductCards);
      } else {
        _filteredProducts = _dynamicProductCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || price.contains(searchLower) || discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      default:
        return Icons.error;
    }
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
    return Column(
      children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Ramya P',
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
                          onChanged: (value) {
                            _filterProducts(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Welcome',
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
                                'Search by product name or price (e.g., "Product Name" or "\$299")',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDynamicData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    height: 160,
                    child: Stack(
                      children: [
                        Container(color: Color(0xFFBDBDBD)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome to Flower Shop',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('Buy', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            enableInfiniteScroll: true,
                            viewportFraction: 0.8,
                            enlargeFactor: 0.3,
                          ),
                          items: [
                            Builder(
                              builder: (BuildContext context) => Container(
                                width: 300,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode('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'),
                                    width: 300,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6.0, height: 6.0, margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4))),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
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
                            childAspectRatio: 1,
                          ),
                          itemCount:                           _searchQuery.isEmpty 
                              ? productCards.length 
                              : productCards.where((product) {
                                  final productName = (product['productName'] ?? '').toString().toLowerCase();
                                  final price = (product['price'] ?? '').toString().toLowerCase();
                                  final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
                                  return productName.contains(_searchQuery) || price.contains(_searchQuery) || discountPrice.contains(_searchQuery);
                                }).length,
                          itemBuilder: (context, index) {
                            final filteredProducts =                             _searchQuery.isEmpty 
                                ? productCards 
                                : productCards.where((product) {
                                    final productName = (product['productName'] ?? '').toString().toLowerCase();
                                    final price = (product['price'] ?? '').toString().toLowerCase();
                                    final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
                                    return productName.contains(_searchQuery) || price.contains(_searchQuery) || discountPrice.contains(_searchQuery);
                                  }).toList();
                            if (index >= filteredProducts.length) return const SizedBox();
                            final product = filteredProducts[index];
                            final productId = 'product_$index';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                          child:                                           product['imageAsset'] != null
                                              ? (product['imageAsset'] != null && product['imageAsset'].isNotEmpty
                                              ? (product['imageAsset'].startsWith('data:image/')
                                                  ? Image.memory(
                                                      base64Decode(product['imageAsset'].split(',')[1]),
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Image.network(
                                                      product['imageAsset'],
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    ))
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                ))
                                              : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 40),
                                          )
                                          ,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
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
                                                  price: double.tryParse(product['price']?.replaceAll('\$','') ?? '0') ?? 0.0,
                                                  discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$','') ?? '0') ?? 0.0
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
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Current/Final Price (always without strikethrough)
                                              Text(
                                                                                                product['price'] ?? '$0'
                                                ,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              // Original Price (if discount exists)
                                                                                            if (product['discountPrice'] != null && product['discountPrice'].toString().isNotEmpty)
                                                Text(
                                                  product['discountPrice'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    decoration: TextDecoration.lineThrough,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star_border, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                product['rating'] ?? '4.0',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                final cartItem = CartItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price: PriceUtils.parsePrice(product['price'] ?? '0'),
                                                  discountPrice:                                                   product['discountPrice'] != null && product['discountPrice'].toString().isNotEmpty
                                                      ? PriceUtils.parsePrice(product['discountPrice'])
                                                      : 0.0
                                                  ,
                                                  image: product['imageAsset'],
                                                );
                                                _cartManager.addItem(cartItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to cart')),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  
                                                ),
                                              ),
                                              child: const Text(
                                                'Add to Cart',
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
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
                ],
              ),
            ),
          ),
        ),
      ],
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
                                    ? (item.image!.startsWith('data:image/')
                                    ? Image.memory(
                                  base64Decode(item.image!.split(',')[1]),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                )
                                    : Image.network(
                                  item.image!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                ))
                                    : const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    // Show current price (effective price)
                                    Text(
                                      PriceUtils.formatPrice(item.effectivePrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    // Show original price if there's a discount
                                    if (item.discountPrice > 0 && item.price != item.discountPrice)
                                      Text(
                                        PriceUtils.formatPrice(item.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
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
                // Bill Summary Section
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (_cartManager.totalDiscount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('-$0.00', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GST (18%)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.gstAmount), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        },
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
                      child: item.image != null && item.image!.isNotEmpty
                          ? (item.image!.startsWith('data:image/')
                          ? Image.memory(
                        base64Decode(item.image!.split(',')[1]),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      )
                          : Image.network(
                        item.image!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      ))
                          : const Icon(Icons.image),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(250, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Refund button action
                    },
                    child: const Text(
                      'Refund',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Log out and navigate to sign in page
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_cartManager.items.length}'),
            isLabelVisible: _cartManager.items.length > 0,
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_wishlistManager.items.length}'),
            isLabelVisible: _wishlistManager.items.length > 0,
            child: const Icon(Icons.favorite),
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
