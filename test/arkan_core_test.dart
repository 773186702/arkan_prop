import 'package:arkan_prop/core/utils/formatters.dart';
import 'package:arkan_prop/core/utils/pin_hasher.dart';
import 'package:arkan_prop/features/finance/domain/finance_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinHasher Tests', () {
    test('PinHasher hashes with salt and verifies correctly', () {
      final h1 = PinHasher.hashPin('1234');
      final h2 = PinHasher.hashPin('1234');
      expect(h1, isNot(equals(h2)));
      expect(PinHasher.verifyPin('1234', h1), isTrue);
      expect(PinHasher.verifyPin('9999', h1), isFalse);
    });
  });

  group('DueEntity Status Tests', () {
    test('DueEntity calculates status correctly based on remaining and due date', () {
      final paidDue = DueEntity(
        id: 'D1',
        contractId: 'C1',
        tenantId: 'T1',
        unitId: 'U1',
        dueType: 'إيجار',
        periodLabel: 'يناير',
        dueDate: '2026-01-01',
        amount: 1000,
        paid: 1000,
        currency: 'YER',
      );
      expect(paidDue.status, equals('مسدد'));
      expect(paidDue.remaining, equals(0));

      final partialDue = DueEntity(
        id: 'D2',
        contractId: 'C1',
        tenantId: 'T1',
        unitId: 'U1',
        dueType: 'إيجار',
        periodLabel: 'فبراير',
        dueDate: '2030-01-01',
        amount: 1000,
        paid: 400,
        currency: 'YER',
      );
      expect(partialDue.status, equals('مسدد جزئياً'));
      expect(partialDue.remaining, equals(600));

      final lateDue = DueEntity(
        id: 'D3',
        contractId: 'C1',
        tenantId: 'T1',
        unitId: 'U1',
        dueType: 'إيجار',
        periodLabel: 'فبراير',
        dueDate: '2020-01-01',
        amount: 1000,
        paid: 0,
        currency: 'YER',
      );
      expect(lateDue.status, equals('متأخر'));
      expect(lateDue.remaining, equals(1000));
    });
  });

  group('AppFormatters Tests', () {
    test('Formatters format money and date correctly', () {
      expect(AppFormatters.money(150000), equals('150,000'));
      expect(AppFormatters.date(DateTime(2026, 11, 19, 10, 30)), equals('2026-11-19 10:30'));
    });
  });
}
