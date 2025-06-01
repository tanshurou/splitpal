import 'package:flutter_test/flutter_test.dart';
import 'package:splitpal/utils/get_expense_Id.dart';

void main() {
  group('getNextExpenseIdFromDocs', () {
    test('returns E006 when max ID is E005', () async {
      final result = await getNextExpenseIdFromDocs(['E001', 'E002', 'E005']);
      expect(result, 'E006');
    });

    test('returns E001 when list is empty', () async {
      final result = await getNextExpenseIdFromDocs([]);
      expect(result, 'E001');
    });

    test('ignores IDs without E prefix', () async {
      final result = await getNextExpenseIdFromDocs(['A999', 'B100']);
      expect(result, 'E001');
    });

    test('works with mixed valid and invalid IDs', () async {
      final result = await getNextExpenseIdFromDocs(['E003', 'X005', 'E002']);
      expect(result, 'E004');
    });
  });
}
