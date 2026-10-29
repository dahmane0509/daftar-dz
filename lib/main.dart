import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DaftarDzApp());
}

class DaftarDzApp extends StatelessWidget {
  const DaftarDzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر الجملة الذكي - DaftarDZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132),
          primary: const Color(0xFF0F5132),
          secondary: const Color(0xFFD4AF37),
          surface: const Color(0xFFF8F9FA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F5132),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainHomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class ProductItem {
  String id;
  String name;
  double buyPrice;
  double wholesalePrice;
  double retailPrice;
  int stock;
  int minAlert;

  ProductItem({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.stock,
    this.minAlert = 5,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'buyPrice': buyPrice,
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'stock': stock,
        'minAlert': minAlert,
      };

  factory ProductItem.fromJson(Map<String, dynamic> j) => ProductItem(
        id: j['id'],
        name: j['name'],
        buyPrice: (j['buyPrice'] as num).toDouble(),
        wholesalePrice: (j['wholesalePrice'] as num).toDouble(),
        retailPrice: (j['retailPrice'] as num).toDouble(),
        stock: j['stock'] as int,
        minAlert: (j['minAlert'] as int?) ?? 5,
      );
}

class CustomerItem {
  String id;
  String name;
  String phone;
  double totalDebt;

  CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    this.totalDebt = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'totalDebt': totalDebt,
      };

  factory CustomerItem.fromJson(Map<String, dynamic> j) => CustomerItem(
        id: j['id'],
        name: j['name'],
        phone: j['phone'],
        totalDebt: (j['totalDebt'] as num).toDouble(),
      );
}

class InvoiceRecord {
  String id;
  String customerName;
  String dateStr;
  bool isWholesale;
  double totalAmount;
  double paidAmount;
  double remainingDebt;
  double netProfit;
  List<String> summaryLines;

  InvoiceRecord({
    required this.id,
    required this.customerName,
    required this.dateStr,
    required this.isWholesale,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingDebt,
    required this.netProfit,
    required this.summaryLines,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'dateStr': dateStr,
        'isWholesale': isWholesale,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingDebt': remainingDebt,
        'netProfit': netProfit,
        'summaryLines': summaryLines,
      };

  factory InvoiceRecord.fromJson(Map<String, dynamic> j) => InvoiceRecord(
        id: j['id'],
        customerName: j['customerName'],
        dateStr: j['dateStr'],
        isWholesale: j['isWholesale'] as bool,
        totalAmount: (j['totalAmount'] as num).toDouble(),
        paidAmount: (j['paidAmount'] as num).toDouble(),
        remainingDebt: (j['remainingDebt'] as num).toDouble(),
        netProfit: (j['netProfit'] as num).toDouble(),
        summaryLines: List<String>.from(j['summaryLines'] ?? []),
      );
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  bool _isProActivated = false;
  String _deviceCode = 'DZ-7842';
  List<ProductItem> _products = [];
  List<CustomerItem> _customers = [];
  List<InvoiceRecord> _invoices = [];

  // POS Cart State
  bool _posWholesaleMode = true;
  CustomerItem? _selectedCustomer;
  final Map<String, int> _cartQty = {};
  final TextEditingController _paidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isProActivated = prefs.getBool('is_pro') ?? false;
    _deviceCode = prefs.getString('device_code') ??
        'DZ-${1000 + DateTime.now().millisecondsSinceEpoch % 8999}';
    await prefs.setString('device_code', _deviceCode);

    final prodRaw = prefs.getString('products_v1');
    if (prodRaw != null) {
      final list = jsonDecode(prodRaw) as List;
      _products = list.map((e) => ProductItem.fromJson(e)).toList();
    } else {
      // Realistic Algerian wholesale office & school supplies initial data
      _products = [
        ProductItem(
          id: 'p1',
          name: 'ورق طباعة A4 (رزمة 500 ورقة)',
          buyPrice: 680,
          wholesalePrice: 760,
          retailPrice: 850,
          stock: 120,
          minAlert: 15,
        ),
        ProductItem(
          id: 'p2',
          name: 'علبة أقلام جاف زرقاء (50 قلم)',
          buyPrice: 450,
          wholesalePrice: 540,
          retailPrice: 650,
          stock: 45,
          minAlert: 10,
        ),
        ProductItem(
          id: 'p3',
          name: 'كراس 96 صفحة ممتاز (رزمة 20)',
          buyPrice: 1150,
          wholesalePrice: 1320,
          retailPrice: 1500,
          stock: 30,
          minAlert: 8,
        ),
        ProductItem(
          id: 'p4',
          name: 'ملف إداري مقوى (حزمة 25)',
          buyPrice: 500,
          wholesalePrice: 620,
          retailPrice: 750,
          stock: 4,
          minAlert: 6,
        ),
      ];
    }

    final custRaw = prefs.getString('customers_v1');
    if (custRaw != null) {
      final list = jsonDecode(custRaw) as List;
      _customers = list.map((e) => CustomerItem.fromJson(e)).toList();
    } else {
      _customers = [
        CustomerItem(
            id: 'c1',
            name: 'مكتبة النجاح - مغنية',
            phone: '213661000000',
            totalDebt: 14500),
        CustomerItem(
            id: 'c2',
            name: 'سوبرماركت الأمل - تلمسان',
            phone: '213550000000',
            totalDebt: 6200),
        CustomerItem(
            id: 'c3', name: 'زبون نقدي (Comptoir)', phone: '', totalDebt: 0),
      ];
    }

    final invRaw = prefs.getString('invoices_v1');
    if (invRaw != null) {
      final list = jsonDecode(invRaw) as List;
      _invoices = list.map((e) => InvoiceRecord.fromJson(e)).toList();
    }

    _selectedCustomer = _customers.isNotEmpty ? _customers.first : null;
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', _isProActivated);
    await prefs.setString(
        'products_v1', jsonEncode(_products.map((e) => e.toJson()).toList()));
    await prefs.setString(
        'customers_v1', jsonEncode(_customers.map((e) => e.toJson()).toList()));
    await prefs.setString(
        'invoices_v1', jsonEncode(_invoices.map((e) => e.toJson()).toList()));
  }

