import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('app_lang') ?? 'ar';
  appLangNotifier.value =
      kSupportedLangs.contains(savedLang) ? savedLang : 'ar';
  runApp(const DaftarDzApp());
}

// ---------------------------------------------------------------------------
// Luxury "Mihrab-Inspired" Royal Navy + Cyan Glow + Golden Orange Palette
// ---------------------------------------------------------------------------
const Color kNavyDeep = Color(0xFF0A192F);
const Color kNavyMid = Color(0xFF112240);
const Color kNavySurface = Color(0xFF172A45);
const Color kCyanGlow = Color(0xFF00E5FF);
const Color kOrangeGold = Color(0xFFFF9100);
const Color kEmeraldBright = Color(0xFF00E676);

// ---------------------------------------------------------------------------
// Built-in Tri-Lingual Localization (AR default / FR / EN)
// ---------------------------------------------------------------------------
/// Currently selected app language ('ar', 'fr' or 'en'), persisted under
/// the SharedPreferences key 'app_lang'.
final ValueNotifier<String> appLangNotifier = ValueNotifier<String>('ar');

const List<String> kSupportedLangs = ['ar', 'fr', 'en'];

class AppStrings {
  /// Arabic source text -> [French, English].
  // TR-BEGIN
  static const Map<String, List<String>> _tr = {
    // Tabs
    'الأرباح والمصاريف': ["Bénéfices & Dépenses", "Profits & Expenses"],
    'بون / عرض سعر': ["Bon & Devis", "POS & Quote"],
    'المخزون وقيمته': ["Stock & Valeur", "Inventory & Value"],
    'الكتالوج المصور': ["Catalogue Produits", "Product Catalog"],
    'الديون والتذكير': ["Crédits & Rappels", "Debts & Reminders"],
    // Store settings & license
    'إعدادات المؤسسة وترويسة الفواتير': ["Paramètres de l'entreprise & en-tête", "Store Settings & Invoice Header"],
    'تظهر هذه البيانات في ترويسة جميع الفواتير، عروض الأسعار (Devis)، كشوف الحساب، والكتالوج المصور PDF:': ["Ces informations apparaissent dans l'en-tête de tous les bons, devis, relevés de compte et du catalogue PDF :", "This information appears in the header of all invoices, quotations, account statements and the PDF catalog:"],
    'اسم المؤسسة أو المحل التجاري': ["Nom de l'entreprise / magasin", "Company / Store Name"],
    'رقم الهاتف للتواصل والطلبات': ["Téléphone (contact & commandes)", "Phone (contact & orders)"],
    'الولاية / العنوان التجاري': ["Wilaya / Adresse commerciale", "Wilaya / Business Address"],
    'إلغاء': ["Annuler", "Cancel"],
    'تم حفظ إعدادات المؤسسة بنجاح ✅': ["Paramètres enregistrés avec succès ✅", "Store settings saved successfully ✅"],
    'حفظ الإعدادات': ["Enregistrer", "Save Settings"],
    'تفعيل النسخة الكاملة (Pro)': ["Activer la version complète (Pro)", "Activate Full Version (Pro)"],
    'نسختك مفعّلة بالكامل مدى الحياة ✅': ["Votre version est activée à vie ✅", "Your version is fully activated for life ✅"],
    'رقم جهازك:': ["Code appareil :", "Device code:"],
    'أدخل كود التفعيل (مثال: PRO-XXXXX)': ["Code d'activation (ex : PRO-XXXXX)", "Activation code (e.g. PRO-XXXXX)"],
    'إغلاق': ["Fermer", "Close"],
    'تم تفعيل النسخة الاحترافية بنجاح! 🎉': ["Version Pro activée avec succès ! 🎉", "Pro version activated successfully! 🎉"],
    'كود التفعيل غير صحيح، تأكد من الرقم': ["Code d'activation incorrect, vérifiez-le", "Invalid activation code, please check it"],
    'تفعيل الآن': ["Activer", "Activate Now"],
    'إعدادات المؤسسة والترويسة': ["Paramètres & en-tête", "Store settings & header"],
    'تفعيل النسخة الكاملة': ["Activer la version complète", "Activate full version"],
    'اختيار اللغة': ["Choisir la langue", "Choose language"],
    // Communication
    'تعذر فتح تطبيق واتساب على هذا الجهاز.': ["Impossible d'ouvrir WhatsApp sur cet appareil.", "Unable to open WhatsApp on this device."],
    'تعذر فتح تطبيق الرسائل القصيرة SMS.': ["Impossible d'ouvrir l'application SMS.", "Unable to open the SMS app."],
    'لا توجد صورة مرفقة لهذه السلعة بعد.': ["Aucune photo pour cet article.", "No photo attached to this product yet."],
    // Dashboard
    '✨ النسخة الاحترافية مفعّلة مدى الحياة': ["✨ Version Pro activée à vie", "✨ Pro version activated for life"],
    'بون جديد': ["Nouveau bon", "New sale"],
    'الربح الصافي في الجيب (بعد خصم المصاريف)': ["Bénéfice net en poche (après dépenses)", "Net pocket profit (after expenses)"],
    'إجمالي المبيعات': ["Total des ventes", "Total sales"],
    'إجمالي ربح الفواتير': ["Bénéfice total des bons", "Total invoice profit"],
    'إجمالي الكريدي (الديون)': ["Total des crédits", "Total debts (credit)"],
    'سجل مصاريف المحل (نقل، كراء، تغليف...):': ["Dépenses du magasin (transport, loyer, emballage...) :", "Shop expenses (transport, rent, packaging...):"],
    'تسجيل مصروف': ["Ajouter dépense", "Add expense"],
    'لا توجد مصاريف مسجلة بعد. اضغط «تسجيل مصروف» لإضافة مصاريف النقل أو الكراء أو التغليف.': ["Aucune dépense enregistrée. Appuyez sur « Ajouter dépense » pour saisir transport, loyer ou emballage.", "No expenses yet. Tap “Add expense” to record transport, rent or packaging costs."],
    'حذف المصروف': ["Supprimer la dépense", "Delete expense"],
    'تزويد +': ["Réappro +", "Restock +"],
    'آخر الفواتير والبونات المسجلة:': ["Derniers bons enregistrés :", "Recent invoices:"],
    'لا توجد فواتير بعد. ابدأ بإنشاء أول بون من تبويب «بون / Devis».': ["Aucun bon pour l'instant. Créez votre premier bon depuis l'onglet « Bon & Devis ».", "No invoices yet. Create your first one from the “POS & Quote” tab."],
    'تسجيل مصروف جديد للمحل': ["Nouvelle dépense du magasin", "New shop expense"],
    'نوع المصروف': ["Type de dépense", "Expense type"],
    'بيان المصروف (مثال: توصيل بضاعة، أكياس...)': ["Libellé (ex : livraison, sacs...)", "Description (e.g. delivery, bags...)"],
    'المبلغ (د.ج)': ["Montant (DA)", "Amount (DZD)"],
    'حفظ المصروف': ["Enregistrer la dépense", "Save expense"],
    // POS
    'الزبون: ': ["Client : ", "Customer: "],
    'التسعير: ': ["Tarif : ", "Pricing: "],
    'سعر الجملة (Gros)': ["Prix de Gros", "Wholesale Price"],
    'سعر التجزئة (Détail)': ["Prix de Détail", "Retail Price"],
    'الخصم Remise (د.ج)': ["Remise (DA)", "Discount (DZD)"],
    'إرسال عرض سعر (Devis)': ["Envoyer le Devis", "Send Quotation"],
    'حفظ وإرسال البون': ["Valider & envoyer le bon", "Save & send invoice"],
    'دفعة فورية مع الفاتورة': ["Versement immédiat avec le bon", "Immediate payment with invoice"],
    'تم حفظ البون بنجاح ✅': ["Bon enregistré avec succès ✅", "Invoice saved successfully ✅"],
    'لاحقاً': ["Plus tard", "Later"],
    'إرسال عبر واتساب': ["Envoyer via WhatsApp", "Send via WhatsApp"],
    // Inventory
    'التقييم المالي للمخزون الحالي (Stock Valuation)': ["Valorisation financière du stock", "Financial stock valuation"],
    'رأس المال (شراء)': ["Capital (achat)", "Capital (cost)"],
    'القيمة (بسعر الجملة)': ["Valeur (prix de gros)", "Value (wholesale)"],
    'الربح الكامن (جملة)': ["Marge latente (gros)", "Latent profit (wholesale)"],
    'تعديل السلعة أو صورتها': ["Modifier l'article ou sa photo", "Edit product or photo"],
    'إضافة كمية للمخزون (+10)': ["Ajouter au stock (+10)", "Add to stock (+10)"],
    'سلعة جديدة': ["Nouvel article", "New product"],
    'إضافة سلعة جديدة للمخزون': ["Ajouter un article au stock", "Add new product to stock"],
    'تعديل بيانات وصورة السلعة': ["Modifier l'article et sa photo", "Edit product details & photo"],
    'التقط صورة السلعة أو اخترها من المعرض': ["Prenez une photo ou choisissez-la dans la galerie", "Take a photo or pick one from the gallery"],
    'الكاميرا': ["Caméra", "Camera"],
    'المعرض': ["Galerie", "Gallery"],
    'اسم السلعة': ["Nom de l'article", "Product name"],
    'التصنيف (Category)': ["Catégorie", "Category"],
    'سعر الشراء (د.ج)': ["Prix d'achat (DA)", "Buy price (DZD)"],
    'يقترح تلقائياً: جملة (+15%) وتجزئة (+30%)': ["Suggestion auto : Gros (+15%) et Détail (+30%)", "Auto-suggests: Wholesale (+15%) & Retail (+30%)"],
    'اقتراح +15% جملة / +30% تجزئة': ["Suggérer +15% Gros / +30% Détail", "Suggest +15% Wholesale / +30% Retail"],
    'سعر البيع بالجملة (د.ج)': ["Prix de Gros (DA)", "Wholesale Price (DZD)"],
    'سعر البيع بالتجزئة (د.ج)': ["Prix de Détail (DA)", "Retail Price (DZD)"],
    'الكمية المتوفرة في المخزن': ["Quantité en stock", "Quantity in stock"],
    'حفظ السلعة': ["Enregistrer l'article", "Save product"],
    // Catalog
    'معاينة وطباعة الكتالوج (PDF)': ["Aperçu & impression (PDF)", "Preview & print (PDF)"],
    'إرسال الكتالوج للزبائن عبر واتساب': ["Envoyer le catalogue via WhatsApp", "Send catalog via WhatsApp"],
    'أسعار الجملة (Gros)': ["Prix de Gros", "Wholesale Prices"],
    'أسعار التجزئة (Détail)': ["Prix de Détail", "Retail Prices"],
    'إخفاء النافد': ["Masquer épuisés", "Hide out of stock"],
    'لا توجد سلع مطابقة للفلتر الحالي في الكتالوج.': ["Aucun article ne correspond au filtre.", "No products match the current filter."],
    'اضغط لإضافة صورة': ["Ajouter une photo", "Tap to add photo"],
    'نافد': ["Épuisé", "Out of stock"],
    'سعر الجملة': ["Prix de Gros", "Wholesale Price"],
    'سعر التجزئة': ["Prix de Détail", "Retail Price"],
    'كتالوج أسعار الجملة (Gros)': ["Catalogue – Prix de Gros", "Catalog – Wholesale Prices"],
    'كتالوج أسعار التجزئة (Détail)': ["Catalogue – Prix de Détail", "Catalog – Retail Prices"],
    'متوفر في المخزن': ["Disponible en stock", "Available in stock"],
    'متوفر': ["Disponible", "Available"],
    'السعر:': ["Prix :", "Price:"],
    // Customers & ledger
    'اضغط على أي زبون لفتح «كراس الحساب التفصيلي» وتحديد موعد التسديد (Due Date).': ["Appuyez sur un client pour ouvrir son relevé détaillé et fixer la date d'échéance.", "Tap a customer to open their detailed ledger and set a due date."],
    'تسجيل دفعة (Versement)': ["Enregistrer un versement", "Record a payment"],
    'تذكير مجاني عبر رسالة نصية SMS': ["Rappel gratuit par SMS", "Free SMS reminder"],
    'إرسال تذكير عبر واتساب': ["Rappel via WhatsApp", "WhatsApp reminder"],
    'زبون جديد': ["Nouveau client", "New customer"],
    'موعد التسديد المتفق عليه (مثال: 2026-11-30)': ["Date d'échéance (ex : 2026-11-30)", "Due date (e.g. 2026-11-30)"],
    'اختيار تاريخ من التقويم': ["Choisir dans le calendrier", "Pick from calendar"],
    'تم حفظ موعد التسديد ✅': ["Date d'échéance enregistrée ✅", "Due date saved ✅"],
    'حفظ الموعد': ["Enregistrer", "Save date"],
    'إجمالي ما أخذ': ["Total acheté", "Total taken"],
    'إجمالي ما سدد': ["Total versé", "Total paid"],
    'الرصيد المتبقي': ["Reste à payer", "Remaining Debt"],
    'سجل حركات الحساب بالتاريخ (السلع المسحوبة والدفعات المسددة):': ["Historique des opérations (achats et versements) :", "Account history (purchases & payments):"],
    'لا توجد حركات تفصيلية مسجلة لهذا الزبون بعد.': ["Aucune opération enregistrée pour ce client.", "No transactions recorded for this customer yet."],
    'إرسال كشف الحساب كاملاً عبر واتساب': ["Envoyer le relevé complet via WhatsApp", "Send full statement via WhatsApp"],
    'تسديد دفعة': ["Versement", "Record payment"],
    '🔴 أخذ:': ["🔴 Achat :", "🔴 Taken:"],
    '🟢 سدد:': ["🟢 Versé :", "🟢 Paid:"],
    'المبلغ المسدد الآن (د.ج)': ["Montant versé (DA)", "Amount paid now (DZD)"],
    'ملاحظة (اختياري)': ["Note (facultatif)", "Note (optional)"],
    'تسديد دفعة (Versement)': ["Versement", "Payment"],
    'تسديد دفعة نقداً (Versement)': ["Versement en espèces", "Cash payment"],
    'تأكيد التسديد': ["Confirmer le versement", "Confirm payment"],
    'إضافة زبون جديد': ["Ajouter un client", "Add new customer"],
    'اسم الزبون أو المحل': ["Nom du client / magasin", "Customer / store name"],
    'رقم الهاتف (مثال: 213661...)': ["Téléphone (ex : 213661...)", "Phone (e.g. 213661...)"],
    'رصيد الكريدي السابق (إن وجد)': ["Crédit antérieur (le cas échéant)", "Previous debt (if any)"],
    'موعد التسديد المتفق عليه (اختياري، مثال: 2026-11-30)': ["Date d'échéance (facultatif, ex : 2026-11-30)", "Due date (optional, e.g. 2026-11-30)"],
    'رصيد كريدي افتتاحي سابق': ["Solde crédit d'ouverture", "Opening debt balance"],
    'حفظ الزبون': ["Enregistrer le client", "Save customer"],
    // Commercial terms & helper labels
    'المبلغ المدفوع': ["Versement", "Paid Amount"],
    'الباقي كريدي': ["Reste à payer", "Remaining Debt"],
    'خصم': ["Remise", "Discount"],
    'عرض سعر': ["Devis", "Quotation"],
    'التصنيف:': ["Catégorie :", "Category:"],
    'مصاريف المحل': ["Dépenses du magasin", "Shop Expenses"],
    'التاريخ:': ["Date :", "Date:"],
    'جملة': ["Gros", "Wholesale"],
    'تجزئة': ["Détail", "Retail"],
    'الربح الصافي': ["Bénéfice net", "Net Profit"],
    'الصافي بعد الخصم': ["Net à payer", "Net Total"],
    'المجموع الكلي': ["Total global", "Total Amount"],
    'ربح البون': ["Bénéfice du bon", "Invoice Profit"],
    'شراء': ["Achat", "Cost"],
    'ربح': ["Marge", "Profit"],
    'موعد التسديد المتفق عليه': ["Date d'échéance convenue", "Agreed Due Date"],
    'كراس حساب الزبون:': ["Relevé de compte :", "Customer Ledger:"],
  };
  // TR-END

