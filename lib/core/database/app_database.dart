import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async => _db ??= await _open();
  Future<String> getDbPath() async => p.join(await getDatabasesPath(), AppConstants.dbName);

  Future<Database> _open() async => openDatabase(
        await getDbPath(),
        version: AppConstants.dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
      );

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE properties (id TEXT PRIMARY KEY, name TEXT, code TEXT, type TEXT, address TEXT, description TEXT, status TEXT)');
    await db.execute('CREATE TABLE units (id TEXT PRIMARY KEY, property_id TEXT, code TEXT, type TEXT, floor TEXT, area TEXT, rooms INTEGER, baths INTEGER, elec_meter TEXT, water_meter TEXT, features_json TEXT, status TEXT, UNIQUE(property_id, code), FOREIGN KEY(property_id) REFERENCES properties(id))');
    await db.execute('CREATE TABLE unit_status_history (id INTEGER PRIMARY KEY AUTOINCREMENT, unit_id TEXT, changed_at TEXT, from_status TEXT, to_status TEXT, reason TEXT, FOREIGN KEY(unit_id) REFERENCES units(id))');
    await db.execute('CREATE TABLE tenants (id TEXT PRIMARY KEY, name TEXT, type TEXT, phone TEXT, alt_phone TEXT, id_num TEXT, address TEXT, email TEXT, notes TEXT, status TEXT)');
    await db.execute('CREATE TABLE contract_templates (id TEXT PRIMARY KEY, name TEXT, terms_json TEXT)');
    await db.execute('CREATE TABLE contracts (id TEXT PRIMARY KEY, unit_id TEXT, tenant_id TEXT, created_date TEXT, start_date TEXT, end_date TEXT, rent REAL, currency TEXT, frequency TEXT, custom_interval TEXT, deposit REAL, grace_days INTEGER, status TEXT, prev_contract_id TEXT, increase_pct REAL DEFAULT 0, witnesses_json TEXT, terms_json TEXT, FOREIGN KEY(unit_id) REFERENCES units(id), FOREIGN KEY(tenant_id) REFERENCES tenants(id))');
    await db.execute('CREATE TABLE services (id TEXT PRIMARY KEY, unit_id TEXT, name TEXT, billing_type TEXT, unit_label TEXT, unit_rate REAL, fixed_amount REAL, currency TEXT, prev_reading REAL, FOREIGN KEY(unit_id) REFERENCES units(id))');
    await db.execute('CREATE TABLE dues (id TEXT PRIMARY KEY, contract_id TEXT, tenant_id TEXT, unit_id TEXT, due_type TEXT, period_label TEXT, due_date TEXT, amount REAL, paid REAL DEFAULT 0, currency TEXT, UNIQUE(contract_id, due_type, period_label), FOREIGN KEY(contract_id) REFERENCES contracts(id))');
    await db.execute('CREATE TABLE financial_accounts (id TEXT PRIMARY KEY, name TEXT, type TEXT, provider TEXT, account_ref TEXT, currency TEXT, opening_balance REAL, status TEXT)');
    await db.execute('CREATE TABLE payments (id TEXT PRIMARY KEY, tenant_id TEXT, payment_date TEXT, amount REAL, currency TEXT, method TEXT, account_id TEXT, ref_number TEXT, notes TEXT, reversed INTEGER DEFAULT 0, FOREIGN KEY(tenant_id) REFERENCES tenants(id), FOREIGN KEY(account_id) REFERENCES financial_accounts(id))');
    await db.execute('CREATE TABLE payment_allocations (id INTEGER PRIMARY KEY AUTOINCREMENT, payment_id TEXT, due_id TEXT, amount REAL, mode TEXT, FOREIGN KEY(payment_id) REFERENCES payments(id), FOREIGN KEY(due_id) REFERENCES dues(id))');
    await db.execute('CREATE TABLE expenses (id TEXT PRIMARY KEY, expense_date TEXT, category TEXT, amount REAL, currency TEXT, account_id TEXT, target_label TEXT, bearer TEXT, notes TEXT, FOREIGN KEY(account_id) REFERENCES financial_accounts(id))');
    await db.execute('CREATE TABLE settlements (id INTEGER PRIMARY KEY AUTOINCREMENT, contract_id TEXT, settlement_type TEXT, amount REAL, currency TEXT, settlement_date TEXT, notes TEXT, FOREIGN KEY(contract_id) REFERENCES contracts(id))');
    await db.execute('CREATE TABLE audit_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TEXT, message TEXT)');
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    await db.insert('properties', {'id': 'P1', 'name': 'برج النخبة السكني', 'code': 'ARK-01', 'type': 'سكني', 'address': 'صنعاء - حي حدة', 'description': 'برج سكني بمصعد ومواقف', 'status': 'نشط'});
    await db.insert('properties', {'id': 'P2', 'name': 'مجمع الياسمين التجاري', 'code': 'ARK-02', 'type': 'تجاري', 'address': 'عدن - المنصورة', 'description': 'محلات ومكاتب', 'status': 'نشط'});
    await db.insert('units', {'id': 'U1', 'property_id': 'P1', 'code': 'A-101', 'type': 'شقة', 'floor': 'الأول', 'area': '145 م²', 'rooms': 3, 'baths': 2, 'elec_meter': 'EL-88412', 'water_meter': 'WT-3310', 'features_json': '["مطبخ راكب","3 مكيفات","موقف خاص"]', 'status': 'Rented'});
    await db.insert('units', {'id': 'U2', 'property_id': 'P1', 'code': 'A-102', 'type': 'شقة', 'floor': 'الأول', 'area': '120 م²', 'rooms': 2, 'baths': 2, 'elec_meter': 'EL-88413', 'water_meter': 'WT-3311', 'features_json': '["تكييف مركزي","شرفة"]', 'status': 'Available'});
    await db.insert('units', {'id': 'U3', 'property_id': 'P2', 'code': 'S-01', 'type': 'محل', 'floor': 'الأرضي', 'area': '65 م²', 'rooms': 1, 'baths': 1, 'elec_meter': 'EL-99201', 'water_meter': 'WT-4402', 'features_json': '["واجهة سيكوريت","عداد تجاري"]', 'status': 'Rented'});
    await db.insert('unit_status_history', {'unit_id': 'U1', 'changed_at': '2026-08-20', 'from_status': 'Available', 'to_status': 'Rented', 'reason': 'اعتماد عقد C-2026-01'});
    await db.insert('tenants', {'id': 'T1', 'name': 'محمد علي الحميري', 'type': 'فرد', 'phone': '967777123456', 'alt_phone': '967733112233', 'id_num': '01010458921', 'address': 'صنعاء - حدة', 'email': 'm@mail.com', 'notes': 'ملتزم بالسداد', 'status': 'نشط'});
    await db.insert('tenants', {'id': 'T2', 'name': 'مؤسسة الأفق للتجارة', 'type': 'مؤسسة', 'phone': '967733987654', 'alt_phone': '02345678', 'id_num': 'س.ت 44910', 'address': 'عدن - المنصورة', 'email': 'f@alofoq.ye', 'notes': 'حوالات الكريمي', 'status': 'نشط'});
    await db.insert('contract_templates', {'id': 'TMP1', 'name': 'قالب عقد سكني قياسي', 'terms_json': '["يلتزم المستأجر بسداد الإيجار في موعده دون تأخير.","يلتزم بالمحافظة على الوحدة وعدم التعديل دون موافقة.","يمنع التأجير من الباطن."]'});
    await db.insert('contract_templates', {'id': 'TMP2', 'name': 'قالب عقد تجاري', 'terms_json': '["تستخدم الوحدة للنشاط التجاري المصرح به.","يتحمل المستأجر التراخيص وفواتير الخدمات."]'});
    await db.insert('contracts', {'id': 'C-2026-01', 'unit_id': 'U1', 'tenant_id': 'T1', 'created_date': '2026-08-20', 'start_date': '2026-09-01', 'end_date': '2027-08-31', 'rent': 120000.0, 'currency': 'YER', 'frequency': 'Monthly', 'custom_interval': '', 'deposit': 120000.0, 'grace_days': 5, 'status': 'Active', 'prev_contract_id': null, 'increase_pct': 0.0, 'witnesses_json': '[{"name":"أحمد صالح القباطي","detail":"شاهد أول"},{"name":"خالد يحيى الشرعبي","detail":"شاهد ثاني"}]', 'terms_json': '["يلتزم المستأجر بسداد الإيجار في موعده دون تأخير.","يلتزم بالمحافظة على الوحدة."]'});
    await db.insert('contracts', {'id': 'C-2026-02', 'unit_id': 'U3', 'tenant_id': 'T2', 'created_date': '2026-06-25', 'start_date': '2026-07-01', 'end_date': '2027-06-30', 'rent': 2500.0, 'currency': 'SAR', 'frequency': 'Monthly', 'custom_interval': '', 'deposit': 5000.0, 'grace_days': 3, 'status': 'Active', 'prev_contract_id': null, 'increase_pct': 0.0, 'witnesses_json': '[{"name":"ناجي سعيد المفلحي","detail":"شاهد أول"}]', 'terms_json': '["تستخدم الوحدة للنشاط التجاري المصرح به."]'});
    await db.insert('services', {'id': 'SV1', 'unit_id': 'U1', 'name': 'كهرباء خاصة', 'billing_type': 'Usage-Based', 'unit_label': 'ك.و.س', 'unit_rate': 280.0, 'fixed_amount': 0.0, 'currency': 'YER', 'prev_reading': 1420.0});
    await db.insert('services', {'id': 'SV2', 'unit_id': 'U1', 'name': 'نظافة وحراسة', 'billing_type': 'Fixed', 'unit_label': 'شهري', 'unit_rate': 0.0, 'fixed_amount': 10000.0, 'currency': 'YER', 'prev_reading': 0.0});
    await db.insert('dues', {'id': 'D-101', 'contract_id': 'C-2026-01', 'tenant_id': 'T1', 'unit_id': 'U1', 'due_type': 'إيجار', 'period_label': 'سبتمبر 2026', 'due_date': '2026-09-01', 'amount': 120000.0, 'paid': 120000.0, 'currency': 'YER'});
    await db.insert('dues', {'id': 'D-102', 'contract_id': 'C-2026-01', 'tenant_id': 'T1', 'unit_id': 'U1', 'due_type': 'إيجار', 'period_label': 'أكتوبر 2026', 'due_date': '2026-10-01', 'amount': 120000.0, 'paid': 70000.0, 'currency': 'YER'});
    await db.insert('dues', {'id': 'D-103', 'contract_id': 'C-2026-01', 'tenant_id': 'T1', 'unit_id': 'U1', 'due_type': 'إيجار', 'period_label': 'نوفمبر 2026', 'due_date': '2026-11-01', 'amount': 120000.0, 'paid': 0.0, 'currency': 'YER'});
    await db.insert('dues', {'id': 'D-201', 'contract_id': 'C-2026-02', 'tenant_id': 'T2', 'unit_id': 'U3', 'due_type': 'إيجار', 'period_label': 'نوفمبر 2026', 'due_date': '2026-11-01', 'amount': 2500.0, 'paid': 0.0, 'currency': 'SAR'});
    await db.insert('financial_accounts', {'id': 'FA1', 'name': 'الصندوق الرئيسي (YER)', 'type': 'Cash', 'provider': 'خزنة المكتب', 'account_ref': 'BOX-01', 'currency': 'YER', 'opening_balance': 100000.0, 'status': 'نشط'});
    await db.insert('financial_accounts', {'id': 'FA2', 'name': 'محفظة جوالي', 'type': 'E-Wallet', 'provider': 'جوالي', 'account_ref': '777•••456', 'currency': 'YER', 'opening_balance': 0.0, 'status': 'نشط'});
    await db.insert('financial_accounts', {'id': 'FA3', 'name': 'حساب الكريمي (SAR)', 'type': 'Bank', 'provider': 'بنك الكريمي', 'account_ref': '•••• 4821', 'currency': 'SAR', 'opening_balance': 1000.0, 'status': 'نشط'});
    await db.insert('financial_accounts', {'id': 'FA4', 'name': 'صندوق الدولار (USD)', 'type': 'Cash', 'provider': 'خزنة المكتب', 'account_ref': 'BOX-USD', 'currency': 'USD', 'opening_balance': 500.0, 'status': 'نشط'});
    await db.insert('payments', {'id': 'PAY-01', 'tenant_id': 'T1', 'payment_date': '2026-09-01', 'amount': 120000.0, 'currency': 'YER', 'method': 'نقداً', 'account_id': 'FA1', 'ref_number': '-', 'notes': 'إيجار سبتمبر', 'reversed': 0});
    await db.insert('payment_allocations', {'payment_id': 'PAY-01', 'due_id': 'D-101', 'amount': 120000.0, 'mode': 'auto'});
    await db.insert('payments', {'id': 'PAY-02', 'tenant_id': 'T1', 'payment_date': '2026-10-08', 'amount': 70000.0, 'currency': 'YER', 'method': 'محفظة إلكترونية', 'account_id': 'FA2', 'ref_number': 'JW-99812', 'notes': 'دفعة جزئية', 'reversed': 0});
    await db.insert('payment_allocations', {'payment_id': 'PAY-02', 'due_id': 'D-102', 'amount': 70000.0, 'mode': 'auto'});
    await db.insert('expenses', {'id': 'EX-01', 'expense_date': '2026-10-12', 'category': 'صيانة مصعد', 'amount': 35000.0, 'currency': 'YER', 'account_id': 'FA1', 'target_label': 'برج النخبة السكني', 'bearer': 'المالك', 'notes': 'صيانة دورية'});
    await db.insert('audit_logs', {'created_at': AppFormatters.nowTs(), 'message': 'تهيئة قاعدة بيانات ركن العقار المحلية بنجاح'});
  }

  Future<void> restoreDatabase(String sourceFilePath) async {
    final dbPath = await getDbPath();
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('الملف المحدد غير موجود', sourceFilePath);
    }
    final targetFile = File(dbPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await sourceFile.copy(dbPath);
    _db = await _open();
    final db = await database;
    await addAudit(db, 'استعادة قاعدة البيانات بنجاح من: ${p.basename(sourceFilePath)}');
  }

  Future<void> addAudit(DatabaseExecutor ex, String msg) =>
      ex.insert('audit_logs', {'created_at': AppFormatters.nowTs(), 'message': msg});
}