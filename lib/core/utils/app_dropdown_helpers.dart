import 'package:get/get.dart';

/// Helper to build locale-safe DropdownMenuItems.
/// Values stored in DB are language-neutral keys (English).
/// Display text is translated via GetX .tr
abstract final class AppDropdownHelpers {
  // ─── Property Type ───────────────────────────────────────────────
  /// Canonical DB keys for property types
  static const propTypeKeys = ['Residential', 'Commercial', 'Mixed'];

  /// Translation map for property types (key → i18n key)
  static const _propTypeI18n = {
    'Residential': 'residential',
    'Commercial': 'commercial',
    'Mixed': 'mixed',
  };

  /// Map stored Arabic/legacy values to canonical key
  static const _propTypeLegacy = {
    'سكني': 'Residential',
    'تجاري': 'Commercial',
    'مختلط': 'Mixed',
  };

  static String propTypeLabel(String key) =>
      (_propTypeI18n[key] ?? 'residential').tr;

  /// Normalize a stored value (Arabic or English) to canonical key
  static String normalizePropType(String stored) =>
      _propTypeLegacy[stored] ?? stored;

  // ─── Unit Type ────────────────────────────────────────────────────
  static const unitTypeKeys = ['Apartment', 'Shop', 'Office', 'Warehouse'];

  static const _unitTypeI18n = {
    'Apartment': 'unit_type_apt',
    'Shop': 'unit_type_shop',
    'Office': 'unit_type_office',
    'Warehouse': 'unit_type_warehouse',
  };

  static const _unitTypeLegacy = {
    'شقة': 'Apartment',
    'محل': 'Shop',
    'مكتب': 'Office',
    'مخزن': 'Warehouse',
  };

  static String unitTypeLabel(String key) =>
      (_unitTypeI18n[key] ?? 'unit_type_apt').tr;

  static String normalizeUnitType(String stored) =>
      _unitTypeLegacy[stored] ?? stored;

  // ─── Tenant Type ──────────────────────────────────────────────────
  static const tenantTypeKeys = ['Individual', 'Family', 'Organization'];

  static const _tenantTypeI18n = {
    'Individual': 'tenant_individual',
    'Family': 'tenant_family',
    'Organization': 'tenant_org',
  };

  static const _tenantTypeLegacy = {
    'فرد': 'Individual',
    'عائلة': 'Family',
    'مؤسسة': 'Organization',
  };

  static String tenantTypeLabel(String key) =>
      (_tenantTypeI18n[key] ?? 'tenant_individual').tr;

  static String normalizeTenantType(String stored) =>
      _tenantTypeLegacy[stored] ?? stored;

  // ─── Payment Method ───────────────────────────────────────────────
  static const paymentMethodKeys = ['Cash', 'Transfer', 'E-Wallet', 'Cheque'];

  static const _paymentMethodI18n = {
    'Cash': 'method_cash',
    'Transfer': 'method_transfer',
    'E-Wallet': 'method_wallet',
    'Cheque': 'method_cheque',
  };

  static const _paymentMethodLegacy = {
    'نقداً': 'Cash',
    'حوالة': 'Transfer',
    'محفظة إلكترونية': 'E-Wallet',
    'شيك': 'Cheque',
    // also allow already-translated English
    'Cash': 'Cash',
    'Transfer': 'Transfer',
    'E-Wallet': 'E-Wallet',
    'Cheque': 'Cheque',
  };

  static String paymentMethodLabel(String key) =>
      (_paymentMethodI18n[key] ?? 'method_cash').tr;

  static String normalizePaymentMethod(String stored) =>
      _paymentMethodLegacy[stored] ?? stored;

  // ─── Expense Bearer ────────────────────────────────────────────────
  static const bearerKeys = ['Owner', 'Management'];

  static const _bearerI18n = {
    'Owner': 'bearer_owner',
    'Management': 'bearer_mgmt',
  };

  static const _bearerLegacy = {
    'المالك': 'Owner',
    'الإدارة': 'Management',
    'Owner': 'Owner',
    'Management': 'Management',
  };

  static String bearerLabel(String key) =>
      (_bearerI18n[key] ?? 'bearer_owner').tr;

  static String normalizeBearer(String stored) =>
      _bearerLegacy[stored] ?? stored;

  // ─── Contract Frequency ───────────────────────────────────────────
  static const frequencyKeys = ['Monthly', 'Quarterly', 'Semi-Annual', 'Annual'];

  static const _frequencyI18n = {
    'Monthly': 'freq_monthly',
    'Quarterly': 'freq_quarterly',
    'Semi-Annual': 'freq_semi_annual',
    'Annual': 'freq_annual',
  };

  static const _frequencyLegacy = {
    'شهري': 'Monthly',
    'ربع سنوي': 'Quarterly',
    'نصف سنوي': 'Semi-Annual',
    'سنوي': 'Annual',
    'Monthly': 'Monthly',
    'Quarterly': 'Quarterly',
    'Semi-Annual': 'Semi-Annual',
    'Annual': 'Annual',
  };

  static String frequencyLabel(String key) =>
      (_frequencyI18n[key] ?? 'freq_monthly').tr;

  static String normalizeFrequency(String stored) =>
      _frequencyLegacy[stored] ?? stored;

  // ─── Unit Status ──────────────────────────────────────────────────
  static const unitStatusKeys = [
    'Available',
    'Rented',
    'Pending',
    'Blocked',
    'Maintenance',
  ];

  static const _unitStatusI18n = {
    'Available': 'unit_status_available',
    'Rented': 'unit_status_rented',
    'Pending': 'unit_status_pending',
    'Blocked': 'unit_status_blocked',
    'Maintenance': 'unit_status_maintenance',
  };

  static const _unitStatusLegacy = {
    'متاح': 'Available',
    'شاغر': 'Available',
    'مؤجر': 'Rented',
    'معلق': 'Pending',
    'قيد الحجز': 'Pending',
    'محظور': 'Blocked',
    'تحت الصيانة': 'Maintenance',
    'صيانة': 'Maintenance',
    'Available': 'Available',
    'Rented': 'Rented',
    'Pending': 'Pending',
    'Blocked': 'Blocked',
    'Maintenance': 'Maintenance',
  };

  static String unitStatusLabel(String key) {
    final i18nKey = _unitStatusI18n[key];
    if (i18nKey != null && i18nKey.tr != i18nKey) {
      return i18nKey.tr;
    }
    return key == 'Available'
        ? 'متاح'
        : (key == 'Rented'
            ? 'مؤجر'
            : (key == 'Pending'
                ? 'قيد الحجز'
                : (key == 'Blocked' ? 'محظور' : 'تحت الصيانة')));
  }

  static String normalizeUnitStatus(String stored) =>
      _unitStatusLegacy[stored] ?? stored;
}