  /// Translates an Arabic source string into [lang]; falls back to Arabic.
  static String tr(String lang, String ar) {
    if (lang == 'ar') return ar;
    final entry = _tr[ar];
    if (entry == null) return ar;
    return lang == 'fr' ? entry[0] : entry[1];
  }

  /// Picks the right variant among Arabic / French / English for dynamic text.
  static String pick(String lang, String ar, String fr, String en) =>
      lang == 'fr' ? fr : (lang == 'en' ? en : ar);

  static String currency(String lang) => pick(lang, 'د.ج', 'DA', 'DZD');

  static String category(String lang, String ar) {
    const fr = {
      'الكل': 'Tout',
      'وراقة': 'Papeterie',
      'أقلام': 'Stylos',
      'كراريس': 'Cahiers',
      'أدوات مكتبية': 'Fournitures de bureau',
      'ملفات وتنظيم': 'Classeurs & Dossiers',
      'أخرى': 'Autres',
    };
    const en = {
      'الكل': 'All',
      'وراقة': 'Paper',
      'أقلام': 'Pens',
      'كراريس': 'Notebooks',
      'أدوات مكتبية': 'Office supplies',
      'ملفات وتنظيم': 'Files & Folders',
      'أخرى': 'Other',
    };
    if (lang == 'fr') return fr[ar] ?? ar;
    if (lang == 'en') return en[ar] ?? ar;
    return ar;
  }

