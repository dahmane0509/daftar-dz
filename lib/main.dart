import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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
      title: 'دفتر الجملة الذكي - DaftarDZ v2.0.0',
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
// Constants & Models
// ---------------------------------------------------------------------------
const List<String> kDefaultCategories = [
  'وراقة',
  'أقلام',
  'كراريس',
  'أدوات مكتبية',
  'ملفات وتنظيم',
  'أخرى',
];

const List<String> kExpenseCategories = [
  'نقل وشحن',
  'كراء المحل',
  'تغليف وأكياس',
  'كهرباء وماء وإنترنت',
  'أجور وعمال',
  'مصاريف أخرى',
];

class ProductItem {
  String id;
  String name;
  double buyPrice;
  double wholesalePrice;
  double retailPrice;
  int stock;
  int minAlert;
  String? imagePath;
  String category;

  ProductItem({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.stock,
    this.minAlert = 5,
    this.imagePath,
    this.category = 'وراقة',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'buyPrice': buyPrice,
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'stock': stock,
        'minAlert': minAlert,
        'imagePath': imagePath,
        'category': category,
      };

  factory ProductItem.fromJson(Map<String, dynamic> j) => ProductItem(
        id: j['id'] as String,
        name: j['name'] as String,
        buyPrice: (j['buyPrice'] as num).toDouble(),
        wholesalePrice: (j['wholesalePrice'] as num).toDouble(),
        retailPrice: (j['retailPrice'] as num).toDouble(),
        stock: j['stock'] as int,
        minAlert: (j['minAlert'] as int?) ?? 5,
        imagePath: j['imagePath'] as String?,
        category: (j['category'] as String?) ?? 'وراقة',
      );
}

class CustomerLedgerEntry {
  String id;
  String dateStr;
  String type; // 'debt' (أخذ سلعة) or 'payment' (تسديد دفعة)
  double amount;
  String note;

  CustomerLedgerEntry({
    required this.id,
    required this.dateStr,
    required this.type,
    required this.amount,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateStr': dateStr,
        'type': type,
        'amount': amount,
        'note': note,
      };

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> j) =>
      CustomerLedgerEntry(
        id: (j['id'] as String?) ?? '',
        dateStr: (j['dateStr'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'debt',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        note: (j['note'] as String?) ?? '',
      );
}

class CustomerItem {
  String id;
  String name;
  String phone;
  double totalDebt;
  String? dueDate;
  List<CustomerLedgerEntry> ledger;

  CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    this.totalDebt = 0.0,
    this.dueDate,
    List<CustomerLedgerEntry>? ledger,
  }) : ledger = ledger ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'totalDebt': totalDebt,
        'dueDate': dueDate,
        'ledger': ledger.map((e) => e.toJson()).toList(),
      };

  factory CustomerItem.fromJson(Map<String, dynamic> j) => CustomerItem(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String,
        totalDebt: (j['totalDebt'] as num).toDouble(),
        dueDate: j['dueDate'] as String?,
        ledger: (j['ledger'] as List?)
                ?.map((e) =>
                    CustomerLedgerEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class InvoiceRecord {
  String id;
  String customerName;
  String dateStr;
  bool isWholesale;
  double subtotalAmount;
  double discountAmount;
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
    double? subtotalAmount,
    this.discountAmount = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingDebt,
    required this.netProfit,
    required this.summaryLines,
  }) : subtotalAmount = subtotalAmount ?? totalAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'dateStr': dateStr,
        'isWholesale': isWholesale,
        'subtotalAmount': subtotalAmount,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingDebt': remainingDebt,
        'netProfit': netProfit,
        'summaryLines': summaryLines,
      };

