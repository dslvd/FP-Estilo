import 'package:flutter_test/flutter_test.dart';
import 'package:plantpal/main.dart';

void main() {
  testWidgets('shows plant list on launch', (tester) async {
    await tester.pumpWidget(const PlantPalApp());
    expect(find.text('PlantPal'), findsWidgets);
    expect(find.text('Monstera'), findsOneWidget);
  });
}
