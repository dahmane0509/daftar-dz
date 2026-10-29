import 'package:flutter_test/flutter_test.dart';
import 'package:daftar_dz/main.dart';

void main() {
  testWidgets('DaftarDzApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DaftarDzApp());
    expect(find.byType(DaftarDzApp), findsOneWidget);
  });
}