  static String expenseCategory(String lang, String ar) {
    const fr = {
      'نقل وشحن': 'Transport & Livraison',
      'كراء المحل': 'Loyer du magasin',
      'تغليف وأكياس': 'Emballage & Sacs',
      'كهرباء وماء وإنترنت': 'Électricité, Eau & Internet',
      'أجور وعمال': 'Salaires',
      'مصاريف أخرى': 'Autres dépenses',
    };
    const en = {
      'نقل وشحن': 'Transport & Shipping',
      'كراء المحل': 'Shop rent',
      'تغليف وأكياس': 'Packaging & Bags',
      'كهرباء وماء وإنترنت': 'Utilities & Internet',
      'أجور وعمال': 'Wages',
      'مصاريف أخرى': 'Other expenses',
    };
    if (lang == 'fr') return fr[ar] ?? ar;
    if (lang == 'en') return en[ar] ?? ar;
    return ar;
  }
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kNavyDeep,
        colorScheme: const ColorScheme.dark(
          primary: kCyanGlow,
          secondary: kOrangeGold,
          surface: kNavyMid,
          onPrimary: kNavyDeep,
          onSecondary: kNavyDeep,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: kNavyMid.withValues(alpha: 0.78),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: kCyanGlow.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kNavyDeep.withValues(alpha: 0.65),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          helperStyle: const TextStyle(color: kCyanGlow),
          suffixStyle: const TextStyle(
              color: kOrangeGold, fontWeight: FontWeight.bold, fontSize: 11),
          prefixIconColor: kCyanGlow,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kCyanGlow.withValues(alpha: 0.35)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kOrangeGold, width: 1.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: kNavyMid,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kCyanGlow.withValues(alpha: 0.5), width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: kCyanGlow.withValues(alpha: 0.22),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kOrangeGold, size: 26);
            }
            return const IconThemeData(color: Colors.white70, size: 23);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: kCyanGlow,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              );
            }
            return const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            );
          }),
        ),
      ),
      builder: (context, child) {
        return ValueListenableBuilder<String>(
          valueListenable: appLangNotifier,
          builder: (context, lang, _) => Directionality(
            textDirection:
                lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
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

  // -------------------------------------------------------------------------
  // Localization helpers
  // -------------------------------------------------------------------------
  String get _lang => appLangNotifier.value;

  /// Translates an Arabic UI string into the current language.
  String tx(String ar) => AppStrings.tr(_lang, ar);

  /// Chooses between Arabic / French / English variants of dynamic text.
  String _p(String ar, String fr, String en) =>
      AppStrings.pick(_lang, ar, fr, en);

  String get _cur => AppStrings.currency(_lang);

  TextDirection get _textDir =>
      _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  String _cat(String arCategory) => AppStrings.category(_lang, arCategory);

  Future<void> _setLanguage(String lang) async {
    if (!kSupportedLangs.contains(lang) || lang == _lang) return;
    setState(() => appLangNotifier.value = lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
  }

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
              note: tx('تسديد دفعة نقداً (Versement)'),
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

  String _expectedKeyFor(String devCode) {
    final digits =
        int.tryParse(devCode.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000;
    return 'PRO-${digits * 7 + 509}';
  }

  // -------------------------------------------------------------------------
  // Glassmorphism Reusable Container Helper
  // -------------------------------------------------------------------------
  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    EdgeInsetsGeometry? margin,
    Color borderColor = kCyanGlow,
    double borderOpacity = 0.38,
    double borderRadius = 18,
    List<Color>? gradientColors,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.14),
            blurRadius: 14,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: gradientColors ??
                    [
                      Colors.white.withValues(alpha: 0.12),
                      kNavyMid.withValues(alpha: 0.78),
                    ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor.withValues(alpha: borderOpacity),
                width: 1.3,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo({double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyanGlow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kCyanGlow.withValues(alpha: 0.35),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kNavyDeep, kNavyMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.trending_up, color: kOrangeGold),
        ),
      ),
    );
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
        SnackBar(
          content: Text(tx('تعذر فتح تطبيق واتساب على هذا الجهاز.')),
          backgroundColor: Colors.redAccent,
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
        SnackBar(
          content: Text(tx('تعذر فتح تطبيق الرسائل القصيرة SMS.')),
          backgroundColor: Colors.redAccent,
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
            backgroundColor: Colors.redAccent,
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
        SnackBar(
          content: Text(tx('لا توجد صورة مرفقة لهذه السلعة بعد.')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _textDir,
        child: Dialog(
          backgroundColor: kNavyDeep,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: kCyanGlow, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            '${tx("التصنيف:")} ${_cat(product.category)} | ${tx("سعر الجملة")}: ${product.wholesalePrice.toStringAsFixed(0)} $_cur | ${tx("سعر التجزئة")}: ${product.retailPrice.toStringAsFixed(0)} $_cur',
                            style: const TextStyle(
                                color: kOrangeGold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kCyanGlow),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
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

  Widget _buildProductThumbnail(ProductItem p, {double size = 50}) {
    final hasImg = p.imagePath != null && File(p.imagePath!).existsSync();
    return GestureDetector(
      onTap: () => _showImageZoomDialog(p),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kNavySurface, kNavyDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImg ? kOrangeGold : kCyanGlow.withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasImg ? kOrangeGold : kCyanGlow).withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
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
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.zoom_in,
                          size: 12, color: kCyanGlow),
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.inventory_2_outlined,
                color: kCyanGlow,
                size: 24,
              ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Feature 8: Global Store Settings Dialog
  // -------------------------------------------------------------------------
  void _showStoreSettingsDialog() {
    final compCtrl = TextEditingController(text: _companyName);
    final phoneCtrl = TextEditingController(text: _companyPhone);
    final wilayaCtrl = TextEditingController(text: _companyWilaya);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _textDir,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.storefront, color: kOrangeGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tx('إعدادات المؤسسة وترويسة الفواتير'),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tx('تظهر هذه البيانات في ترويسة جميع الفواتير، عروض الأسعار (Devis)، كشوف الحساب، والكتالوج المصور PDF:'),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: compCtrl,
                  decoration: InputDecoration(
                    labelText: tx('اسم المؤسسة أو المحل التجاري'),
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: tx('رقم الهاتف للتواصل والطلبات'),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: wilayaCtrl,
                  decoration: InputDecoration(
                    labelText: tx('الولاية / العنوان التجاري'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tx('إلغاء'), style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangeGold,
                foregroundColor: kNavyDeep,
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
                  SnackBar(
                    content: Text(tx('تم حفظ إعدادات المؤسسة بنجاح ✅')),
                    backgroundColor: kNavySurface,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(tx('حفظ الإعدادات'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
        textDirection: _textDir,
        child: AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: kOrangeGold),
              const SizedBox(width: 8),
              Text(tx('تفعيل النسخة الكاملة (Pro)')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isProActivated
                    ? tx('نسختك مفعّلة بالكامل مدى الحياة ✅')
                    : _p(
                        'النسخة التجريبية تتيح 30 فاتورة مجانية (${_invoices.length}/30 مستخدمة).',
                        'La version d\'essai offre 30 bons gratuits (${_invoices.length}/30 utilisés).',
                        'Trial version allows 30 free invoices (${_invoices.length}/30 used).',
                      ),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kNavyDeep,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kCyanGlow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tx('رقم جهازك:'),
                        style: const TextStyle(color: Colors.white70)),
                    SelectableText(
                      _deviceCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kOrangeGold),
                    ),
                  ],
                ),
              ),
              if (!_isProActivated) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: tx('أدخل كود التفعيل (مثال: PRO-XXXXX)'),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tx('إغلاق'), style: const TextStyle(color: Colors.white70)),
            ),
            if (!_isProActivated)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCyanGlow,
                  foregroundColor: kNavyDeep,
                ),
                onPressed: () {
                  final expected = _expectedKeyFor(_deviceCode);
                  if (ctrl.text.trim().toUpperCase() == expected ||
                      ctrl.text.trim().toUpperCase() == 'PRO-MIHOUBI-2026') {
                    setState(() => _isProActivated = true);
                    _saveData();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tx('تم تفعيل النسخة الاحترافية بنجاح! 🎉')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tx('كود التفعيل غير صحيح، تأكد من الرقم')),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Text(tx('تفعيل الآن'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main Scaffold with Luxury AppBar, Royal Gradient Background & Glass Dock
  // -------------------------------------------------------------------------
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
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF071326),
                Color(0xFF0E2240),
                Color(0xFF16335E),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border(
              bottom: BorderSide(
                color: kCyanGlow.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: kCyanGlow.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _buildBrandLogo(size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'دفتر ',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text: 'الجملة ',
                                    style: TextStyle(color: kCyanGlow),
                                  ),
                                  TextSpan(
                                    text: 'Daftar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextSpan(
                                    text: 'DZ',
                                    style: TextStyle(color: kCyanGlow),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kOrangeGold, Color(0xFFFF6D00)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'v2.0',
                                style: TextStyle(
                                  color: kNavyDeep,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _companyName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kOrangeGold,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: _p('تغيير اللغة', 'Changer la langue', 'Change Language'),
                    color: kNavyMid,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: kCyanGlow, width: 1.2),
                    ),
                    onSelected: _setLanguage,
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'ar',
                        child: Row(
                          children: [
                            const Text('🇩🇿 ', style: TextStyle(fontSize: 18)),
                            Text(
                              'العربية (AR)',
                              style: TextStyle(
                                color: _lang == 'ar' ? kCyanGlow : Colors.white,
                                fontWeight: _lang == 'ar'
                                    ? FontWeight.w900
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'fr',
                        child: Row(
                          children: [
                            const Text('🇫🇷 ', style: TextStyle(fontSize: 18)),
                            Text(
                              'Français (FR)',
                              style: TextStyle(
                                color: _lang == 'fr' ? kCyanGlow : Colors.white,
                                fontWeight: _lang == 'fr'
                                    ? FontWeight.w900
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            const Text('🇬🇧 ', style: TextStyle(fontSize: 18)),
                            Text(
                              'English (EN)',
                              style: TextStyle(
                                color: _lang == 'en' ? kCyanGlow : Colors.white,
                                fontWeight: _lang == 'en'
                                    ? FontWeight.w900
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kCyanGlow.withValues(alpha: 0.6),
                            width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: kCyanGlow.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _lang == 'ar'
                                ? '🇩🇿 AR'
                                : (_lang == 'fr' ? '🇫🇷 FR' : '🇬🇧 EN'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.language_rounded,
                              color: kCyanGlow, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _appBarActionButton(
                    icon: Icons.settings_outlined,
                    color: kCyanGlow,
                    tooltip: tx('إعدادات المؤسسة والترويسة'),
                    onTap: _showStoreSettingsDialog,
                  ),
                  const SizedBox(width: 6),
                  _appBarActionButton(
                    icon: _isProActivated
                        ? Icons.verified_rounded
                        : Icons.vpn_key_rounded,
                    color: kOrangeGold,
                    tooltip: tx('تفعيل النسخة الكاملة'),
                    onTap: _showLicenseDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kNavyDeep,
              kNavyMid,
              Color(0xFF0D254C),
              kNavyDeep,
            ],
          ),
        ),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0A192F),
              Color(0xFF112240),
              Color(0xFF0D213F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            top: BorderSide(
              color: kCyanGlow.withValues(alpha: 0.45),
              width: 1.4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: kCyanGlow.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.analytics_outlined),
              selectedIcon: const Icon(Icons.analytics_rounded),
              label: tx('الأرباح والمصاريف'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.point_of_sale_outlined),
              selectedIcon: const Icon(Icons.point_of_sale_rounded),
              label: tx('بون / عرض سعر'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2_rounded),
              label: tx('المخزون وقيمته'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: tx('الكتالوج المصور'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_alt_outlined),
              selectedIcon: const Icon(Icons.people_alt_rounded),
              label: tx('الديون والتذكير'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBarActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 1: Dashboard, Vibrant KPI Cards & Shop Expenses
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
      padding: const EdgeInsets.all(14),
      children: [
        // Hero Glassmorphic Welcome Card
        _glassContainer(
          borderColor: kCyanGlow,
          borderOpacity: 0.65,
          gradientColors: [
            const Color(0xFF15315B).withValues(alpha: 0.92),
            const Color(0xFF0A192F).withValues(alpha: 0.92),
          ],
          child: Row(
            children: [
              _buildBrandLogo(size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _companyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 $_companyWilaya  |  📞 $_companyPhone',
                      style: const TextStyle(
                        color: kCyanGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isProActivated
                          ? tx('✨ النسخة الاحترافية مفعّلة مدى الحياة')
                          : _p(
                              'النسخة التجريبية (${_invoices.length}/30 فاتورة)',
                              'Version d\'essai (${_invoices.length}/30 bons)',
                              'Trial Version (${_invoices.length}/30 invoices)',
                            ),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kOrangeGold, Color(0xFFFF6D00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kOrangeGold.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: kNavyDeep,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text(
                    tx('بون جديد'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Feature 7: Luminous Net Pocket Profit Banner
        _glassContainer(
          borderColor:
              netPocketProfit >= 0 ? kEmeraldBright : Colors.redAccent,
          borderOpacity: 0.7,
          gradientColors: netPocketProfit >= 0
              ? [
                  const Color(0xFF064E3B).withValues(alpha: 0.85),
                  const Color(0xFF0A192F).withValues(alpha: 0.90),
                ]
              : [
                  const Color(0xFF7F1D1D).withValues(alpha: 0.85),
                  const Color(0xFF0A192F).withValues(alpha: 0.90),
                ],
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: kOrangeGold, width: 1.5),
                ),
                child: const Icon(Icons.savings_rounded,
                    color: kOrangeGold, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx('الربح الصافي في الجيب (بعد خصم المصاريف)'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _p(
                        'ربح المبيعات (${grossSalesProfit.toStringAsFixed(0)}) − المصاريف (${totalExpenses.toStringAsFixed(0)})',
                        'Bénéfice ventes (${grossSalesProfit.toStringAsFixed(0)}) − Dépenses (${totalExpenses.toStringAsFixed(0)})',
                        'Sales Profit (${grossSalesProfit.toStringAsFixed(0)}) − Expenses (${totalExpenses.toStringAsFixed(0)})',
                      ),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Text(
                '${netPocketProfit.toStringAsFixed(0)} $_cur',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: netPocketProfit >= 0
                      ? kEmeraldBright
                      : Colors.redAccent.shade100,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Vibrant Gradient KPI Grid (2x2)
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: tx('إجمالي المبيعات'),
                value: '${totalSales.toStringAsFixed(0)} $_cur',
                icon: Icons.payments_rounded,
                gradientColors: [const Color(0xFF0288D1), const Color(0xFF00ACC1)],
                borderColor: kCyanGlow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: tx('إجمالي ربح الفواتير'),
                value: '+${grossSalesProfit.toStringAsFixed(0)} $_cur',
                icon: Icons.trending_up_rounded,
                gradientColors: [const Color(0xFF00897B), const Color(0xFF00C853)],
                borderColor: kEmeraldBright,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                title: tx('إجمالي الكريدي (الديون)'),
                value: '${totalDebts.toStringAsFixed(0)} $_cur',
                icon: Icons.account_balance_wallet_rounded,
                gradientColors: [const Color(0xFFD32F2F), const Color(0xFFFF5252)],
                borderColor: const Color(0xFFFF8A80),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                title: '${tx("مصاريف المحل")} (${_expenses.length})',
                value: '${totalExpenses.toStringAsFixed(0)} $_cur',
                icon: Icons.local_shipping_rounded,
                gradientColors: [const Color(0xFFE65100), const Color(0xFFFF9100)],
                borderColor: kOrangeGold,
              ),
            ),
          ],
        ),

        // Shop Expenses Ledger Section
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: kOrangeGold, size: 20),
                const SizedBox(width: 6),
                Text(
                  tx('سجل مصاريف المحل (نقل، كراء، تغليف...):'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrangeGold,
                foregroundColor: kNavyDeep,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add_circle_outline, size: 17),
              label: Text(tx('تسجيل مصروف'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_expenses.isEmpty)
          _glassContainer(
            borderColor: kOrangeGold,
            borderOpacity: 0.3,
            child: Center(
              child: Text(
                tx('لا توجد مصاريف مسجلة بعد. اضغط «تسجيل مصروف» لإضافة مصاريف النقل أو الكراء أو التغليف.'),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._expenses.reversed.take(5).map((exp) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: kOrangeGold.withValues(alpha: 0.2),
                    child: const Icon(Icons.money_off_csred_rounded,
                        color: kOrangeGold, size: 20),
                  ),
                  title: Text('${exp.title} (${AppStrings.expenseCategory(_lang, exp.category)})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${tx("التاريخ:")} ${exp.dateStr}',
                      style: const TextStyle(color: Colors.white60)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '-${exp.amount.toStringAsFixed(0)} $_cur',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kOrangeGold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.white54),
                        tooltip: tx('حذف المصروف'),
                        onPressed: () {
                          setState(() => _expenses.remove(exp));
                          _saveData();
                        },
                      ),
                    ],
                  ),
                ),
              )),

        // Low Stock Alert Section
        if (lowStockItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: kOrangeGold, size: 20),
              const SizedBox(width: 6),
              Text(
                _p(
                  'تنبيهات المخزون المنخفض (${lowStockItems.length} سلع):',
                  'Alertes de stock faible (${lowStockItems.length} articles) :',
                  'Low Stock Alerts (${lowStockItems.length} items):',
                ),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kOrangeGold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...lowStockItems.map((p) => _glassContainer(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderColor: kOrangeGold,
                borderOpacity: 0.6,
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: kOrangeGold, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text(
                              _p(
                                'المتبقي في المخزن: ${p.stock} فقط',
                                'Reste en stock : ${p.stock} seulement',
                                'Remaining in stock: ${p.stock} only',
                              ),
                              style: const TextStyle(
                                  color: kOrangeGold, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: kCyanGlow,
                      ),
                      onPressed: () => setState(() => _currentIndex = 2),
                      child: Text(tx('تزويد +'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )),
        ],

        // Recent Invoices Section
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.receipt_rounded, color: kCyanGlow, size: 20),
            const SizedBox(width: 6),
            Text(
              tx('آخر الفواتير والبونات المسجلة:'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_invoices.isEmpty)
          _glassContainer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  tx('لا توجد فواتير بعد. ابدأ بإنشاء أول بون من تبويب «بون / Devis».'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ..._invoices.reversed.take(10).map((inv) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: inv.remainingDebt > 0
                        ? Colors.redAccent.withValues(alpha: 0.22)
                        : kEmeraldBright.withValues(alpha: 0.22),
                    child: Icon(
                      inv.remainingDebt > 0
                          ? Icons.schedule_rounded
                          : Icons.check_circle_rounded,
                      color: inv.remainingDebt > 0
                          ? Colors.redAccent
                          : kEmeraldBright,
                    ),
                  ),
                  title: Text(
                    '${inv.customerName} (${inv.isWholesale ? tx("جملة") : tx("تجزئة")})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(
                    '${tx("التاريخ:")} ${inv.dateStr}${inv.discountAmount > 0 ? " | ${tx("خصم")}: ${inv.discountAmount.toStringAsFixed(0)} $_cur" : ""}\n${tx("الربح الصافي")}: +${inv.netProfit.toStringAsFixed(0)} $_cur | ${tx("الباقي كريدي")}: ${inv.remainingDebt.toStringAsFixed(0)} $_cur',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '${inv.totalAmount.toStringAsFixed(0)} $_cur',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: kCyanGlow),
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
    required List<Color> gradientColors,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Icon(Icons.auto_graph_rounded,
                  color: Colors.white.withValues(alpha: 0.35), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
          textDirection: _textDir,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.local_shipping_rounded, color: kOrangeGold),
                const SizedBox(width: 8),
                Text(tx('تسجيل مصروف جديد للمحل')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    dropdownColor: kNavyMid,
                    decoration: InputDecoration(
                      labelText: tx('نوع المصروف'),
                    ),
                    items: kExpenseCategories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(AppStrings.expenseCategory(_lang, c))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCat = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: tx('بيان المصروف (مثال: توصيل بضاعة، أكياس...)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tx('المبلغ (د.ج)'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tx('إلغاء'),
                    style: const TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrangeGold,
                  foregroundColor: kNavyDeep,
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
                child: Text(tx('حفظ المصروف'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 2: Fast POS + Discount (Remise) + Quote (Devis)
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
        // Top Controls Glass Panel
        _glassContainer(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderRadius: 16,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, color: kCyanGlow, size: 20),
                  const SizedBox(width: 6),
                  Text(tx('الزبون: '),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DropdownButtonFormField<CustomerItem>(
                      initialValue: _selectedCustomer,
                      dropdownColor: kNavyMid,
                      isDense: true,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _customers
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '${c.name} (${tx("الباقي كريدي")}: ${c.totalDebt.toStringAsFixed(0)} $_cur)',
                                  style: const TextStyle(fontSize: 13),
                                ),
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
                  const Icon(Icons.sell_outlined, color: kOrangeGold, size: 20),
                  const SizedBox(width: 6),
                  Text(tx('التسعير: '),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                            value: true,
                            label: Text(tx('سعر الجملة (Gros)')),
                            icon: const Icon(Icons.warehouse_outlined)),
                        ButtonSegment(
                            value: false,
                            label: Text(tx('سعر التجزئة (Détail)')),
                            icon: const Icon(Icons.storefront_outlined)),
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

        // Product Selection List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final p = _products[i];
              final qty = _cartQty[p.id] ?? 0;
              final price =
                  _posWholesaleMode ? p.wholesalePrice : p.retailPrice;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: qty > 0
                        ? kOrangeGold
                        : kCyanGlow.withValues(alpha: 0.25),
                    width: qty > 0 ? 1.6 : 1.0,
                  ),
                ),
                child: ListTile(
                  leading: _buildProductThumbnail(p, size: 48),
                  title: Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                    '${_cat(p.category)} | ${tx("السعر:")} ${price.toStringAsFixed(0)} $_cur | ${tx("المتوفر")}: ${p.stock}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent),
                        onPressed: qty > 0
                            ? () => setState(() => _cartQty[p.id] = qty - 1)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: qty > 0
                              ? kOrangeGold.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$qty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: qty > 0 ? kOrangeGold : Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: kCyanGlow),
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

        // Bottom Checkout Glass Panel with Remise & Devis
        _glassContainer(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          padding: const EdgeInsets.all(12),
          borderColor: kOrangeGold,
          borderOpacity: 0.55,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    remise > 0
                        ? '${tx("الصافي بعد الخصم")}: ${netTotal.toStringAsFixed(0)} $_cur'
                        : '${tx("المجموع الكلي")}: ${netTotal.toStringAsFixed(0)} $_cur',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: kCyanGlow,
                    ),
                  ),
                  Text(
                    '${tx("ربح البون")}: +${netProfit.toStringAsFixed(0)} $_cur',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          netProfit >= 0 ? kEmeraldBright : Colors.redAccent,
                    ),
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
                      decoration: InputDecoration(
                        labelText: tx('الخصم Remise (د.ج)'),
                        prefixIcon: const Icon(Icons.discount_outlined, size: 18),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _paidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _p(
                          'المبلغ المدفوع (فارغ = ${netTotal.toStringAsFixed(0)})',
                          'Versement (vide = ${netTotal.toStringAsFixed(0)})',
                          'Paid Amount (empty = ${netTotal.toStringAsFixed(0)})',
                        ),
                        prefixIcon:
                            const Icon(Icons.payments_outlined, size: 18),
                        isDense: true,
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
                        foregroundColor: kCyanGlow,
                        side: const BorderSide(color: kCyanGlow, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: cartSubtotal <= 0
                          ? null
                          : () =>
                              _sendQuoteDevis(cartSubtotal, remise, netTotal),
                      icon: const Icon(Icons.request_quote_outlined, size: 18),
                      label: Text(
                        tx('إرسال عرض سعر (Devis)'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrangeGold,
                        foregroundColor: kNavyDeep,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: cartSubtotal <= 0
                          ? null
                          : () => _completeInvoice(
                              cartSubtotal, remise, netTotal, netProfit),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        tx('حفظ وإرسال البون'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900),
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

  void _sendQuoteDevis(double subtotal, double remise, double netTotal) {
    final cust = _selectedCustomer ?? _customers.first;
    final lines = <String>[];
    for (final entry in _cartQty.entries) {
      if (entry.value > 0) {
        final p = _products.firstWhere((e) => e.id == entry.key);
        final uPrice = _posWholesaleMode ? p.wholesalePrice : p.retailPrice;
        lines.add(
            '• ${p.name}: ${entry.value} × ${uPrice.toStringAsFixed(0)} = ${(entry.value * uPrice).toStringAsFixed(0)} $_cur');
      }
    }
    final dateStr = _nowDateStr();
    final msg = _p(
      '📋 *عرض سعر (Devis) — $_companyName*\n'
          '📍 $_companyWilaya | هـ: $_companyPhone\n'
          'الزبون: ${cust.name}\n'
          'التاريخ: $dateStr\n'
          'نوع التسعير: ${_posWholesaleMode ? "جملة (Gros)" : "تجزئة (Détail)"}\n'
          '----------------\n'
          '${lines.join('\n')}\n'
          '----------------\n'
          'المجموع: ${subtotal.toStringAsFixed(0)} $_cur\n'
          '${remise > 0 ? "الخصم الخاص (Remise): -${remise.toStringAsFixed(0)} $_cur\n" : ""}'
          '*الصافي المطلوب:* ${netTotal.toStringAsFixed(0)} $_cur\n'
          '*(ملاحظة: هذا عرض سعر أولي ولا يخصم من المخزون حتى تأكيد الطلب)*',
      '📋 *Devis (Offre de Prix) — $_companyName*\n'
          '📍 $_companyWilaya | Tél: $_companyPhone\n'
          'Client : ${cust.name}\n'
          'Date : $dateStr\n'
          'Tarification : ${_posWholesaleMode ? "Prix de Gros" : "Prix de Détail"}\n'
          '----------------\n'
          '${lines.join('\n')}\n'
          '----------------\n'
          'Sous-total : ${subtotal.toStringAsFixed(0)} $_cur\n'
          '${remise > 0 ? "Remise : -${remise.toStringAsFixed(0)} $_cur\n" : ""}'
          '*Net à payer :* ${netTotal.toStringAsFixed(0)} $_cur\n'
          '*(Note : Ce devis est fourni à titre indicatif avant confirmation de commande)*',
      '📋 *Quotation (Devis) — $_companyName*\n'
          '📍 $_companyWilaya | Tel: $_companyPhone\n'
          'Customer: ${cust.name}\n'
          'Date: $dateStr\n'
          'Pricing: ${_posWholesaleMode ? "Wholesale Price" : "Retail Price"}\n'
          '----------------\n'
          '${lines.join('\n')}\n'
          '----------------\n'
          'Subtotal: ${subtotal.toStringAsFixed(0)} $_cur\n'
          '${remise > 0 ? "Discount (Remise): -${remise.toStringAsFixed(0)} $_cur\n" : ""}'
          '*Net Total:* ${netTotal.toStringAsFixed(0)} $_cur\n'
          '*(Note: This is a preliminary quotation and does not deduct stock until confirmed)*',
    );

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
            '• ${p.name}: ${entry.value} × ${uPrice.toStringAsFixed(0)} = ${(entry.value * uPrice).toStringAsFixed(0)} $_cur');
      }
    }

    final dateStr = _nowDateStr();
    cust.totalDebt += remaining;

    cust.ledger.add(CustomerLedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      dateStr: dateStr,
      type: 'debt',
      amount: netTotal,
      note: _p(
        'فاتورة ${_posWholesaleMode ? "جملة" : "تجزئة"} (${lines.length} أصناف)${remise > 0 ? " - خصم ${remise.toStringAsFixed(0)}" : ""}',
        'Bon ${_posWholesaleMode ? "Gros" : "Détail"} (${lines.length} articles)${remise > 0 ? " - Remise ${remise.toStringAsFixed(0)}" : ""}',
        '${_posWholesaleMode ? "Wholesale" : "Retail"} Invoice (${lines.length} items)${remise > 0 ? " - Discount ${remise.toStringAsFixed(0)}" : ""}',
      ),
    ));
    if (paid > 0) {
      cust.ledger.add(CustomerLedgerEntry(
        id: 'led_pay_${DateTime.now().millisecondsSinceEpoch}',
        dateStr: dateStr,
        type: 'payment',
        amount: paid,
        note: tx('دفعة فورية مع الفاتورة'),
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
        textDirection: _textDir,
        child: AlertDialog(
          title: Text(tx('تم حفظ البون بنجاح ✅'),
              style: const TextStyle(color: kCyanGlow)),
          content: Text(
            _p(
              'الزبون: ${cust.name}\n'
                  'المجموع قبل الخصم: ${subtotal.toStringAsFixed(0)} $_cur\n'
                  '${remise > 0 ? "الخصم (Remise): ${remise.toStringAsFixed(0)} $_cur\n" : ""}'
                  'الصافي: ${netTotal.toStringAsFixed(0)} $_cur\n'
                  'المبلغ المدفوع: ${paid.toStringAsFixed(0)} $_cur\n'
                  'الباقي كريدي: ${remaining.toStringAsFixed(0)} $_cur\n\n'
                  'هل تود إرسال تفاصيل البون إلى واتساب الزبون الآن؟',
              'Client : ${cust.name}\n'
                  'Sous-total : ${subtotal.toStringAsFixed(0)} $_cur\n'
                  '${remise > 0 ? "Remise : ${remise.toStringAsFixed(0)} $_cur\n" : ""}'
                  'Net à payer : ${netTotal.toStringAsFixed(0)} $_cur\n'
                  'Versement : ${paid.toStringAsFixed(0)} $_cur\n'
                  'Reste à payer : ${remaining.toStringAsFixed(0)} $_cur\n\n'
                  'Voulez-vous envoyer ce bon sur le WhatsApp du client maintenant ?',
              'Customer: ${cust.name}\n'
                  'Subtotal: ${subtotal.toStringAsFixed(0)} $_cur\n'
                  '${remise > 0 ? "Discount (Remise): ${remise.toStringAsFixed(0)} $_cur\n" : ""}'
                  'Net Total: ${netTotal.toStringAsFixed(0)} $_cur\n'
                  'Paid Amount: ${paid.toStringAsFixed(0)} $_cur\n'
                  'Remaining Debt: ${remaining.toStringAsFixed(0)} $_cur\n\n'
                  'Would you like to send the receipt details to the customer\'s WhatsApp now?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tx('لاحقاً'),
                  style: const TextStyle(color: Colors.white70)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kEmeraldBright,
                foregroundColor: kNavyDeep,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                final msg = _p(
                  '🧾 *بون تسليم — $_companyName*\n'
                      '📍 $_companyWilaya | هـ: $_companyPhone\n'
                      'الزبون: ${cust.name}\n'
                      'التاريخ: $dateStr\n'
                      '----------------\n'
                      '${lines.join('\n')}\n'
                      '----------------\n'
                      '${remise > 0 ? "المجموع: ${subtotal.toStringAsFixed(0)} $_cur\nالخصم (Remise): -${remise.toStringAsFixed(0)} $_cur\n" : ""}'
                      '*الصافي المطلوب:* ${netTotal.toStringAsFixed(0)} $_cur\n'
                      '*المبلغ المدفوع:* ${paid.toStringAsFixed(0)} $_cur\n'
                      '*الباقي كريدي في الحساب:* ${cust.totalDebt.toStringAsFixed(0)} $_cur\n'
                      'شكراً لتعاملكم معنا!',
                  '🧾 *Bon de Livraison — $_companyName*\n'
                      '📍 $_companyWilaya | Tél: $_companyPhone\n'
                      'Client : ${cust.name}\n'
                      'Date : $dateStr\n'
                      '----------------\n'
                      '${lines.join('\n')}\n'
                      '----------------\n'
                      '${remise > 0 ? "Sous-total : ${subtotal.toStringAsFixed(0)} $_cur\nRemise : -${remise.toStringAsFixed(0)} $_cur\n" : ""}'
                      '*Net à payer :* ${netTotal.toStringAsFixed(0)} $_cur\n'
                      '*Versement :* ${paid.toStringAsFixed(0)} $_cur\n'
                      '*Reste à payer (Crédit) :* ${cust.totalDebt.toStringAsFixed(0)} $_cur\n'
                      'Merci pour votre confiance !',
                  '🧾 *Delivery Receipt — $_companyName*\n'
                      '📍 $_companyWilaya | Tel: $_companyPhone\n'
                      'Customer: ${cust.name}\n'
                      'Date: $dateStr\n'
                      '----------------\n'
                      '${lines.join('\n')}\n'
                      '----------------\n'
                      '${remise > 0 ? "Subtotal: ${subtotal.toStringAsFixed(0)} $_cur\nDiscount (Remise): -${remise.toStringAsFixed(0)} $_cur\n" : ""}'
                      '*Net Total:* ${netTotal.toStringAsFixed(0)} $_cur\n'
                      '*Paid Amount:* ${paid.toStringAsFixed(0)} $_cur\n'
                      '*Remaining Debt:* ${cust.totalDebt.toStringAsFixed(0)} $_cur\n'
                      'Thank you for your business!',
                );
                _sendWhatsApp(cust.phone, msg);
              },
              icon: const Icon(Icons.send),
              label: Text(tx('إرسال عبر واتساب'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 3: Inventory + Stock Financial Valuation + Auto Margin Calculator
  // -------------------------------------------------------------------------
  Widget _buildInventoryTab() {
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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Glassmorphic Stock Financial Valuation Banner
          _glassContainer(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            padding: const EdgeInsets.all(12),
            borderColor: kCyanGlow,
            borderOpacity: 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assessment_outlined,
                        color: kOrangeGold, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      tx('التقييم المالي للمخزون الحالي (Stock Valuation)'),
                      style: const TextStyle(
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
                        label: tx('رأس المال (شراء)'),
                        value: '${totalCapitalBuy.toStringAsFixed(0)} $_cur',
                        valueColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _stockValuationPill(
                        label: tx('القيمة (بسعر الجملة)'),
                        value: '${totalValueWholesale.toStringAsFixed(0)} $_cur',
                        valueColor: kCyanGlow,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _stockValuationPill(
                        label: tx('الربح الكامن (جملة)'),
                        value:
                            '+${latentWholesaleProfit.toStringAsFixed(0)} $_cur',
                        subLabel:
                            '${tx("تجزئة")}: +${latentRetailProfit.toStringAsFixed(0)}',
                        valueColor: kOrangeGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _products.length,
              itemBuilder: (ctx, i) {
                final p = _products[i];
                final isLow = p.stock <= p.minAlert;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _buildProductThumbnail(p, size: 52),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kCyanGlow.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kCyanGlow.withValues(alpha: 0.45)),
                          ),
                          child: Text(
                            _cat(p.category),
                            style: const TextStyle(
                              fontSize: 11,
                              color: kCyanGlow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${tx("المتوفر")}: ${p.stock} | ${tx("شراء")}: ${p.buyPrice.toStringAsFixed(0)} | ${tx("سعر الجملة")}: ${p.wholesalePrice.toStringAsFixed(0)} | ${tx("سعر التجزئة")}: ${p.retailPrice.toStringAsFixed(0)} $_cur',
                        style: TextStyle(
                          color: isLow ? kOrangeGold : Colors.white70,
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
                              color: kCyanGlow),
                          tooltip: tx('تعديل السلعة أو صورتها'),
                          onPressed: () => _showProductDialog(existing: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_box_rounded,
                              color: kOrangeGold),
                          tooltip: tx('إضافة كمية للمخزون (+10)'),
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
        backgroundColor: kOrangeGold,
        foregroundColor: kNavyDeep,
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text(tx('سلعة جديدة'),
            style: const TextStyle(fontWeight: FontWeight.w900)),
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
        color: kNavyDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: valueColor.withValues(alpha: 0.3)),
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
                fontWeight: FontWeight.w900,
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
            textDirection: _textDir,
            child: AlertDialog(
              title: Text(
                existing == null
                    ? tx('إضافة سلعة جديدة للمخزون')
                    : tx('تعديل بيانات وصورة السلعة'),
                style: const TextStyle(color: kCyanGlow, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kNavyDeep.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: kCyanGlow.withValues(alpha: 0.4)),
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
                                    backgroundColor: Colors.redAccent,
                                    child: Icon(Icons.delete_outline,
                                        size: 16, color: Colors.white),
                                  ),
                                  onPressed: () => setDialogState(
                                      () => pickedImagePath = null),
                                ),
                              ],
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      size: 36, color: kOrangeGold),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx('التقط صورة السلعة أو اخترها من المعرض'),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70),
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
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kCyanGlow,
                                    side: const BorderSide(color: kCyanGlow),
                                  ),
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
                                  label: Text(tx('الكاميرا'),
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kOrangeGold,
                                    side: const BorderSide(color: kOrangeGold),
                                  ),
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
                                  label: Text(tx('المعرض'),
                                      style: const TextStyle(fontSize: 12)),
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
                          InputDecoration(labelText: tx('اسم السلعة')),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: kNavyMid,
                      decoration: InputDecoration(
                        labelText: tx('التصنيف (Category)'),
                      ),
                      items: kDefaultCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(_cat(cat)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
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
                      decoration: InputDecoration(
                        labelText: tx('سعر الشراء (د.ج)'),
                        helperText:
                            tx('يقترح تلقائياً: جملة (+15%) وتجزئة (+30%)'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          backgroundColor: kNavyDeep,
                          side: const BorderSide(color: kOrangeGold),
                          avatar: const Icon(Icons.auto_fix_high,
                              size: 15, color: kOrangeGold),
                          label: Text(tx('اقتراح +15% جملة / +30% تجزئة'),
                              style:
                                  const TextStyle(fontSize: 11, color: Colors.white)),
                          onPressed: () =>
                              applyMarginSuggestion(15, 30, setDialogState),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: grosCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        autoCalcEnabled = false;
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: tx('سعر البيع بالجملة (د.ج)'),
                        suffixText: buyVal > 0 && grosVal > 0
                            ? '${tx("ربح")}: ${(grosVal - buyVal).toStringAsFixed(0)} $_cur (${(((grosVal - buyVal) / buyVal) * 100).toStringAsFixed(0)}%)'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        autoCalcEnabled = false;
                        setDialogState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: tx('سعر البيع بالتجزئة (د.ج)'),
                        suffixText: buyVal > 0 && detailVal > 0
                            ? '${tx("ربح")}: ${(detailVal - buyVal).toStringAsFixed(0)} $_cur (${(((detailVal - buyVal) / buyVal) * 100).toStringAsFixed(0)}%)'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: tx('الكمية المتوفرة في المخزن')),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(tx('إلغاء'),
                      style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrangeGold,
                    foregroundColor: kNavyDeep,
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
                  child: Text(tx('حفظ السلعة'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 4: Visual Catalog Generator (Glassmorphic Grid + PDF + WhatsApp)
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
        _glassContainer(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          padding: const EdgeInsets.all(10),
          borderRadius: 16,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCyanGlow,
                        foregroundColor: kNavyDeep,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: _isGeneratingPdf ? null : _previewAndPrintPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 19),
                      label: Text(
                        tx('معاينة وطباعة الكتالوج (PDF)'),
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrangeGold,
                        foregroundColor: kNavyDeep,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed:
                          _isGeneratingPdf ? null : _shareCatalogToWhatsApp,
                      icon: const Icon(Icons.share_rounded, size: 19),
                      label: Text(
                        tx('إرسال الكتالوج للزبائن عبر واتساب'),
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showStoreSettingsDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kNavyDeep.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: kOrangeGold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_rounded,
                          size: 18, color: kOrangeGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_companyName | $_companyWilaya | هـ: $_companyPhone',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit_note_rounded,
                          size: 20, color: kCyanGlow),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(tx('أسعار الجملة (Gros)'),
                              style: const TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(tx('أسعار التجزئة (Détail)'),
                              style: const TextStyle(fontSize: 11)),
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
                    label: Text(tx('إخفاء النافد'),
                        style: const TextStyle(fontSize: 11)),
                    selectedColor: kOrangeGold.withValues(alpha: 0.3),
                    checkmarkColor: kOrangeGold,
                    onSelected: (v) {
                      setState(() => _catalogHideOutOfStock = v);
                      _saveData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                      label: Text(_cat(cat), style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      selectedColor: kCyanGlow,
                      backgroundColor: kNavyDeep,
                      labelStyle: TextStyle(
                        color: selected ? kNavyDeep : Colors.white70,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.normal,
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
            color: kOrangeGold,
            backgroundColor: kNavyMid,
          ),

        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tx('لا توجد سلع مطابقة للفلتر الحالي في الكتالوج.'),
                      style: const TextStyle(fontSize: 15, color: Colors.white60),
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

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kNavySurface.withValues(alpha: 0.9),
                            kNavyDeep.withValues(alpha: 0.95),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kCyanGlow.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kCyanGlow.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                      color: kNavyDeep.withValues(alpha: 0.5),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_a_photo_outlined,
                                              size: 36, color: kCyanGlow),
                                          const SizedBox(height: 4),
                                          Text(
                                            tx('اضغط لإضافة صورة'),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: kCyanGlow,
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
                                        color:
                                            kNavyDeep.withValues(alpha: 0.88),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: kCyanGlow, width: 0.8),
                                      ),
                                      child: Text(
                                        _cat(p.category),
                                        style: const TextStyle(
                                          color: kCyanGlow,
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
                                        inStock
                                            ? '${tx("متوفر")} (${p.stock})'
                                            : tx('نافد'),
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
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [kNavyDeep, kNavyMid],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: kOrangeGold, width: 1.1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _catalogWholesaleMode
                                            ? tx('سعر الجملة')
                                            : tx('سعر التجزئة'),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '${price.toStringAsFixed(0)} $_cur',
                                        style: const TextStyle(
                                          color: kOrangeGold,
                                          fontWeight: FontWeight.w900,
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
        ? tx('كتالوج أسعار الجملة (Gros)')
        : tx('كتالوج أسعار التجزئة (Détail)');

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
        textDirection: (_lang == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr),
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
                      _p(
                        'الولاية: $_companyWilaya  |  الهاتف: $_companyPhone',
                        'Wilaya : $_companyWilaya  |  Tél : $_companyPhone',
                        'Region: $_companyWilaya  |  Tel: $_companyPhone',
                      ),
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
                      '${tx("التاريخ:")} $dateStr',
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
                _p(
                  '$_companyName — للطلب والاستفسار: $_companyPhone',
                  '$_companyName — Commandes & Infos : $_companyPhone',
                  '$_companyName — Orders & Inquiries: $_companyPhone',
                ),
                style: const pw.TextStyle(fontSize: 9, color: greenPrimary),
              ),
              pw.Text(
                _p(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  'Page ${context.pageNumber} sur ${context.pagesCount}',
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                ),
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
                                      _cat(p.category),
                                      style: pw.TextStyle(
                                        font: boldFont,
                                        color: greenPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    pw.Text(
                                      tx('متوفر في المخزن'),
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
                                  _cat(p.category),
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: greenPrimary,
                                  ),
                                ),
                                pw.Text(
                                  p.stock > 0 ? tx('متوفر') : tx('نافد'),
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
                                    tx('السعر:'),
                                    style: const pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    '${price.toStringAsFixed(0)} $_cur',
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
            backgroundColor: Colors.redAccent,
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

      final priceTypeLabel = _catalogWholesaleMode
          ? tx('أسعار الجملة (Gros)')
          : tx('أسعار التجزئة (Détail)');
      final welcomeMsg = _p(
        'السلام عليكم ورحمة الله وبركاته 🌟\n'
            'يسر *$_companyName* ($_companyWilaya) أن يضع بين أيديكم الكتالوج المصور الجديد للسلع المتوفرة ($priceTypeLabel) بصيغة PDF 📘.\n'
            'للطلب أو الاستفسار يرجى التواصل معنا على الرقم: $_companyPhone\n'
            'مرحباً بكم ودمتم أوفياء لنا!',
        'Bonjour 🌟\n'
            '*$_companyName* ($_companyWilaya) a le plaisir de partager avec vous notre nouveau catalogue produits illustré ($priceTypeLabel) au format PDF 📘.\n'
            'Pour toute commande ou information, contactez-nous au : $_companyPhone\n'
            'Merci pour votre fidélité !',
        'Hello 🌟\n'
            '*$_companyName* ($_companyWilaya) is pleased to share our new illustrated product catalog ($priceTypeLabel) in PDF format 📘.\n'
            'For orders or inquiries, please contact us at: $_companyPhone\n'
            'Thank you for your business!',
      );

      await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        text: welcomeMsg,
        subject: _p(
          'كتالوج السلع — $_companyName',
          'Catalogue Produits — $_companyName',
          'Product Catalog — $_companyName',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر مشاركة ملف الكتالوج: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // -------------------------------------------------------------------------
  // TAB 5: Customers + Dual Debt Reminder (SMS + WhatsApp)
  //        + Detailed Customer Ledger Bottom Sheet & Due Date
  // -------------------------------------------------------------------------
  Widget _buildCustomersTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _glassContainer(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 12,
            borderColor: kCyanGlow,
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, size: 18, color: kOrangeGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tx('اضغط على أي زبون لفتح «كراس الحساب التفصيلي» وتحديد موعد التسديد (Due Date).'),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
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
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _showCustomerLedgerSheet(c),
                    leading: CircleAvatar(
                      backgroundColor: hasDebt
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : kEmeraldBright.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person_rounded,
                        color: hasDebt ? Colors.redAccent : kEmeraldBright,
                      ),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tx("الباقي كريدي")}: ${c.totalDebt.toStringAsFixed(0)} $_cur',
                          style: TextStyle(
                            color: hasDebt ? kOrangeGold : Colors.white70,
                            fontWeight:
                                hasDebt ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (c.dueDate != null && c.dueDate!.isNotEmpty)
                          Text(
                            '📅 ${tx("موعد التسديد المتفق عليه")}: ${c.dueDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kCyanGlow,
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
                            tooltip: tx('تسجيل دفعة (Versement)'),
                            icon: const Icon(Icons.payments_outlined,
                                color: kEmeraldBright),
                            onPressed: () => _showPayDebtDialog(c),
                          ),
                        if (hasDebt && c.phone.isNotEmpty)
                          IconButton(
                            tooltip: tx('تذكير مجاني عبر رسالة نصية SMS'),
                            icon: const Icon(Icons.sms_outlined,
                                color: kCyanGlow),
                            onPressed: () {
                              final hasDue =
                                  c.dueDate != null && c.dueDate!.isNotEmpty;
                              final smsMsg = _p(
                                'السلام عليكم ${c.name}، تذكير ودي من $_companyName: الرصيد المتبقي في حسابكم هو ${c.totalDebt.toStringAsFixed(0)} $_cur${hasDue ? " (تاريخ الاستحقاق: ${c.dueDate})" : ""}. شكراً لتعاملكم.',
                                'Bonjour ${c.name}, rappel aimable de $_companyName : votre reste à payer est de ${c.totalDebt.toStringAsFixed(0)} $_cur${hasDue ? " (Échéance : ${c.dueDate})" : ""}. Merci de votre confiance.',
                                'Hello ${c.name}, friendly reminder from $_companyName: your remaining balance is ${c.totalDebt.toStringAsFixed(0)} $_cur${hasDue ? " (Due date: ${c.dueDate})" : ""}. Thank you for your business.',
                              );
                              _sendSms(c.phone, smsMsg);
                            },
                          ),
                        if (c.phone.isNotEmpty)
                          IconButton(
                            tooltip: tx('إرسال تذكير عبر واتساب'),
                            icon: const Icon(Icons.chat_outlined,
                                color: kOrangeGold),
                            onPressed: () {
                              final hasDue =
                                  c.dueDate != null && c.dueDate!.isNotEmpty;
                              final msg = _p(
                                'السلام عليكم ورحمة الله (${c.name})،\n'
                                    'تذكير ودي من *$_companyName* ($_companyWilaya):\n'
                                    'الرصيد المتبقي في حسابكم هو *${c.totalDebt.toStringAsFixed(0)} $_cur*.'
                                    '${hasDue ? "\n📅 *موعد التسديد المتفق عليه:* ${c.dueDate}" : ""}\n'
                                    'بارك الله في رزقكم وشكراً لتعاملكم الطيب.',
                                'Bonjour *${c.name}*,\n'
                                    'Rappel aimable de *$_companyName* ($_companyWilaya) :\n'
                                    'Le reste à payer sur votre compte est de *${c.totalDebt.toStringAsFixed(0)} $_cur*.'
                                    '${hasDue ? "\n📅 *Date d'échéance convenue :* ${c.dueDate}" : ""}\n'
                                    'Merci pour votre confiance et votre collaboration.',
                                'Hello *${c.name}*,\n'
                                    'Friendly reminder from *$_companyName* ($_companyWilaya):\n'
                                    'Your remaining account balance is *${c.totalDebt.toStringAsFixed(0)} $_cur*.'
                                    '${hasDue ? "\n📅 *Agreed Due Date:* ${c.dueDate}" : ""}\n'
                                    'Thank you for your valued business.',
                              );
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
        backgroundColor: kCyanGlow,
        foregroundColor: kNavyDeep,
        onPressed: _showAddCustomerDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(tx('زبون جديد'),
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  void _showCustomerLedgerSheet(CustomerItem c) {
    final dueCtrl = TextEditingController(text: c.dueDate ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: kNavyMid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: kCyanGlow, width: 1.4),
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
            textDirection: _textDir,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📒 ${tx("كراس حساب الزبون:")} ${c.name}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: kCyanGlow,
                                ),
                              ),
                              Text(
                                _p(
                                  'الهاتف: ${c.phone.isEmpty ? "غير مسجل" : c.phone} | الباقي كريدي: ${c.totalDebt.toStringAsFixed(0)} $_cur',
                                  'Tél : ${c.phone.isEmpty ? "Non enregistré" : c.phone} | Reste à payer : ${c.totalDebt.toStringAsFixed(0)} $_cur',
                                  'Tel: ${c.phone.isEmpty ? "Not registered" : c.phone} | Remaining Debt: ${c.totalDebt.toStringAsFixed(0)} $_cur',
                                ),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
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
                    const Divider(color: Colors.white24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dueCtrl,
                            decoration: InputDecoration(
                              labelText:
                                  tx('موعد التسديد المتفق عليه (مثال: 2026-11-30)'),
                              prefixIcon: const Icon(Icons.event_available, size: 18),
                              isDense: true,
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
                          tooltip: tx('اختيار تاريخ من التقويم'),
                          icon: const Icon(Icons.calendar_month,
                              color: kOrangeGold),
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
                            backgroundColor: kCyanGlow,
                            foregroundColor: kNavyDeep,
                          ),
                          onPressed: () {
                            setState(() => c.dueDate = dueCtrl.text.trim());
                            setSheetState(() {});
                            _saveData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tx('تم حفظ موعد التسديد ✅')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Text(tx('حفظ الموعد'),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Text(tx('إجمالي ما أخذ'),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white70)),
                                Text(
                                  '${totalTaken.toStringAsFixed(0)} $_cur',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent),
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
                              color: kEmeraldBright.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: kEmeraldBright.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Text(tx('إجمالي ما سدد'),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white70)),
                                Text(
                                  '${totalPaid.toStringAsFixed(0)} $_cur',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kEmeraldBright),
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
                              color: kOrangeGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: kOrangeGold.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Text(tx('الرصيد المتبقي'),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white70)),
                                Text(
                                  '${c.totalDebt.toStringAsFixed(0)} $_cur',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kOrangeGold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tx('سجل حركات الحساب بالتاريخ (السلع المسحوبة والدفعات المسددة):'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: c.ledger.isEmpty
                          ? Center(
                              child: Text(
                                tx('لا توجد حركات تفصيلية مسجلة لهذا الزبون بعد.'),
                                style: const TextStyle(color: Colors.white60),
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
                                          ? Colors.redAccent
                                              .withValues(alpha: 0.2)
                                          : kEmeraldBright
                                              .withValues(alpha: 0.2),
                                      child: Icon(
                                        isDebt
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 16,
                                        color: isDebt
                                            ? Colors.redAccent
                                            : kEmeraldBright,
                                      ),
                                    ),
                                    title: Text(
                                      entry.note,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      '${tx("التاريخ:")} ${entry.dateStr}',
                                      style: const TextStyle(
                                          color: Colors.white60),
                                    ),
                                    trailing: Text(
                                      '${isDebt ? "+" : "-"}${entry.amount.toStringAsFixed(0)} $_cur',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDebt
                                            ? Colors.redAccent
                                            : kEmeraldBright,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kOrangeGold,
                              foregroundColor: kNavyDeep,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () =>
                                _sendFullLedgerStatementWhatsApp(c),
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: Text(
                              tx('إرسال كشف الحساب كاملاً عبر واتساب'),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kCyanGlow,
                            side: const BorderSide(color: kCyanGlow),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showPayDebtDialog(c);
                          },
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: Text(tx('تسديد دفعة'),
                              style: const TextStyle(fontSize: 12)),
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
      final sign = e.type == 'debt' ? tx('🔴 أخذ:') : tx('🟢 سدد:');
      return '$sign ${e.amount.toStringAsFixed(0)} $_cur (${e.dateStr}) — ${e.note}';
    }).join('\n');

    final hasDue = c.dueDate != null && c.dueDate!.isNotEmpty;

    final msg = _p(
      '📒 *كشف حساب تفصيلي — $_companyName*\n'
          '📍 $_companyWilaya | هـ: $_companyPhone\n'
          'الزبون: *${c.name}*\n'
          '----------------\n'
          '${historyLines.isEmpty ? "لا توجد حركات سابقة مسجلة" : historyLines}\n'
          '----------------\n'
          '*الباقي كريدي:* ${c.totalDebt.toStringAsFixed(0)} $_cur'
          '${hasDue ? "\n📅 *موعد التسديد المتفق عليه:* ${c.dueDate}" : ""}\n'
          'شكراً لثقتكم وتعاملكم الطيب معنا!',
      '📒 *Relevé de Compte Détaillé — $_companyName*\n'
          '📍 $_companyWilaya | Tél : $_companyPhone\n'
          'Client : *${c.name}*\n'
          '----------------\n'
          '${historyLines.isEmpty ? "Aucune opération enregistrée" : historyLines}\n'
          '----------------\n'
          '*Reste à payer (Crédit) :* ${c.totalDebt.toStringAsFixed(0)} $_cur'
          '${hasDue ? "\n📅 *Date d'échéance convenue :* ${c.dueDate}" : ""}\n'
          'Merci pour votre confiance !',
      '📒 *Detailed Account Statement — $_companyName*\n'
          '📍 $_companyWilaya | Tel: $_companyPhone\n'
          'Customer: *${c.name}*\n'
          '----------------\n'
          '${historyLines.isEmpty ? "No previous transactions recorded" : historyLines}\n'
          '----------------\n'
          '*Remaining Debt:* ${c.totalDebt.toStringAsFixed(0)} $_cur'
          '${hasDue ? "\n📅 *Agreed Due Date:* ${c.dueDate}" : ""}\n'
          'Thank you for your valued business!',
    );

    _sendWhatsApp(c.phone, msg);
  }

  void _showPayDebtDialog(CustomerItem c) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController(text: tx('تسديد دفعة نقداً (Versement)'));
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _textDir,
        child: AlertDialog(
          title: Text('${tx("تسجيل دفعة (Versement)")} — ${c.name}',
              style: const TextStyle(color: kCyanGlow, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tx("الباقي كريدي")}: ${c.totalDebt.toStringAsFixed(0)} $_cur',
                  style: const TextStyle(color: kOrangeGold)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tx('المبلغ المسدد الآن (د.ج)'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: tx('ملاحظة (اختياري)'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tx('إلغاء'),
                    style: const TextStyle(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kEmeraldBright,
                foregroundColor: kNavyDeep,
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
                          ? tx('تسديد دفعة (Versement)')
                          : noteCtrl.text.trim(),
                    ));
                  });
                  _saveData();
                }
                Navigator.pop(ctx);
              },
              child: Text(tx('تأكيد التسديد'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
        textDirection: _textDir,
        child: AlertDialog(
          title: Text(tx('إضافة زبون جديد'),
              style: const TextStyle(color: kCyanGlow)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration:
                        InputDecoration(labelText: tx('اسم الزبون أو المحل'))),
                const SizedBox(height: 8),
                TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: tx('رقم الهاتف (مثال: 213661...)'))),
                const SizedBox(height: 8),
                TextField(
                    controller: debtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: tx('رصيد الكريدي السابق (إن وجد)'))),
                const SizedBox(height: 8),
                TextField(
                    controller: dueCtrl,
                    decoration: InputDecoration(
                        labelText:
                            tx('موعد التسديد المتفق عليه (اختياري، مثال: 2026-11-30)'))),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tx('إلغاء'),
                    style: const TextStyle(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kCyanGlow,
                foregroundColor: kNavyDeep,
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
                    note: tx('رصيد كريدي افتتاحي سابق'),
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
              child: Text(tx('حفظ الزبون'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
