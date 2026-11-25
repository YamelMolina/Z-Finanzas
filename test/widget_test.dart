import 'package:flutter_test/flutter_test.dart';
import 'package:z_finances/main.dart';

void main() {
  testWidgets('Z Finances inicia correctamente', (tester) async {
    await tester.pumpWidget(const ZFinancesApp());

    // Verificamos que el Login se cargue con los textos nuevos
    expect(find.text('Z FINANCES'), findsOneWidget);
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });
}