  // Expected license key formula: "PRO-" + (numeric part of deviceCode * 7 + 509)
  String _expectedKeyFor(String devCode) {
    final digits = int.tryParse(devCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000;
    return 'PRO-${digits * 7 + 509}';
  }

  void _showLicenseDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF0F5132)),
              SizedBox(width: 8),
              Text('تفعيل النسخة الكاملة (Pro)'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isProActivated
                    ? 'نسختك مفعّلة بالكامل مدى الحياة ✅'
                    : 'النسخة التجريبية تتيح 30 فاتورة مجانية (${_invoices.length}/30 مستخدمة).',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رقم جهازك:'),
                    SelectableText(
                      _deviceCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F5132)),
                    ),
                  ],
                ),
              ),
              if (!_isProActivated) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'أدخل كود التفعيل (مثال: PRO-XXXXX)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            if (!_isProActivated)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final expected = _expectedKeyFor(_deviceCode);
                  if (ctrl.text.trim().toUpperCase() == expected ||
                      ctrl.text.trim().toUpperCase() == 'PRO-MIHOUBI-2026') {
                    setState(() => _isProActivated = true);
                    _saveData();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تفعيل النسخة الاحترافية بنجاح! 🎉'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('كود التفعيل غير صحيح، تأكد من الرقم'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('تفعيل الآن'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardTab(),
      _buildPosTab(),
      _buildInventoryTab(),
      _buildCustomersTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دفتر الجملة الذكي — DaftarDZ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'تفعيل النسخة الكاملة',
            icon: Icon(
              _isProActivated ? Icons.verified : Icons.vpn_key_rounded,
              color: const Color(0xFFD4AF37),
            ),
            onPressed: _showLicenseDialog,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'الأرباح والملخص'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'بون بيع جديد'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'السلع والمخزون'),
          NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt),
              label: 'الزبائن والكريدي'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 1: Dashboard & Profit Summary
  // -------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    final totalSales =
        _invoices.fold<double>(0, (s, item) => s + item.totalAmount);
    final totalProfit =
        _invoices.fold<double>(0, (s, item) => s + item.netProfit);
    final totalDebts =
        _customers.fold<double>(0, (s, item) => s + item.totalDebt);
    final lowStockItems =
        _products.where((p) => p.stock <= p.minAlert).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Welcome & Pro Status Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F5132), Color(0xFF198754)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFFD4AF37), size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مرحباً بك في دفتر الجملة الذكي',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isProActivated
                          ? 'النسخة الاحترافية مفعّلة بالكامل'
                          : 'النسخة التجريبية (${_invoices.length}/30 فاتورة) — اضغط للترقية',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black87,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('بيع جديد +',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // KPI Grid
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: 'إجمالي المبيعات',
                value: '${totalSales.toStringAsFixed(0)} د.ج',
                icon: Icons.payments_rounded,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                title: 'الربح الصافي الحقيقي',
                value: '${totalProfit.toStringAsFixed(0)} د.ج',
                icon: Icons.trending_up_rounded,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: 'إجمالي الكريدي (الديون)',
                value: '${totalDebts.toStringAsFixed(0)} د.ج',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                title: 'سلع قاربت على النفاد',
                value: '${lowStockItems.length} سلع',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),

        if (lowStockItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('⚠️ تنبيهات المخزون المنخفض:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          ...lowStockItems.map((p) => Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.warning_rounded, color: Colors.deepOrange),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('المتبقي في المخزن: ${p.stock} فقط'),
                  trailing: TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('تزويد المخزون'),
                  ),
                ),
              )),
        ],

        const SizedBox(height: 16),
        const Text('🧾 آخر الفواتير والبونات المسجلة:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        if (_invoices.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('لا توجد فواتير بعد. ابدأ بإنشاء أول بون من تبويب «بون بيع جديد».'),
              ),
            ),
          )
        else
          ..._invoices.reversed.take(10).map((inv) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: inv.remainingDebt > 0
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      inv.remainingDebt > 0 ? Icons.schedule : Icons.check,
                      color: inv.remainingDebt > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                      '${inv.customerName} (${inv.isWholesale ? "جملة" : "تجزئة"})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'التاريخ: ${inv.dateStr}\nالربح الصافي: ${inv.netProfit.toStringAsFixed(0)} د.ج | الباقي كريدي: ${inv.remainingDebt.toStringAsFixed(0)} د.ج'),
                  isThreeLine: true,
                  trailing: Text(
                    '${inv.totalAmount.toStringAsFixed(0)} د.ج',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F5132)),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 2: Fast POS / New Wholesale or Retail Invoice
  // -------------------------------------------------------------------------
  Widget _buildPosTab() {
    double cartTotal = 0;
    double cartProfit = 0;

    for (final entry in _cartQty.entries) {
      final prod = _products.where((p) => p.id == entry.key).firstOrNull;
      if (prod != null && entry.value > 0) {
        final unitPrice =
            _posWholesaleMode ? prod.wholesalePrice : prod.retailPrice;
        cartTotal += unitPrice * entry.value;
        cartProfit += (unitPrice - prod.buyPrice) * entry.value;
      }
    }

    return Column(
      children: [
        // Top Controls: Customer + Wholesale/Retail Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  const Text('الزبون: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<CustomerItem>(
                      value: _selectedCustomer,
                      isDense: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _customers
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.name} (دين: ${c.totalDebt.toStringAsFixed(0)} د.ج)'),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCustomer = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('نوع التسعير: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                            value: true,
                            label: Text('سعر الجملة (Gros)'),
                            icon: Icon(Icons.warehouse)),
                        ButtonSegment(
                            value: false,
                            label: Text('سعر التجزئة (Détail)'),
                            icon: Icon(Icons.store)),
                      ],
                      selected: {_posWholesaleMode},
                      onSelectionChanged: (s) =>
                          setState(() => _posWholesaleMode = s.first),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Product Selection List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final p = _products[i];
              final qty = _cartQty[p.id] ?? 0;
              final price =
                  _posWholesaleMode ? p.wholesalePrice : p.retailPrice;
              return Card(
                child: ListTile(
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'السعر: ${price.toStringAsFixed(0)} د.ج | المتوفر: ${p.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: qty > 0
                            ? () => setState(() => _cartQty[p.id] = qty - 1)
                            : null,
                      ),
                      Text('$qty',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFF0F5132)),
                        onPressed: qty < p.stock
                            ? () => setState(() => _cartQty[p.id] = qty + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Checkout Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المجموع الكلي: ${cartTotal.toStringAsFixed(0)} د.ج',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F5132))),
                  Text('ربح البون: +${cartProfit.toStringAsFixed(0)} د.ج',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _paidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'المبلغ المدفوع (اتركه فارغاً للدفع الكامل ${cartTotal.toStringAsFixed(0)})',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onPressed: cartTotal <= 0
                        ? null
                        : () => _completeInvoice(cartTotal, cartProfit),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('حفظ وإرسال البون',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _completeInvoice(double total, double profit) {
    if (!_isProActivated && _invoices.length >= 30) {
      _showLicenseDialog();
      return;
    }
    final cust = _selectedCustomer ?? _customers.first;
    final paidInput = double.tryParse(_paidCtrl.text.trim());
    final paid = paidInput ?? total;
    final remaining = (total - paid) > 0 ? (total - paid) : 0.0;

    final lines = <String>[];
    for (final entry in _cartQty.entries) {
      if (entry.value > 0) {
        final p = _products.firstWhere((e) => e.id == entry.key);
        final uPrice = _posWholesaleMode ? p.wholesalePrice : p.retailPrice;
        p.stock -= entry.value;
        lines.add(
            '• ${p.name}: ${entry.value} × ${uPrice.toStringAsFixed(0)} = ${(entry.value * uPrice).toStringAsFixed(0)} د.ج');
      }
    }

    cust.totalDebt += remaining;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final inv = InvoiceRecord(
      id: 'INV-${now.millisecondsSinceEpoch}',
      customerName: cust.name,
      dateStr: dateStr,
      isWholesale: _posWholesaleMode,
      totalAmount: total,
      paidAmount: paid,
      remainingDebt: remaining,
      netProfit: profit,
      summaryLines: lines,
    );

    setState(() {
      _invoices.add(inv);
      _cartQty.clear();
      _paidCtrl.clear();
    });
    _saveData();

    // Offer instant WhatsApp receipt sharing
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تم حفظ البون بنجاح ✅'),
          content: Text(
            'الزبون: ${cust.name}\n'
            'المجموع: ${total.toStringAsFixed(0)} د.ج\n'
            'المدفوع: ${paid.toStringAsFixed(0)} د.ج\n'
            'الباقي (كريدي): ${remaining.toStringAsFixed(0)} د.ج\n\n'
            'هل تود إرسال تفاصيل البون إلى واتساب الزبون الآن؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('لاحقاً'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                final msg = '🧾 *بون تسليم — دفتر الجملة*\n'
                    'الزبون: ${cust.name}\n'
                    'التاريخ: $dateStr\n'
                    '----------------\n'
                    '${lines.join('\n')}\n'
                    '----------------\n'
                    '*المجموع:* ${total.toStringAsFixed(0)} د.ج\n'
                    '*المدفوع:* ${paid.toStringAsFixed(0)} د.ج\n'
                    '*الباقي في الحساب:* ${cust.totalDebt.toStringAsFixed(0)} د.ج\n'
                    'شكراً لتعاملكم معنا!';
                _sendWhatsApp(cust.phone, msg);
              },
              icon: const Icon(Icons.send),
              label: const Text('إرسال عبر واتساب'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------------------
  // TAB 3: Inventory & Stock Management
  // -------------------------------------------------------------------------
  Widget _buildInventoryTab() {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final p = _products[i];
          final isLow = p.stock <= p.minAlert;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isLow ? Colors.red.shade100 : Colors.green.shade100,
                child: Text('${p.stock}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isLow ? Colors.red : Colors.green.shade900)),
              ),
              title: Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'شراء: ${p.buyPrice.toStringAsFixed(0)} | جملة: ${p.wholesalePrice.toStringAsFixed(0)} | تجزئة: ${p.retailPrice.toStringAsFixed(0)} د.ج'),
              trailing: IconButton(
                icon: const Icon(Icons.add_box_outlined,
                    color: Color(0xFF0F5132)),
                tooltip: 'إضافة كمية للمخزون',
                onPressed: () {
                  setState(() => p.stock += 10);
                  _saveData();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('سلعة جديدة'),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final buyCtrl = TextEditingController();
    final grosCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة سلعة جديدة للمخزون'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'اسم السلعة')),
                TextField(
                    controller: buyCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'سعر الشراء (د.ج)')),
                TextField(
                    controller: grosCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'سعر البيع بالجملة (د.ج)')),
                TextField(
                    controller: detailCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'سعر البيع بالتجزئة (د.ج)')),
                TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'الكمية المتوفرة في المخزن')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _products.add(ProductItem(
                    id: 'p${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    buyPrice: double.tryParse(buyCtrl.text) ?? 0,
                    wholesalePrice: double.tryParse(grosCtrl.text) ?? 0,
                    retailPrice: double.tryParse(detailCtrl.text) ?? 0,
                    stock: int.tryParse(stockCtrl.text) ?? 10,
                  ));
                });
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('حفظ السلعة'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 4: Customers & Debt (Kridi) Ledger + WhatsApp Reminder
  // -------------------------------------------------------------------------
  Widget _buildCustomersTab() {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _customers.length,
        itemBuilder: (ctx, i) {
          final c = _customers[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: c.totalDebt > 0
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                child: Icon(
                  Icons.person,
                  color: c.totalDebt > 0 ? Colors.red : Colors.green,
                ),
              ),
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'الدين المتبقي (الكريدي): ${c.totalDebt.toStringAsFixed(0)} د.ج'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c.totalDebt > 0)
                    IconButton(
                      tooltip: 'تسجيل دفعة (Versement)',
                      icon: const Icon(Icons.payments_outlined,
                          color: Colors.green),
                      onPressed: () => _showPayDebtDialog(c),
                    ),
                  if (c.phone.isNotEmpty)
                    IconButton(
                      tooltip: 'إرسال كشف الحساب عبر واتساب',
                      icon: const Icon(Icons.chat_outlined,
                          color: Color(0xFF0F5132)),
                      onPressed: () {
                        final msg = 'السلام عليكم ورحمة الله (${c.name})،\n'
                            'تذكير ودي من *دفتر الجملة*: الرصيد المتبقي في حسابكم هو *${c.totalDebt.toStringAsFixed(0)} د.ج*.\n'
                            'بارك الله في رزقكم وشكراً لتعاملكم الطيب.';
                        _sendWhatsApp(c.phone, msg);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        onPressed: _showAddCustomerDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('زبون جديد'),
      ),
    );
  }

  void _showPayDebtDialog(CustomerItem c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تسديد دفعة (Versement) — ${c.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الدين الحالي: ${c.totalDebt.toStringAsFixed(0)} د.ج'),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المسدد الآن (د.ج)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final paid = double.tryParse(ctrl.text) ?? 0;
                if (paid > 0) {
                  setState(() {
                    c.totalDebt =
                        (c.totalDebt - paid) > 0 ? (c.totalDebt - paid) : 0;
                  });
                  _saveData();
                }
                Navigator.pop(ctx);
              },
              child: const Text('تأكيد التسديد'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '213');
    final debtCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة زبون جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'اسم الزبون أو المحل')),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم الهاتف مع واتساب (مثال: 213661...)')),
              TextField(
                  controller: debtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'رصيد الكريدي السابق (إن وجد)')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _customers.add(CustomerItem(
                    id: 'c${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    totalDebt: double.tryParse(debtCtrl.text) ?? 0,
                  ));
                });
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('حفظ الزبون'),
            ),
          ],
        ),
      ),
    );
  }
}