  factory InvoiceRecord.fromJson(Map<String, dynamic> j) {
    final total = (j['totalAmount'] as num).toDouble();
    return InvoiceRecord(
      id: j['id'] as String,
      customerName: j['customerName'] as String,
      dateStr: j['dateStr'] as String,
      isWholesale: j['isWholesale'] as bool,
      subtotalAmount: (j['subtotalAmount'] as num?)?.toDouble() ?? total,
      discountAmount: (j['discountAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: total,
      paidAmount: (j['paidAmount'] as num).toDouble(),
      remainingDebt: (j['remainingDebt'] as num).toDouble(),
      netProfit: (j['netProfit'] as num).toDouble(),
      summaryLines: List<String>.from(j['summaryLines'] ?? []),
    );
  }
}

class ExpenseRecord {
  String id;
  String title;
  String category;
  double amount;
  String dateStr;

  ExpenseRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dateStr,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'dateStr': dateStr,
      };

  factory ExpenseRecord.fromJson(Map<String, dynamic> j) => ExpenseRecord(
        id: j['id'] as String,
        title: j['title'] as String,
        category: (j['category'] as String?) ?? 'نقل وشحن',
        amount: (j['amount'] as num).toDouble(),
        dateStr: j['dateStr'] as String,
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
  List<ExpenseRecord> _expenses = [];

  // POS Cart State
  bool _posWholesaleMode = true;
  CustomerItem? _selectedCustomer;
  final Map<String, int> _cartQty = {};
  final TextEditingController _paidCtrl = TextEditingController();
  final TextEditingController _remiseCtrl = TextEditingController();

  // Global Store & Catalog Settings State
  bool _catalogHideOutOfStock = true;
  bool _catalogWholesaleMode = true;
  String _catalogSelectedCategory = 'الكل';
  String _companyName = 'تجارة بالجملة للمكتبة والوراقة - ميهوبي عبد الرحمان';
  String _companyPhone = '0661000000';
  String _companyWilaya = 'تلمسان - مغنية';
  bool _isGeneratingPdf = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _nowDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isProActivated = prefs.getBool('is_pro') ?? false;
    _deviceCode = prefs.getString('device_code') ??
        'DZ-${1000 + DateTime.now().millisecondsSinceEpoch % 8999}';
    await prefs.setString('device_code', _deviceCode);

    _companyName = prefs.getString('catalog_company_name') ??
        'تجارة بالجملة للمكتبة والوراقة - ميهوبي عبد الرحمان';
    _companyPhone = prefs.getString('catalog_company_phone') ?? '0661000000';
    _companyWilaya =
        prefs.getString('catalog_company_wilaya') ?? 'تلمسان - مغنية';
    _catalogHideOutOfStock = prefs.getBool('catalog_hide_oos') ?? true;
    _catalogWholesaleMode = prefs.getBool('catalog_wholesale') ?? true;

    final prodRaw = prefs.getString('products_v1');
    if (prodRaw != null) {
      final list = jsonDecode(prodRaw) as List;
      _products = list
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _products = [
        ProductItem(
          id: 'p1',
          name: 'ورق طباعة A4 (رزمة 500 ورقة)',
          buyPrice: 680,
          wholesalePrice: 760,
          retailPrice: 850,
          stock: 120,
          minAlert: 15,
          category: 'وراقة',
        ),
        ProductItem(
          id: 'p2',
          name: 'علبة أقلام جاف زرقاء (50 قلم)',
          buyPrice: 450,
          wholesalePrice: 540,
          retailPrice: 650,
          stock: 45,
          minAlert: 10,
          category: 'أقلام',
        ),
        ProductItem(
          id: 'p3',
          name: 'كراس 96 صفحة ممتاز (رزمة 20)',
          buyPrice: 1150,
          wholesalePrice: 1320,
          retailPrice: 1500,
          stock: 30,
          minAlert: 8,
          category: 'كراريس',
        ),
        ProductItem(
          id: 'p4',
          name: 'ملف إداري مقوى (حزمة 25)',
          buyPrice: 500,
          wholesalePrice: 620,
          retailPrice: 750,
          stock: 4,
          minAlert: 6,
          category: 'ملفات وتنظيم',
        ),
      ];
    }

    final custRaw = prefs.getString('customers_v1');
    if (custRaw != null) {
      final list = jsonDecode(custRaw) as List;
      _customers = list
          .map((e) => CustomerItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _customers = [
        CustomerItem(
          id: 'c1',
          name: 'مكتبة النجاح - مغنية',
          phone: '213661000000',
          totalDebt: 14500,
          dueDate: '2026-11-15',
          ledger: [
            CustomerLedgerEntry(
              id: 'l1',
              dateStr: '2026-10-28 10:30',
              type: 'debt',
              amount: 20000,
              note: 'فاتورة جملة (ورق طباعة + كراريس)',
            ),
            CustomerLedgerEntry(
              id: 'l2',
              dateStr: '2026-11-01 16:00',
              type: 'payment',
              amount: 5500,
              note: 'تسديد دفعة نقداً (Versement)',
            ),
          ],
        ),
        CustomerItem(
          id: 'c2',
          name: 'سوبرماركت الأمل - تلمسان',
          phone: '213550000000',
          totalDebt: 6200,
          dueDate: '2026-11-20',
          ledger: [
            CustomerLedgerEntry(
              id: 'l3',
              dateStr: '2026-10-30 11:15',
              type: 'debt',
              amount: 6200,
              note: 'رصيد سابق (بون بيع بالجملة)',
            ),
          ],
        ),
        CustomerItem(
            id: 'c3', name: 'زبون نقدي (Comptoir)', phone: '', totalDebt: 0),
      ];
    }

    final invRaw = prefs.getString('invoices_v1');
    if (invRaw != null) {
      final list = jsonDecode(invRaw) as List;
      _invoices = list
          .map((e) => InvoiceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final expRaw = prefs.getString('expenses_v1');
    if (expRaw != null) {
      final list = jsonDecode(expRaw) as List;
      _expenses = list
          .map((e) => ExpenseRecord.fromJson(e as Map<String, dynamic>))
          .toList();
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
    await prefs.setString(
        'expenses_v1', jsonEncode(_expenses.map((e) => e.toJson()).toList()));
    await prefs.setString('catalog_company_name', _companyName);
    await prefs.setString('catalog_company_phone', _companyPhone);
    await prefs.setString('catalog_company_wilaya', _companyWilaya);
    await prefs.setBool('catalog_hide_oos', _catalogHideOutOfStock);
    await prefs.setBool('catalog_wholesale', _catalogWholesaleMode);
  }

  // Expected license key formula: "PRO-" + (numeric part of deviceCode * 7 + 509)
  String _expectedKeyFor(String devCode) {
    final digits =
        int.tryParse(devCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000;
    return 'PRO-${digits * 7 + 509}';
  }

  // -------------------------------------------------------------------------
  // Communication Helpers: WhatsApp & Direct SMS
  // -------------------------------------------------------------------------
  Future<void> _sendWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تطبيق واتساب على هذا الجهاز.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSms(String phone, String message) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.startsWith('213') && !cleanPhone.startsWith('+')) {
      cleanPhone = '+$cleanPhone';
    }
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تطبيق الرسائل القصيرة SMS.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Image Picker & Zoom Helpers
  // -------------------------------------------------------------------------
  Future<String?> _pickAndSaveProductImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1024,
      );
      if (picked == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final ext = picked.path.contains('.')
          ? picked.path.substring(picked.path.lastIndexOf('.'))
          : '.jpg';
      final savedPath =
          '${imagesDir.path}/prod_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedFile = await File(picked.path).copy(savedPath);
      return savedFile.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر التقاط أو اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _showImageZoomDialog(ProductItem product) {
    final hasImage =
        product.imagePath != null && File(product.imagePath!).existsSync();
    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد صورة مرفقة لهذه السلعة بعد.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'التصنيف: ${product.category} | جملة: ${product.wholesalePrice.toStringAsFixed(0)} د.ج | تجزئة: ${product.retailPrice.toStringAsFixed(0)} د.ج',
                            style: const TextStyle(
                                color: Color(0xFFD4AF37), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.file(
                      File(product.imagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(ProductItem p, {double size = 48}) {
    final hasImg = p.imagePath != null && File(p.imagePath!).existsSync();
    return GestureDetector(
      onTap: () => _showImageZoomDialog(p),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF0F5132).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasImg
                ? const Color(0xFFD4AF37)
                : const Color(0xFF0F5132).withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImg
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(p.imagePath!),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.zoom_in,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF0F5132),
                size: 24,
              ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Feature 8: Global Store Settings Dialog (Header for Invoices & Catalogs)
  // -------------------------------------------------------------------------
  void _showStoreSettingsDialog() {
    final compCtrl = TextEditingController(text: _companyName);
    final phoneCtrl = TextEditingController(text: _companyPhone);
    final wilayaCtrl = TextEditingController(text: _companyWilaya);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.storefront, color: Color(0xFF0F5132)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إعدادات المؤسسة وترويسة الفواتير',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تظهر هذه البيانات في ترويسة جميع الفواتير، عروض الأسعار (Devis)، كشوف الحساب، والكتالوج المصور PDF:',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: compCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المؤسسة أو المحل التجاري',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف للتواصل والطلبات',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: wilayaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الولاية / العنوان التجاري',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (compCtrl.text.trim().isNotEmpty) {
                    _companyName = compCtrl.text.trim();
                  }
                  _companyPhone = phoneCtrl.text.trim();
                  _companyWilaya = wilayaCtrl.text.trim();
                });
                _saveData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ إعدادات المؤسسة بنجاح ✅'),
                    backgroundColor: Color(0xFF0F5132),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ الإعدادات'),
            ),
          ],
        ),
      ),
    );
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
      _buildCatalogTab(),
      _buildCustomersTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'دفتر الجملة الذكي — DaftarDZ v2.0',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _companyName,
              style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إعدادات المؤسسة والترويسة',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showStoreSettingsDialog,
          ),
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
              label: 'الأرباح والمصاريف'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'بون / Devis'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'المخزون'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'الكتالوج'),
          NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt),
              label: 'الزبائن والكريدي'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 1: Dashboard, Net Pocket Profit & Shop Expenses (Feature 7)
  // -------------------------------------------------------------------------
  Widget _buildDashboardTab() {
    final totalSales =
        _invoices.fold<double>(0, (s, item) => s + item.totalAmount);
    final grossSalesProfit =
        _invoices.fold<double>(0, (s, item) => s + item.netProfit);
    final totalExpenses =
        _expenses.fold<double>(0, (s, item) => s + item.amount);
    final netPocketProfit = grossSalesProfit - totalExpenses;
    final totalDebts =
        _customers.fold<double>(0, (s, item) => s + item.totalDebt);
    final lowStockItems =
        _products.where((p) => p.stock <= p.minAlert).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Welcome & Store Identity Banner
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
                    Text(
                      _companyName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$_companyWilaya | هـ: $_companyPhone',
                      style: const TextStyle(
                          color: Color(0xFFD4AF37), fontSize: 12),
                    ),
                    Text(
                      _isProActivated
                          ? 'النسخة الاحترافية v2.0 مفعّلة بالكامل'
                          : 'النسخة التجريبية (${_invoices.length}/30 فاتورة)',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
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
        const SizedBox(height: 10),

        // Feature 7 Highlight Banner: Net Pocket Profit After Expenses
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: netPocketProfit >= 0
                ? Colors.green.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: netPocketProfit >= 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: netPocketProfit >= 0
                    ? const Color(0xFF0F5132)
                    : Colors.red.shade700,
                child: const Icon(Icons.savings_outlined,
                    color: Color(0xFFD4AF37)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الربح الصافي في الجيب (بعد خصم المصاريف)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'ربح المبيعات (${grossSalesProfit.toStringAsFixed(0)}) - المصاريف (${totalExpenses.toStringAsFixed(0)})',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                '${netPocketProfit.toStringAsFixed(0)} د.ج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: netPocketProfit >= 0
                      ? const Color(0xFF0F5132)
                      : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

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
                title: 'إجمالي مصاريف المحل',
                value: '${totalExpenses.toStringAsFixed(0)} د.ج',
                icon: Icons.money_off_csred_rounded,
                color: Colors.deepOrange.shade700,
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

        // Feature 7: Shop Expenses Section (نقل، كراء، تغليف...)
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '💸 سجل مصاريف المحل (نقل، كراء، تغليف...):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade700,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('تسجيل مصروف', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_expenses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Center(
                child: Text(
                  'لا توجد مصاريف مسجلة. سجل مصاريف النقل أو الكراء أو التغليف لحساب ربحك الصافي بدقة.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ..._expenses.reversed.take(5).map((exp) => Card(
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.receipt_long,
                        color: Colors.deepOrange.shade800, size: 20),
                  ),
                  title: Text('${exp.title} (${exp.category})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('التاريخ: ${exp.dateStr}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '-${exp.amount.toStringAsFixed(0)} د.ج',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.grey),
                        tooltip: 'حذف المصروف',
                        onPressed: () {
                          setState(() => _expenses.remove(exp));
                          _saveData();
                        },
                      ),
                    ],
                  ),
                ),
              )),

        if (lowStockItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('⚠️ تنبيهات المخزون المنخفض:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          ...lowStockItems.map((p) => Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning_rounded,
                      color: Colors.deepOrange),
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
                child: Text(
                    'لا توجد فواتير بعد. ابدأ بإنشاء أول بون من تبويب «بون / Devis».'),
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
                      'التاريخ: ${inv.dateStr}${inv.discountAmount > 0 ? " | خصم: ${inv.discountAmount.toStringAsFixed(0)} د.ج" : ""}\nالربح الصافي: ${inv.netProfit.toStringAsFixed(0)} د.ج | الباقي كريدي: ${inv.remainingDebt.toStringAsFixed(0)} د.ج'),
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

  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCat = kExpenseCategories.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل مصروف جديد للمحل'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(
                      labelText: 'نوع المصروف',
                      border: OutlineInputBorder(),
                    ),
                    items: kExpenseCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCat = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'بيان المصروف (مثال: توصيل بضاعة، أكياس...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (د.ج)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amt <= 0) return;
                  final title = titleCtrl.text.trim().isEmpty
                      ? selectedCat
                      : titleCtrl.text.trim();
                  setState(() {
                    _expenses.add(ExpenseRecord(
                      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      category: selectedCat,
                      amount: amt,
                      dateStr: _nowDateStr(),
                    ));
                  });
                  _saveData();
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ المصروف'),
              ),
            ],
          ),
        ),
      ),
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
  // TAB 2: Fast POS + Discount (Remise) + Quote (Devis) (Feature 4)
  // -------------------------------------------------------------------------
  Widget _buildPosTab() {
    double cartSubtotal = 0;
    double rawProfit = 0;

    for (final entry in _cartQty.entries) {
      final prod = _products.where((p) => p.id == entry.key).firstOrNull;
      if (prod != null && entry.value > 0) {
        final unitPrice =
            _posWholesaleMode ? prod.wholesalePrice : prod.retailPrice;
        cartSubtotal += unitPrice * entry.value;
        rawProfit += (unitPrice - prod.buyPrice) * entry.value;
      }
    }

    final remise = double.tryParse(_remiseCtrl.text.trim()) ?? 0.0;
    final netTotal =
        (cartSubtotal - remise) > 0 ? (cartSubtotal - remise) : 0.0;
    final netProfit = rawProfit - remise;

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
                      initialValue: _selectedCustomer,
                      isDense: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _customers
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                    '${c.name} (دين: ${c.totalDebt.toStringAsFixed(0)} د.ج)'),
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
                  const Text('التسعير: ',
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

        // Product Selection List with Thumbnail & Zoom
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
                  leading: _buildProductThumbnail(p, size: 48),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${p.category} | السعر: ${price.toStringAsFixed(0)} د.ج | المتوفر: ${p.stock}'),
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

        // Bottom Checkout Summary with Remise & Devis Button
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    remise > 0
                        ? 'الصافي بعد الخصم: ${netTotal.toStringAsFixed(0)} د.ج'
                        : 'المجموع الكلي: ${netTotal.toStringAsFixed(0)} د.ج',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5132)),
                  ),
                  Text(
                    'ربح البون: +${netProfit.toStringAsFixed(0)} د.ج',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: netProfit >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _remiseCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'الخصم Remise (د.ج)',
                        prefixIcon: Icon(Icons.discount_outlined, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _paidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'المدفوع (فارغ = ${netTotal.toStringAsFixed(0)})',
                        prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F5132),
                        side: const BorderSide(color: Color(0xFF0F5132)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: cartSubtotal <= 0
                          ? null
                          : () => _sendQuoteDevis(cartSubtotal, remise, netTotal),
                      icon: const Icon(Icons.request_quote_outlined, size: 18),
                      label: const Text(
                        'إرسال عرض سعر (Devis)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: cartSubtotal <= 0
                          ? null
                          : () => _completeInvoice(
                              cartSubtotal, remise, netTotal, netProfit),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'حفظ وإرسال البون',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Feature 4: Send Devis (Quote) via WhatsApp without deducting stock
  void _sendQuoteDevis(double subtotal, double remise, double netTotal) {
    final cust = _selectedCustomer ?? _customers.first;
    final lines = <String>[];
    for (final entry in _cartQty.entries) {
      if (entry.value > 0) {
        final p = _products.firstWhere((e) => e.id == entry.key);
        final uPrice = _posWholesaleMode ? p.wholesalePrice : p.retailPrice;
        lines.add(
            '• ${p.name}: ${entry.value} × ${uPrice.toStringAsFixed(0)} = ${(entry.value * uPrice).toStringAsFixed(0)} د.ج');
      }
    }
    final dateStr = _nowDateStr();
    final msg = '📋 *عرض سعر (Devis) — $_companyName*\n'
        '📍 $_companyWilaya | هـ: $_companyPhone\n'
        'الزبون: ${cust.name}\n'
        'التاريخ: $dateStr\n'
        'نوع التسعير: ${_posWholesaleMode ? "جملة (Gros)" : "تجزئة (Détail)"}\n'
        '----------------\n'
        '${lines.join('\n')}\n'
        '----------------\n'
        'المجموع: ${subtotal.toStringAsFixed(0)} د.ج\n'
        '${remise > 0 ? "الخصم الخاص (Remise): -${remise.toStringAsFixed(0)} د.ج\n" : ""}'
        '*الصافي المطلوب:* ${netTotal.toStringAsFixed(0)} د.ج\n'
        '*(ملاحظة: هذا عرض سعر أولي ولا يخصم من المخزون حتى تأكيد الطلب)*';

    _sendWhatsApp(cust.phone, msg);
  }

  void _completeInvoice(
      double subtotal, double remise, double netTotal, double profit) {
    if (!_isProActivated && _invoices.length >= 30) {
      _showLicenseDialog();
      return;
    }
    final cust = _selectedCustomer ?? _customers.first;
    final paidInput = double.tryParse(_paidCtrl.text.trim());
    final paid = paidInput ?? netTotal;
    final remaining = (netTotal - paid) > 0 ? (netTotal - paid) : 0.0;

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

    final dateStr = _nowDateStr();
    cust.totalDebt += remaining;

    // Record in Customer Detailed Ledger (Feature 2)
    cust.ledger.add(CustomerLedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      dateStr: dateStr,
      type: 'debt',
      amount: netTotal,
      note:
          'فاتورة ${_posWholesaleMode ? "جملة" : "تجزئة"} (${lines.length} أصناف)${remise > 0 ? " - خصم ${remise.toStringAsFixed(0)}" : ""}',
    ));
    if (paid > 0) {
      cust.ledger.add(CustomerLedgerEntry(
        id: 'led_pay_${DateTime.now().millisecondsSinceEpoch}',
        dateStr: dateStr,
        type: 'payment',
        amount: paid,
        note: 'دفعة فورية مع الفاتورة',
      ));
    }

    final inv = InvoiceRecord(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      customerName: cust.name,
      dateStr: dateStr,
      isWholesale: _posWholesaleMode,
      subtotalAmount: subtotal,
      discountAmount: remise,
      totalAmount: netTotal,
      paidAmount: paid,
      remainingDebt: remaining,
      netProfit: profit,
      summaryLines: lines,
    );

    setState(() {
      _invoices.add(inv);
      _cartQty.clear();
      _paidCtrl.clear();
      _remiseCtrl.clear();
    });
    _saveData();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تم حفظ البون بنجاح ✅'),
          content: Text(
            'الزبون: ${cust.name}\n'
            'المجموع قبل الخصم: ${subtotal.toStringAsFixed(0)} د.ج\n'
            '${remise > 0 ? "الخصم (Remise): ${remise.toStringAsFixed(0)} د.ج\n" : ""}'
            'الصافي: ${netTotal.toStringAsFixed(0)} د.ج\n'
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
                final msg = '🧾 *بون تسليم — $_companyName*\n'
                    '📍 $_companyWilaya | هـ: $_companyPhone\n'
                    'الزبون: ${cust.name}\n'
                    'التاريخ: $dateStr\n'
                    '----------------\n'
                    '${lines.join('\n')}\n'
                    '----------------\n'
                    '${remise > 0 ? "المجموع: ${subtotal.toStringAsFixed(0)} د.ج\nالخصم (Remise): -${remise.toStringAsFixed(0)} د.ج\n" : ""}'
                    '*الصافي المطلوب:* ${netTotal.toStringAsFixed(0)} د.ج\n'
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

  // -------------------------------------------------------------------------
  // TAB 3: Inventory + Stock Financial Valuation (Feature 3) + Auto Margin (Feature 6)
  // -------------------------------------------------------------------------
  Widget _buildInventoryTab() {
    // Feature 3: Financial Stock Valuation Calculation
    double totalCapitalBuy = 0;
    double totalValueWholesale = 0;
    double totalValueRetail = 0;

    for (final p in _products) {
      if (p.stock > 0) {
        totalCapitalBuy += p.stock * p.buyPrice;
        totalValueWholesale += p.stock * p.wholesalePrice;
        totalValueRetail += p.stock * p.retailPrice;
      }
    }
    final latentWholesaleProfit = totalValueWholesale - totalCapitalBuy;
    final latentRetailProfit = totalValueRetail - totalCapitalBuy;

    return Scaffold(
      body: Column(
        children: [
          // Feature 3: Stock Financial Valuation Banner at Top of Inventory
          Container(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5132), Color(0xFF146C43)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assessment_outlined,
                        color: Color(0xFFD4AF37), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'التقييم المالي للمخزون الحالي (Stock Valuation)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _stockValuationPill(
                        label: 'رأس المال (شراء)',
                        value: '${totalCapitalBuy.toStringAsFixed(0)} د.ج',
                        valueColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _stockValuationPill(
                        label: 'القيمة (بسعر الجملة)',
                        value: '${totalValueWholesale.toStringAsFixed(0)} د.ج',
                        valueColor: const Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _stockValuationPill(
                        label: 'الربح الكامن (جملة)',
                        value: '+${latentWholesaleProfit.toStringAsFixed(0)} د.ج',
                        subLabel:
                            'تجزئة: +${latentRetailProfit.toStringAsFixed(0)}',
                        valueColor: Colors.greenAccent.shade200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _products.length,
              itemBuilder: (ctx, i) {
                final p = _products[i];
                final isLow = p.stock <= p.minAlert;
                return Card(
                  child: ListTile(
                    leading: _buildProductThumbnail(p, size: 52),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0F5132).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0F5132),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'المتوفر: ${p.stock} | شراء: ${p.buyPrice.toStringAsFixed(0)} | جملة: ${p.wholesalePrice.toStringAsFixed(0)} | تجزئة: ${p.retailPrice.toStringAsFixed(0)} د.ج',
                        style: TextStyle(
                          color: isLow ? Colors.red.shade700 : Colors.black87,
                          fontWeight:
                              isLow ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blueGrey),
                          tooltip: 'تعديل السلعة أو صورتها',
                          onPressed: () => _showProductDialog(existing: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_box_outlined,
                              color: Color(0xFF0F5132)),
                          tooltip: 'إضافة كمية للمخزون (+10)',
                          onPressed: () {
                            setState(() => p.stock += 10);
                            _saveData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('سلعة جديدة'),
      ),
    );
  }

  Widget _stockValuationPill({
    required String label,
    required String value,
    required Color valueColor,
    String? subLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (subLabel != null)
            Text(
              subLabel,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
        ],
      ),
    );
  }

  // Feature 6: Auto Profit Margin Calculator (+15% Wholesale, +30% Retail)
  void _showProductDialog({ProductItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final buyCtrl = TextEditingController(
        text: existing != null ? existing.buyPrice.toStringAsFixed(0) : '');
    final grosCtrl = TextEditingController(
        text:
            existing != null ? existing.wholesalePrice.toStringAsFixed(0) : '');
    final detailCtrl = TextEditingController(
        text: existing != null ? existing.retailPrice.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(
        text: existing != null ? '${existing.stock}' : '20');
    String selectedCategory = existing?.category ?? kDefaultCategories.first;
    if (!kDefaultCategories.contains(selectedCategory)) {
      selectedCategory = kDefaultCategories.first;
    }
    String? pickedImagePath = existing?.imagePath;
    bool autoCalcEnabled = existing == null;

    void applyMarginSuggestion(
        double grosPct, double detailPct, StateSetter setDialogState) {
      final buy = double.tryParse(buyCtrl.text.trim()) ?? 0;
      if (buy > 0) {
        grosCtrl.text = (buy * (1 + grosPct / 100)).round().toString();
        detailCtrl.text = (buy * (1 + detailPct / 100)).round().toString();
        setDialogState(() {});
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final hasPreview =
              pickedImagePath != null && File(pickedImagePath!).existsSync();
          final buyVal = double.tryParse(buyCtrl.text.trim()) ?? 0;
          final grosVal = double.tryParse(grosCtrl.text.trim()) ?? 0;
          final detailVal = double.tryParse(detailCtrl.text.trim()) ?? 0;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(existing == null
                  ? 'إضافة سلعة جديدة للمخزون'
                  : 'تعديل بيانات وصورة السلعة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Preview & Camera/Gallery Buttons
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          if (hasPreview)
                            Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(pickedImagePath!),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                IconButton(
                                  icon: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.delete_outline,
                                        size: 16, color: Colors.white),
                                  ),
                                  onPressed: () => setDialogState(
                                      () => pickedImagePath = null),
                                ),
                              ],
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: [
                                  Icon(Icons.camera_alt_outlined,
                                      size: 36, color: Color(0xFF0F5132)),
                                  SizedBox(height: 4),
                                  Text(
                                    'التقط صورة السلعة أو اخترها من المعرض',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final path = await _pickAndSaveProductImage(
                                        ImageSource.camera);
                                    if (path != null) {
                                      setDialogState(
                                          () => pickedImagePath = path);
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.photo_camera, size: 18),
                                  label: const Text('الكاميرا',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final path = await _pickAndSaveProductImage(
                                        ImageSource.gallery);
                                    if (path != null) {
                                      setDialogState(
                                          () => pickedImagePath = path);
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.photo_library, size: 18),
                                  label: const Text('المعرض',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'اسم السلعة'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف (Category)',
                      ),
                      items: kDefaultCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Feature 6: Buy Price with Auto Profit Margin Suggestion (+15% / +30%)
                    TextField(
                      controller: buyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        if (autoCalcEnabled) {
                          final buy = double.tryParse(v.trim()) ?? 0;
                          if (buy > 0) {
                            grosCtrl.text = (buy * 1.15).round().toString();
                            detailCtrl.text = (buy * 1.30).round().toString();
                          }
                        }
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'سعر الشراء (د.ج)',
                        helperText:
                            'يقترح تلقائياً: جملة (+15%) وتجزئة (+30%)',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.auto_fix_high, size: 15),
                          label: const Text('اقتراح +15% جملة / +30% تجزئة',
                              style: TextStyle(fontSize: 11)),
                          onPressed: () =>
                              applyMarginSuggestion(15, 30, setDialogState),
                        ),
                      ],
                    ),
                    TextField(
                      controller: grosCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        autoCalcEnabled = false;
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'سعر البيع بالجملة (د.ج)',
                        suffixText: buyVal > 0 && grosVal > 0
                            ? 'ربح: ${(grosVal - buyVal).toStringAsFixed(0)} د.ج (${(((grosVal - buyVal) / buyVal) * 100).toStringAsFixed(0)}%)'
                            : null,
                      ),
                    ),
                    TextField(
                      controller: detailCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        autoCalcEnabled = false;
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'سعر البيع بالتجزئة (د.ج)',
                        suffixText: buyVal > 0 && detailVal > 0
                            ? 'ربح: ${(detailVal - buyVal).toStringAsFixed(0)} د.ج (${(((detailVal - buyVal) / buyVal) * 100).toStringAsFixed(0)}%)'
                            : null,
                      ),
                    ),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'الكمية المتوفرة في المخزن'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5132),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setState(() {
                      if (existing != null) {
                        existing.name = nameCtrl.text.trim();
                        existing.category = selectedCategory;
                        existing.buyPrice =
                            double.tryParse(buyCtrl.text) ?? existing.buyPrice;
                        existing.wholesalePrice =
                            double.tryParse(grosCtrl.text) ??
                                existing.wholesalePrice;
                        existing.retailPrice =
                            double.tryParse(detailCtrl.text) ??
                                existing.retailPrice;
                        existing.stock =
                            int.tryParse(stockCtrl.text) ?? existing.stock;
                        existing.imagePath = pickedImagePath;
                      } else {
                        _products.add(ProductItem(
                          id: 'p${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text.trim(),
                          buyPrice: double.tryParse(buyCtrl.text) ?? 0,
                          wholesalePrice: double.tryParse(grosCtrl.text) ?? 0,
                          retailPrice: double.tryParse(detailCtrl.text) ?? 0,
                          stock: int.tryParse(stockCtrl.text) ?? 10,
                          category: selectedCategory,
                          imagePath: pickedImagePath,
                        ));
                      }
                    });
                    _saveData();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ السلعة'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 4: Visual Catalog Generator (Feature 5)
  // -------------------------------------------------------------------------
  List<ProductItem> get _filteredCatalogProducts {
    return _products.where((p) {
      if (_catalogHideOutOfStock && p.stock <= 0) return false;
      if (_catalogSelectedCategory != 'الكل' &&
          p.category != _catalogSelectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildCatalogTab() {
    final items = _filteredCatalogProducts;
    final categories = ['الكل', ...kDefaultCategories];

    return Column(
      children: [
        // Top Action Bar: PDF Preview/Print & WhatsApp Share
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5132),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isGeneratingPdf ? null : _previewAndPrintPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text(
                        'معاينة وطباعة الكتالوج (PDF)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                          _isGeneratingPdf ? null : _shareCatalogToWhatsApp,
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text(
                        'إرسال الكتالوج للزبائن عبر واتساب',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Store Header Summary & Edit Button
              InkWell(
                onTap: _showStoreSettingsDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5132).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business,
                          size: 18, color: Color(0xFF0F5132)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_companyName | $_companyWilaya | هـ: $_companyPhone',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F5132),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit_note,
                          size: 20, color: Color(0xFF0F5132)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Pricing Mode + Hide Out-of-Stock Toggle
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('أسعار الجملة (Gros)',
                              style: TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('أسعار التجزئة (Détail)',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {_catalogWholesaleMode},
                      onSelectionChanged: (s) {
                        setState(() => _catalogWholesaleMode = s.first);
                        _saveData();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _catalogHideOutOfStock,
                    label: const Text('إخفاء النافد',
                        style: TextStyle(fontSize: 11)),
                    selectedColor:
                        const Color(0xFFD4AF37).withValues(alpha: 0.35),
                    onSelected: (v) {
                      setState(() => _catalogHideOutOfStock = v);
                      _saveData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Category Filter Bar
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final cat = categories[i];
                    final selected = _catalogSelectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      selectedColor: const Color(0xFF0F5132),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          setState(() => _catalogSelectedCategory = cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        if (_isGeneratingPdf)
          const LinearProgressIndicator(
            color: Color(0xFFD4AF37),
            backgroundColor: Color(0xFF0F5132),
          ),

        // GridView of Product Cards
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لا توجد سلع مطابقة للفلتر الحالي في الكتالوج.',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final p = items[i];
                    final hasImg = p.imagePath != null &&
                        File(p.imagePath!).existsSync();
                    final price = _catalogWholesaleMode
                        ? p.wholesalePrice
                        : p.retailPrice;
                    final inStock = p.stock > 0;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => hasImg
                                  ? _showImageZoomDialog(p)
                                  : _showProductDialog(existing: p),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (hasImg)
                                    Image.file(
                                      File(p.imagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Container(
                                      color: const Color(0xFF0F5132)
                                          .withValues(alpha: 0.07),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined,
                                              size: 36,
                                              color: Color(0xFF0F5132)),
                                          SizedBox(height: 4),
                                          Text(
                                            'اضغط لإضافة صورة',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0F5132),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F5132)
                                            .withValues(alpha: 0.88),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: inStock
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        inStock ? 'متوفر (${p.stock})' : 'نافد',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5132),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFD4AF37),
                                        width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _catalogWholesaleMode
                                            ? 'سعر الجملة'
                                            : 'سعر التجزئة',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '${price.toStringAsFixed(0)} د.ج',
                                        style: const TextStyle(
                                          color: Color(0xFFD4AF37),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<Uint8List> _generateCatalogPdfBytes(PdfPageFormat format) async {
    final baseFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final pdf = pw.Document(
      title: 'كتالوج السلع - $_companyName',
      author: _companyName,
    );

    final items = _filteredCatalogProducts;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final pricingLabel = _catalogWholesaleMode
        ? 'كتالوج أسعار الجملة (Gros)'
        : 'كتالوج أسعار التجزئة (Détail)';

    const greenPrimary = PdfColor.fromInt(0xFF0F5132);
    const goldAccent = PdfColor.fromInt(0xFFD4AF37);
    const lightBg = PdfColor.fromInt(0xFFF8F9FA);

    final Map<String, pw.MemoryImage> loadedImages = {};
    for (final p in items) {
      if (p.imagePath != null) {
        final f = File(p.imagePath!);
        if (f.existsSync()) {
          try {
            final bytes = await f.readAsBytes();
            loadedImages[p.id] = pw.MemoryImage(bytes);
          } catch (_) {}
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: greenPrimary,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: goldAccent, width: 2),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _companyName,
                      style: pw.TextStyle(
                        font: boldFont,
                        color: PdfColors.white,
                        fontSize: 15,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'الولاية: $_companyWilaya  |  الهاتف: $_companyPhone',
                      style: const pw.TextStyle(
                        color: goldAccent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: goldAccent,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      pricingLabel,
                      style: pw.TextStyle(
                        font: boldFont,
                        color: PdfColors.black,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'التاريخ: $dateStr',
                      style: const pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: goldAccent, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '$_companyName — للطلب والاستفسار: $_companyPhone',
                style: const pw.TextStyle(fontSize: 9, color: greenPrimary),
              ),
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.map((p) {
                final price = _catalogWholesaleMode
                    ? p.wholesalePrice
                    : p.retailPrice;
                final img = loadedImages[p.id];
                return pw.Container(
                  width: 172,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: goldAccent, width: 1.2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Container(
                        height: 110,
                        decoration: const pw.BoxDecoration(
                          color: lightBg,
                          borderRadius: pw.BorderRadius.vertical(
                              top: pw.Radius.circular(7)),
                        ),
                        child: img != null
                            ? pw.ClipRRect(
                                horizontalRadius: 7,
                                verticalRadius: 7,
                                child: pw.Image(img, fit: pw.BoxFit.cover),
                              )
                            : pw.Center(
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      p.category,
                                      style: pw.TextStyle(
                                        font: boldFont,
                                        color: greenPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    pw.Text(
                                      'متوفر في المخزن',
                                      style: const pw.TextStyle(
                                        color: PdfColors.grey600,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  p.category,
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: greenPrimary,
                                  ),
                                ),
                                pw.Text(
                                  p.stock > 0 ? 'متوفر' : 'نافد',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                    color: p.stock > 0
                                        ? greenPrimary
                                        : PdfColors.red,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 3),
                            pw.SizedBox(
                              height: 32,
                              child: pw.Text(
                                p.name,
                                maxLines: 2,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 10,
                                  color: PdfColors.black,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: const pw.BoxDecoration(
                                color: greenPrimary,
                                borderRadius:
                                    pw.BorderRadius.all(pw.Radius.circular(5)),
                              ),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'السعر:',
                                    style: const pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    '${price.toStringAsFixed(0)} د.ج',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      color: goldAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _previewAndPrintPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await Printing.layoutPdf(
        name: 'Catalog_DaftarDZ.pdf',
        onLayout: (format) => _generateCatalogPdfBytes(format),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء معاينة الكتالوج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _shareCatalogToWhatsApp() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generateCatalogPdfBytes(PdfPageFormat.a4);
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/Catalog_DaftarDZ.pdf');
      await pdfFile.writeAsBytes(bytes, flush: true);

      final priceTypeAr = _catalogWholesaleMode
          ? 'أسعار الجملة (Gros)'
          : 'أسعار التجزئة (Détail)';
      final welcomeMsg = 'السلام عليكم ورحمة الله وبركاته 🌟\n'
          'يسر *$_companyName* ($_companyWilaya) أن يضع بين أيديكم الكتالوج المصور الجديد للسلع المتوفرة ($priceTypeAr) بصيغة PDF 📘.\n'
          'للطلب أو الاستفسار يرجى التواصل معنا على الرقم: $_companyPhone\n'
          'مرحباً بكم ودمتم أوفياء لنا!';

      await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        text: welcomeMsg,
        subject: 'كتالوج السلع — $_companyName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر مشاركة ملف الكتالوج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // -------------------------------------------------------------------------
  // TAB 5: Customers + Dual Debt Reminder (SMS + WhatsApp) (Feature 1)
  //        + Detailed Customer Ledger Bottom Sheet & Due Date (Feature 2)
  // -------------------------------------------------------------------------
  Widget _buildCustomersTab() {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF0F5132).withValues(alpha: 0.08),
            child: const Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 18, color: Color(0xFF0F5132)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'اضغط على أي زبون لفتح «كراس الحساب التفصيلي» وتحديد موعد التسديد (Due Date).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0F5132)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _customers.length,
              itemBuilder: (ctx, i) {
                final c = _customers[i];
                final hasDebt = c.totalDebt > 0;
                return Card(
                  child: ListTile(
                    onTap: () => _showCustomerLedgerSheet(c),
                    leading: CircleAvatar(
                      backgroundColor:
                          hasDebt ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(
                        Icons.person,
                        color: hasDebt ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الدين المتبقي (الكريدي): ${c.totalDebt.toStringAsFixed(0)} د.ج',
                          style: TextStyle(
                            color:
                                hasDebt ? Colors.red.shade700 : Colors.black87,
                            fontWeight:
                                hasDebt ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (c.dueDate != null && c.dueDate!.isNotEmpty)
                          Text(
                            '📅 موعد التسديد المتفق عليه: ${c.dueDate}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasDebt)
                          IconButton(
                            tooltip: 'تسجيل دفعة (Versement)',
                            icon: const Icon(Icons.payments_outlined,
                                color: Colors.green),
                            onPressed: () => _showPayDebtDialog(c),
                          ),
                        // Feature 1: Free Direct SMS Reminder Button
                        if (hasDebt && c.phone.isNotEmpty)
                          IconButton(
                            tooltip: 'تذكير مجاني عبر رسالة نصية SMS',
                            icon: const Icon(Icons.sms_outlined,
                                color: Colors.blue),
                            onPressed: () {
                              final duePart = (c.dueDate != null &&
                                      c.dueDate!.isNotEmpty)
                                  ? ' (تاريخ الاستحقاق: ${c.dueDate})'
                                  : '';
                              final smsMsg =
                                  'السلام عليكم ${c.name}، تذكير ودي من $_companyName: الرصيد المتبقي في حسابكم هو ${c.totalDebt.toStringAsFixed(0)} د.ج$duePart. شكراً لتعاملكم.';
                              _sendSms(c.phone, smsMsg);
                            },
                          ),
                        // Feature 1: WhatsApp Reminder Button
                        if (c.phone.isNotEmpty)
                          IconButton(
                            tooltip: 'إرسال تذكير عبر واتساب',
                            icon: const Icon(Icons.chat_outlined,
                                color: Color(0xFF0F5132)),
                            onPressed: () {
                              final duePart = (c.dueDate != null &&
                                      c.dueDate!.isNotEmpty)
                                  ? '\n📅 *موعد التسديد المتفق عليه:* ${c.dueDate}'
                                  : '';
                              final msg =
                                  'السلام عليكم ورحمة الله (${c.name})،\n'
                                  'تذكير ودي من *$_companyName* ($_companyWilaya):\n'
                                  'الرصيد المتبقي في حسابكم هو *${c.totalDebt.toStringAsFixed(0)} د.ج*.$duePart\n'
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
          ),
        ],
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

  // Feature 2: Detailed Customer Ledger Bottom Sheet & Due Date
  void _showCustomerLedgerSheet(CustomerItem c) {
    final dueCtrl = TextEditingController(text: c.dueDate ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final totalTaken = c.ledger
              .where((e) => e.type == 'debt')
              .fold<double>(0, (s, e) => s + e.amount);
          final totalPaid = c.ledger
              .where((e) => e.type == 'payment')
              .fold<double>(0, (s, e) => s + e.amount);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.5,
              maxChildSize: 0.94,
              builder: (_, scrollController) => Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📒 كراس حساب الزبون: ${c.name}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                              Text(
                                'الهاتف: ${c.phone.isEmpty ? "غير مسجل" : c.phone} | الدين الحالي: ${c.totalDebt.toStringAsFixed(0)} د.ج',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Due Date Picker & Input Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dueCtrl,
                            decoration: const InputDecoration(
                              labelText:
                                  'موعد التسديد المتفق عليه (مثال: 2026-11-30)',
                              prefixIcon: Icon(Icons.event_available, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (val) {
                              setState(() => c.dueDate = val.trim());
                              setSheetState(() {});
                              _saveData();
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'اختيار تاريخ من التقويم',
                          icon: const Icon(Icons.calendar_month,
                              color: Color(0xFF0F5132)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              final formatted =
                                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              dueCtrl.text = formatted;
                              setState(() => c.dueDate = formatted);
                              setSheetState(() {});
                              _saveData();
                            }
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5132),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() => c.dueDate = dueCtrl.text.trim());
                            setSheetState(() {});
                            _saveData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حفظ موعد التسديد ✅'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text('حفظ الموعد'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Summary Pills (Total Taken vs Total Paid vs Remaining)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('إجمالي ما أخذ',
                                    style: TextStyle(fontSize: 11)),
                                Text(
                                  '${totalTaken.toStringAsFixed(0)} د.ج',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('إجمالي ما سدد',
                                    style: TextStyle(fontSize: 11)),
                                Text(
                                  '${totalPaid.toStringAsFixed(0)} د.ج',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('الرصيد المتبقي',
                                    style: TextStyle(fontSize: 11)),
                                Text(
                                  '${c.totalDebt.toStringAsFixed(0)} د.ج',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F5132)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'سجل حركات الحساب بالتاريخ (السلع المسحوبة والدفعات المسددة):',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),

                    // Ledger Entries List
                    Expanded(
                      child: c.ledger.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد حركات تفصيلية مسجلة لهذا الزبون بعد.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: c.ledger.length,
                              itemBuilder: (_, idx) {
                                final entry =
                                    c.ledger[c.ledger.length - 1 - idx];
                                final isDebt = entry.type == 'debt';
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isDebt
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      child: Icon(
                                        isDebt
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                        color:
                                            isDebt ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      entry.note,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('التاريخ: ${entry.dateStr}'),
                                    trailing: Text(
                                      '${isDebt ? "+" : "-"}${entry.amount.toStringAsFixed(0)} د.ج',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDebt
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 8),
                    // Bottom Actions inside Sheet: Full WhatsApp Statement + SMS + Record Payment
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _sendFullLedgerStatementWhatsApp(c),
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text(
                              'إرسال كشف الحساب كاملاً عبر واتساب',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showPayDebtDialog(c);
                          },
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: const Text('تسديد دفعة',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendFullLedgerStatementWhatsApp(CustomerItem c) {
    final historyLines = c.ledger.map((e) {
      final sign = e.type == 'debt' ? '🔴 أخذ:' : '🟢 سدد:';
      return '$sign ${e.amount.toStringAsFixed(0)} د.ج (${e.dateStr}) — ${e.note}';
    }).join('\n');

    final dueLine = (c.dueDate != null && c.dueDate!.isNotEmpty)
        ? '\n📅 *موعد التسديد المتفق عليه:* ${c.dueDate}'
        : '';

    final msg = '📒 *كشف حساب تفصيلي — $_companyName*\n'
        '📍 $_companyWilaya | هـ: $_companyPhone\n'
        'الزبون: *${c.name}*\n'
        '----------------\n'
        '${historyLines.isEmpty ? "لا توجد حركات سابقة مسجلة" : historyLines}\n'
        '----------------\n'
        '*الرصيد المتبقي (الكريدي):* ${c.totalDebt.toStringAsFixed(0)} د.ج'
        '$dueLine\n'
        'شكراً لثقتكم وتعاملكم الطيب معنا!';

    _sendWhatsApp(c.phone, msg);
  }

  void _showPayDebtDialog(CustomerItem c) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'تسديد دفعة نقداً (Versement)');
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
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final paid = double.tryParse(ctrl.text) ?? 0;
                if (paid > 0) {
                  setState(() {
                    c.totalDebt =
                        (c.totalDebt - paid) > 0 ? (c.totalDebt - paid) : 0;
                    c.ledger.add(CustomerLedgerEntry(
                      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                      dateStr: _nowDateStr(),
                      type: 'payment',
                      amount: paid,
                      note: noteCtrl.text.trim().isEmpty
                          ? 'تسديد دفعة (Versement)'
                          : noteCtrl.text.trim(),
                    ));
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
    final dueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة زبون جديد'),
          content: SingleChildScrollView(
            child: Column(
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
                        labelText: 'رقم الهاتف (مثال: 213661...)')),
                TextField(
                    controller: debtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'رصيد الكريدي السابق (إن وجد)')),
                TextField(
                    controller: dueCtrl,
                    decoration: const InputDecoration(
                        labelText:
                            'موعد التسديد المتفق عليه (اختياري، مثال: 2026-11-30)')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final initialDebt = double.tryParse(debtCtrl.text) ?? 0;
                final initialLedger = <CustomerLedgerEntry>[];
                if (initialDebt > 0) {
                  initialLedger.add(CustomerLedgerEntry(
                    id: 'init_${DateTime.now().millisecondsSinceEpoch}',
                    dateStr: _nowDateStr(),
                    type: 'debt',
                    amount: initialDebt,
                    note: 'رصيد كريدي افتتاحي سابق',
                  ));
                }
                setState(() {
                  _customers.add(CustomerItem(
                    id: 'c${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    totalDebt: initialDebt,
                    dueDate: dueCtrl.text.trim().isEmpty
                        ? null
                        : dueCtrl.text.trim(),
                    ledger: initialLedger,
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
